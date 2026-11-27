-- ============================================================================
-- CMake & Overseer 통합 설정 + 최신 compile_commands.json 자동 루트 링크/복사
-- ============================================================================
local uv = vim.uv or vim.loop
local is_win = vim.fn.has("win32") == 1

-- 탐색 시 건너뛸 외부 의존성/숨김 디렉터리
local ignored_dirs = {
    [".git"] = true,
    [".cache"] = true,
    [".vs"] = true,
    [".vscode"] = true,
    ["node_modules"] = true,
    ["third_party"] = true,
    ["external"] = true,
    ["vendor"] = true,
    ["deps"] = true,
    ["vcpkg_installed"] = true,
}

-- 루트 경로별로 마지막 동기화한 원본 파일 기록 (불필요한 반복 복사/알림 방지)
local last_synced = {}

local function is_newer(a_sec, a_nsec, b_sec, b_nsec)
    if a_sec ~= b_sec then
        return a_sec > b_sec
    end
    return (a_nsec or 0) > (b_nsec or 0)
end

-- 하위 빌드 폴더(depth 1~3, 예: build/, build/release_x86/, out/build/x64-Debug/ 등)에서
-- 모든 compile_commands.json 후보를 찾아 최신 수정 시각(mtime) 순으로 반환
local function find_compile_commands_candidates(root)
    local candidates = {}

    local function scan(dir, depth)
        if depth > 3 then
            return
        end
        local handle = uv.fs_scandir(dir)
        if not handle then
            return
        end

        while true do
            local name, typ = uv.fs_scandir_next(handle)
            if not name then
                break
            end
            if not typ then
                local st = uv.fs_stat(dir .. "/" .. name)
                typ = st and st.type or nil
            end

            if typ == "directory" and not ignored_dirs[name] then
                local subdir = dir .. "/" .. name
                local cc_path = subdir .. "/compile_commands.json"
                local st = uv.fs_stat(cc_path)
                if st and st.type == "file" and st.mtime then
                    table.insert(candidates, {
                        path = vim.fs.normalize(cc_path),
                        rel = subdir:sub(#root + 2) .. "/compile_commands.json",
                        sec = st.mtime.sec or 0,
                        nsec = st.mtime.nsec or 0,
                        size = st.size or 0,
                    })
                end
                scan(subdir, depth + 1)
            end
        end
    end

    scan(root, 1)

    table.sort(candidates, function(a, b)
        return is_newer(a.sec, a.nsec, b.sec, b.nsec)
    end)

    return candidates
end

-- 실행 중인 clangd 클라이언트에 compile_commands.json 변경 알림 전송 (재시작 없이 즉시 반영)
local function notify_clangd_changed(dest_path)
    for _, client in ipairs(vim.lsp.get_clients({ name = "clangd" })) do
        pcall(function()
            client:notify("workspace/didChangeWatchedFiles", {
                changes = {
                    { uri = vim.uri_from_fname(dest_path), type = 2 },
                },
            })
        end)
    end
end

-- 지정한 후보(candidate)를 프로젝트 루트의 compile_commands.json 으로 심볼릭 링크(Linux) 또는 복사(Windows)
local function link_or_copy_to_root(root, candidate, opts)
    opts = opts or {}
    local dest = vim.fs.normalize(root .. "/compile_commands.json")
    local prev = last_synced[root]

    local lstat = uv.fs_lstat(dest)

    -- 1) 이미 동일한 최신 원본을 가리키거나 동기화된 상태라면 디스크 쓰기 생략
    if not opts.force then
        if lstat and lstat.type == "link" then
            local link_target = uv.fs_readlink(dest)
            if link_target then
                local resolved = link_target
                -- 상대 경로 심볼릭 링크 보정
                if not vim.startswith(link_target, "/") and not link_target:match("^%a:[/\\]") then
                    resolved = root .. "/" .. link_target
                end
                resolved = vim.fs.normalize(resolved)
                if resolved == candidate.path then
                    if prev and prev.path == candidate.path and prev.sec == candidate.sec and prev.nsec == candidate.nsec then
                        return false
                    end
                    last_synced[root] = { path = candidate.path, sec = candidate.sec, nsec = candidate.nsec }
                    notify_clangd_changed(dest)
                    return false
                end
            end
        elseif lstat and lstat.type == "file" then
            -- 루트에 직접 cmake -B . 로 생성된 원본이 하위 폴더보다 더 최신이면 덮어쓰지 않음 (자동 모드 한정)
            if not is_win and not prev and lstat.mtime and is_newer(lstat.mtime.sec, lstat.mtime.nsec, candidate.sec, candidate.nsec) then
                return false
            end
            if prev and prev.path == candidate.path and prev.sec == candidate.sec and prev.nsec == candidate.nsec then
                return false
            end
            local dst_stat = uv.fs_stat(dest)
            if
                not prev
                and dst_stat
                and dst_stat.size == candidate.size
                and dst_stat.mtime
                and not is_newer(candidate.sec, candidate.nsec, dst_stat.mtime.sec, dst_stat.mtime.nsec)
            then
                last_synced[root] = { path = candidate.path, sec = candidate.sec, nsec = candidate.nsec }
                return false
            end
        end
    end

    -- 2) 기존 링크/파일 제거 후 심볼릭 링크 시도 -> 권한 제한(Windows / WSL NTFS 등) 시 파일 복사로 자동 폴백
    if lstat then
        pcall(uv.fs_unlink, dest)
    end

    local mode_label = "symlink"
    local ok = false
    if not is_win then
        ok = pcall(function()
            assert(uv.fs_symlink(candidate.path, dest))
        end)
    end
    if not ok then
        mode_label = "copy"
        local copy_ok, copy_err = uv.fs_copyfile(candidate.path, dest)
        if not copy_ok then
            if not opts.silent then
                vim.notify(
                    "compile_commands.json 동기화 실패: " .. tostring(copy_err),
                    vim.log.levels.ERROR,
                    { title = "CMake" }
                )
            end
            return false
        end
    end

    last_synced[root] = { path = candidate.path, sec = candidate.sec, nsec = candidate.nsec }
    notify_clangd_changed(dest)

    if not opts.silent then
        vim.notify(
            string.format("compile_commands.json 갱신 (%s) ← %s", mode_label, candidate.rel),
            vim.log.levels.INFO,
            { title = "CMake & clangd" }
        )
    end
    return true
end

-- 가장 최근(mtime 1위) compile_commands.json 자동 동기화
local function sync_latest_compile_commands(opts)
    opts = opts or {}
    local root = vim.fs.normalize(vim.fn.getcwd(0))
    if vim.fn.filereadable(root .. "/CMakeLists.txt") == 0 and not opts.manual then
        return
    end

    local candidates = find_compile_commands_candidates(root)
    if #candidates == 0 then
        if opts.manual then
            vim.notify(
                "하위 빌드 폴더에서 compile_commands.json 을 찾지 못했습니다.",
                vim.log.levels.WARN,
                { title = "CMake" }
            )
        end
        return
    end

    link_or_copy_to_root(root, candidates[1], {
        force = opts.manual,
        silent = opts.silent,
    })
end

-- 여러 빌드 폴더(Debug / Release / release_x86 등) 중 원하는 compile_commands.json 직접 선택
local function select_compile_commands()
    local root = vim.fs.normalize(vim.fn.getcwd(0))
    local candidates = find_compile_commands_candidates(root)
    if #candidates == 0 then
        vim.notify(
            "하위 빌드 폴더에서 compile_commands.json 을 찾지 못했습니다.",
            vim.log.levels.WARN,
            { title = "CMake" }
        )
        return
    end

    vim.ui.select(candidates, {
        prompt = "Select compile_commands.json (최신 수정순)",
        format_item = function(item)
            local time_str = os.date("%Y-%m-%d %H:%M:%S", item.sec)
            return string.format("%s  (%s)", item.rel, time_str)
        end,
    }, function(choice)
        if choice then
            link_or_copy_to_root(root, choice, { force = true, silent = false })
        end
    end)
end

return {
    -- 1. 빌드 및 태스크 러너 (CMake 빌드 출력 창 관리)
    {
        "stevearc/overseer.nvim",
        cmd = {
            "OverseerRun",
            "OverseerToggle",
            "OverseerOpen",
            "OverseerClose",
        },
        keys = {
            { "<leader>ot", "<cmd>OverseerToggle<cr>", desc = "Overseer 태스크 창 토글" },
            { "<leader>or", "<cmd>OverseerRun<cr>", desc = "Overseer 태스크 실행" },
        },
        opts = {
            task_list = {
                direction = "bottom",
                min_height = 12,
                max_height = 20,
                default_detail = 1,
                bindings = {
                    ["q"] = "Close",
                    ["<Esc>"] = "Close",
                },
            },
        },
    },

    -- 2. CMake 통합 도구 (Ninja + 병렬 빌드 + 최신 compile_commands 연동 + Overseer/Terminal/DAP)
    {
        "Civitasv/cmake-tools.nvim",
        ft = { "c", "cpp", "cmake", "objc", "objcpp" },
        cmd = {
            "CMakeGenerate",
            "CMakeBuild",
            "CMakeRun",
            "CMakeDebug",
            "CMakeRunCurrentFile",
            "CMakeDebugCurrentFile",
            "CMakeRunTest",
            "CMakeLaunchArgs",
            "CMakeTargetSettings",
            "CMakeSelectBuildType",
            "CMakeSelectBuildTarget",
            "CMakeSelectLaunchTarget",
            "CMakeSelectConfigurePreset",
            "CMakeSelectBuildPreset",
            "CMakeClean",
            "CMakeStopExecutor",
            "CMakeStopRunner",
            "CMakeSyncCompileCommands",
            "CMakeSelectCompileCommands",
        },
        dependencies = {
            "nvim-lua/plenary.nvim",
            "stevearc/overseer.nvim",
        },
        keys = {
            -- 기본 구성 / 빌드 / 실행 / 디버그
            { "<leader>cg", "<cmd>CMakeGenerate<cr>", desc = "CMake Generate (Ninja 구성 및 compile_commands 생성)" },
            { "<leader>cb", "<cmd>CMakeBuild<cr>", desc = "CMake Build (프로젝트 병렬 빌드)" },
            { "<leader>cr", "<cmd>CMakeRun<cr>", desc = "CMake Run (선택 타겟 실행)" },
            { "<leader>cd", "<cmd>CMakeDebug<cr>", desc = "CMake Debug (선택 타겟 DAP 디버깅)" },
            { "<leader>cc", "<cmd>CMakeClean<cr>", desc = "CMake Clean" },

            -- 빌드 타입 및 타겟 선택
            { "<leader>cy", "<cmd>CMakeSelectBuildType<cr>", desc = "CMake 빌드 타입 선택 (Debug/Release)" },
            { "<leader>ct", "<cmd>CMakeSelectBuildTarget<cr>", desc = "CMake 빌드 타겟 선택" },
            { "<leader>cl", "<cmd>CMakeSelectLaunchTarget<cr>", desc = "CMake 실행/디버그 타겟 선택" },

            -- 확장 기능: 타겟 인자/환경변수, 단위 테스트(CTest), 현재 파일 즉시 실행/디버그, 강제 중지
            { "<leader>cL", "<cmd>CMakeTargetSettings<cr>", desc = "CMake 실행 타겟 인자(args) 및 환경변수 설정" },
            { "<leader>cT", "<cmd>CMakeRunTest<cr>", desc = "CMake CTest 단위 테스트 선택 실행" },
            { "<leader>cR", "<cmd>CMakeRunCurrentFile<cr>", desc = "CMake 현재 열린 파일 타겟 즉시 실행" },
            { "<leader>cD", "<cmd>CMakeDebugCurrentFile<cr>", desc = "CMake 현재 열린 파일 타겟 즉시 디버깅" },
            {
                "<leader>cx",
                function()
                    pcall(vim.cmd, "CMakeStopExecutor")
                    pcall(vim.cmd, "CMakeStopRunner")
                    vim.notify("진행 중인 CMake 빌드/실행 작업을 중지했습니다.", vim.log.levels.INFO, { title = "CMake" })
                end,
                desc = "CMake 진행 중인 빌드/실행 강제 중지",
            },

            -- 커스텀 빌드 경로 compile_commands.json 수동 선택 / 최신 강제 동기화
            { "<leader>cs", select_compile_commands, desc = "CMake compile_commands.json 목록에서 선택 연결" },
            {
                "<leader>cS",
                function()
                    sync_latest_compile_commands({ manual = true, silent = false })
                end,
                desc = "CMake 최신(mtime) compile_commands.json 루트 동기화",
            },
        },
        opts = {
            cmake_command = "cmake",
            ctest_command = "ctest",
            ctest_show_labels = true, -- CTest 실행 시 테스트 라벨 필터 표시
            cmake_regenerate_on_save = true, -- CMakeLists.txt 저장 시 자동 재구성
            cmake_generate_options = {
                "-G",
                "Ninja", -- Linux/Windows(MSVC) 모두 고속 Ninja 빌드 및 compile_commands 생성 보장
                "-DCMAKE_EXPORT_COMPILE_COMMANDS=1",
            },
            cmake_build_options = {
                "--parallel", -- 멀티코어 병렬 컴파일
            },
            cmake_build_directory = "build/${variant:buildType}",

            -- 최신 cmake-tools 문법: 탭별 워크스페이스(tcd) 루트에 자동 심볼릭 링크(Linux) / 복사(Windows)
            cmake_compile_commands_options = {
                action = is_win and "copy" or "soft_link",
                target = function()
                    return vim.fn.getcwd(0)
                end,
            },

            -- 1) 빌드(Executor)는 하단(bottom) Overseer 패널로 고정
            cmake_executor = {
                name = "overseer",
                opts = {
                    on_new_task = function()
                        require("overseer").open({ enter = false, direction = "bottom" })
                    end,
                },
            },

            -- 2) 실행(Runner)은 콘솔 표준 입력(std::cin / scanf)이 가능한 하단 터미널 사용
            cmake_runner = {
                name = "terminal",
                opts = {
                    split_direction = "horizontal",
                    split_size = 12,
                    focus = true,
                    start_insert = true,
                },
            },

            -- 3) dap.lua 의 codelldb 디버거와 자동 연동
            cmake_dap_configuration = {
                name = "cpp",
                type = "codelldb",
                request = "launch",
                stopOnEntry = false,
                runInTerminal = true,
                console = "integratedTerminal",
            },
        },
        config = function(_, opts)
            require("cmake-tools").setup(opts)

            -- 사용자 명령어 등록
            vim.api.nvim_create_user_command("CMakeSyncCompileCommands", function()
                sync_latest_compile_commands({ manual = true, silent = false })
            end, { desc = "가장 최근에 생성된 compile_commands.json 을 루트에 링크/복사" })

            vim.api.nvim_create_user_command("CMakeSelectCompileCommands", function()
                select_compile_commands()
            end, { desc = "하위 빌드 폴더의 compile_commands.json 중 하나를 골라 루트에 링크/복사" })

            -- 최초 로드 시(C/C++ 파일 진입 시) 조용히 최신 compile_commands.json 점검
            sync_latest_compile_commands({ silent = true })

            -- 외부 터미널(<leader>tt 등)에서 커스텀 cmake 실행 후 닫을 때, 창 포커스 복귀 시, 워크스페이스(tcd) 전환 시 자동 갱신
            local augroup = vim.api.nvim_create_augroup("UserCMakeCompileCommandsSync", { clear = true })
            vim.api.nvim_create_autocmd({ "TermClose", "FocusGained", "DirChanged" }, {
                group = augroup,
                callback = function()
                    vim.schedule(function()
                        sync_latest_compile_commands({ silent = false })
                    end)
                end,
            })
        end,
    },
}

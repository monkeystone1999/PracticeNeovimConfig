return {
    -- 1. 빌드 및 태스크 러너 (CMake 빌드/실행 출력 창 관리)
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
            },
        },
    },

    -- 2. CMake 통합 도구 (clangd용 compile_commands.json 자동 연동 + overseer/nvim-dap 연동)
    {
        "Civitasv/cmake-tools.nvim",
        ft = { "c", "cpp", "cmake", "objc", "objcpp" },
        cmd = {
            "CMakeGenerate",
            "CMakeBuild",
            "CMakeRun",
            "CMakeDebug",
            "CMakeSelectBuildType",
            "CMakeSelectBuildTarget",
            "CMakeSelectLaunchTarget",
            "CMakeClean",
        },
        dependencies = {
            "nvim-lua/plenary.nvim",
            "stevearc/overseer.nvim",
        },
        keys = {
            { "<leader>cg", "<cmd>CMakeGenerate<cr>", desc = "CMake Generate (설정 및 compile_commands 생성)" },
            { "<leader>cb", "<cmd>CMakeBuild<cr>", desc = "CMake Build (프로젝트 빌드)" },
            { "<leader>cr", "<cmd>CMakeRun<cr>", desc = "CMake Run (타겟 실행)" },
            { "<leader>cd", "<cmd>CMakeDebug<cr>", desc = "CMake Debug (nvim-dap 디버깅 실행)" },
            { "<leader>cy", "<cmd>CMakeSelectBuildType<cr>", desc = "CMake 빌드 타입 선택 (Debug/Release)" },
            { "<leader>ct", "<cmd>CMakeSelectBuildTarget<cr>", desc = "CMake 빌드 타겟 선택" },
            { "<leader>cl", "<cmd>CMakeSelectLaunchTarget<cr>", desc = "CMake 실행/디버그 타겟 선택" },
            { "<leader>cc", "<cmd>CMakeClean<cr>", desc = "CMake Clean" },
        },
        opts = {
            cmake_command = "cmake",
            cmake_regenerate_on_save = true, -- CMakeLists.txt 저장 시 자동 재구성
            cmake_generate_options = {
                "-DCMAKE_EXPORT_COMPILE_COMMANDS=1", -- clangd가 헤더/플래그를 인식하기 위한 필수 옵션
            },
            cmake_build_directory = "build/${variant:buildType}",
            -- 생성된 compile_commands.json을 프로젝트 루트에 자동 심볼릭 링크 (Windows는 LSP를 통해 직접 전달)
            cmake_soft_link_compile_commands = vim.fn.has("win32") == 0,
            cmake_compile_commands_from_lsp = vim.fn.has("win32") == 1,

            -- 빌드(Executor)와 실행(Runner) 모두 overseer.nvim 내장 러너로 연결
            cmake_executor = {
                name = "overseer",
                opts = {},
            },
            cmake_runner = {
                name = "overseer",
                opts = {},
            },

            -- 3단계(dap.lua)에서 설치할 codelldb 디버거와 자동 연동
            cmake_dap_configuration = {
                name = "cpp",
                type = "codelldb",
                request = "launch",
                stopOnEntry = false,
                runInTerminal = true,
                console = "integratedTerminal",
            },
        },
    },
}

return {
    "nvim-treesitter/nvim-treesitter-context",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = { "BufReadPost", "BufNewFile" },
    opts = {
        enable = true,
        multiwindow = false,      -- 현재 활성 창에서만 표시
        -- C/C++ 은 #ifdef > namespace > template > class > method > loop/switch 처럼 중첩이 깊음
        max_lines = 6,            -- 상단에 고정할 최대 컨텍스트 줄 수 (0 = 무제한)
        min_window_height = 18,   -- 분할 창이 너무 작을 때는 본문 가독성을 위해 숨김
        line_numbers = true,
        -- 2줄짜리 반환형 개행/시그니처는 그대로 보여주고, 3줄 이상 긴 인자/생성자 초기화 리스트는 1줄로 축약
        multiline_threshold = 2,
        trim_scope = "outer",     -- max_lines 초과 시 가장 바깥쪽(namespace 등)부터 생략
        mode = "cursor",          -- 기본은 커서 기준 (<leader>tC 로 topline 모드와 실시간 전환 가능)
        separator = nil,          -- 구분선 문자 대신 VSCode 스타일 하단 밑줄 하이라이트 사용
        -- 대시보드 플로팅 창(zindex 10)보다 아래에 그려지도록 낮춤 (기본값 20이면 대시보드 위로 겹쳐 보임)
        zindex = 5,
        on_attach = function(buf)
            -- 대용량/자동 생성 C/C++ 파일(Protobuf, Qt MOC/UI 등)에서는 렌더링 부하 방지를 위해 비활성화
            if vim.api.nvim_buf_line_count(buf) > 25000 then
                return false
            end
            local name = vim.api.nvim_buf_get_name(buf)
            if
                name:match("%.pb%.h$")
                or name:match("%.pb%.cc$")
                or name:match("moc_.*%.cpp$")
                or name:match("qrc_.*%.cpp$")
                or name:match("ui_.*%.h$")
            then
                return false
            end
            return true
        end,
    },
    config = function(_, opts)
        local tsc = require("treesitter-context")

        -- =====================================================================
        -- C / C++ 개발자용 추가 Tree-sitter Context 쿼리 확장
        -- (기본 플러그인 쿼리에 누락된 전처리기 분기, struct/enum 내부 #ifdef,
        --  C++ template / requires / extern "C" / lambda / try-catch / concept 보강)
        -- =====================================================================
        local c_extra_rules = {
            -- #elif / C23 #elifdef 조건부 컴파일 분기 (기본 쿼리는 #if, #ifdef, #else 만 포함)
            {
                node = "preproc_elif",
                query = "(preproc_elif (_) (_) @context.end) @context",
            },
            {
                node = "preproc_elifdef",
                query = "(preproc_elifdef name: (identifier) (_) @context.end) @context",
            },
            -- struct / union / class 멤버 선언부 내부의 플랫폼별 #if / #ifdef / #elif / #else 블록
            {
                node = "preproc_if_in_field_declaration_list",
                query = "(preproc_if_in_field_declaration_list (_) (_) @context.end) @context",
            },
            {
                node = "preproc_ifdef_in_field_declaration_list",
                query = "(preproc_ifdef_in_field_declaration_list name: (identifier) (_) @context.end) @context",
            },
            {
                node = "preproc_elif_in_field_declaration_list",
                query = "(preproc_elif_in_field_declaration_list (_) (_) @context.end) @context",
            },
            {
                node = "preproc_else_in_field_declaration_list",
                query = "(preproc_else_in_field_declaration_list (_) (_) @context.end) @context",
            },
            -- 대형 enum 내부의 #if / #ifdef / #elif / #else 블록
            {
                node = "preproc_if_in_enumerator_list",
                query = "(preproc_if_in_enumerator_list (_) (_) @context.end) @context",
            },
            {
                node = "preproc_ifdef_in_enumerator_list",
                query = "(preproc_ifdef_in_enumerator_list name: (identifier) (_) @context.end) @context",
            },
            {
                node = "preproc_elif_in_enumerator_list",
                query = "(preproc_elif_in_enumerator_list (_) (_) @context.end) @context",
            },
            {
                node = "preproc_else_in_enumerator_list",
                query = "(preproc_else_in_enumerator_list (_) (_) @context.end) @context",
            },
            -- 대형 정적 테이블/vtable 지정 초기화 항목 (예: [OP_ADD] = { ... }, .ops = { ... })
            {
                node = "initializer_pair",
                query = "(initializer_pair value: (initializer_list (_) @context.end)) @context",
            },
        }

        local cpp_extra_rules = vim.list_extend(vim.deepcopy(c_extra_rules), {
            -- template <typename T, ...> (C++20 requires 절 포함) 헤더를 클래스/함수 시그니처 위에 고정
            {
                node = "template_declaration",
                query = [[
                  (template_declaration
                    parameters: (template_parameter_list)
                    (requires_clause)?
                    .
                    (_) @context.end) @context
                ]],
            },
            -- extern "C" { ... } 블록 (단일 선언문 extern "C" void f(); 는 제외하고 중괄호 블록만 표시)
            {
                node = "linkage_specification",
                query = "(linkage_specification body: (declaration_list (_) @context.end)) @context",
            },
            -- 람다 표현식 ([this, &ctx](const auto& item) { ... })
            {
                node = "lambda_expression",
                query = "(lambda_expression body: (_ (_) @context.end)) @context",
            },
            -- 예외 처리 블록 (try / catch)
            {
                node = "try_statement",
                query = "(try_statement body: (_ (_) @context.end)) @context",
            },
            {
                node = "catch_clause",
                query = "(catch_clause body: (_ (_) @context.end)) @context",
            },
            -- C++20 concept 정의 및 requires 표현식
            {
                node = "concept_definition",
                query = "(concept_definition) @context",
            },
            {
                node = "requires_expression",
                query = "(requires_expression requirements: (_ (_) @context.end)) @context",
            },
            -- 기본 쿼리에 누락되었을 경우를 대비한 C++ 핵심 스코프 안전망
            {
                node = "namespace_definition",
                query = "(namespace_definition body: (_ (_) @context.end)) @context",
            },
            {
                node = "class_specifier",
                query = "(class_specifier body: (_ (_) @context.end)) @context",
            },
            {
                node = "for_range_loop",
                query = "(for_range_loop body: (_ (_) @context.end)) @context",
            },
        })

        local rules_by_lang = {
            c = c_extra_rules,
            cpp = cpp_extra_rules,
        }

        local configured_langs = {}

        local function extend_context_query(lang)
            local extra_rules = rules_by_lang[lang]
            if not extra_rules or configured_langs[lang] then
                return
            end
            -- 파서가 아직 설치/컴파일 전이면 다음 기회에 재시도하도록 보류
            if not pcall(vim.treesitter.language.add, lang) then
                return
            end

            local ok_files, files = pcall(vim.treesitter.query.get_files, lang, "context")
            if not ok_files then
                return
            end

            local chunks = {}
            for _, filepath in ipairs(files) do
                local f = io.open(filepath, "r")
                if f then
                    local content = f:read("*a")
                    f:close()
                    if content and content ~= "" then
                        -- get_files() 가 이미 inherits/extends 순서대로 파일 목록을 풀어주므로 중복 modeline 제거
                        content = ("\n" .. content)
                            :gsub("\n%s*;+%s*inherits%s*:?[^\n]*", "")
                            :gsub("\n%s*;+%s*extends[^\n]*", "")
                            :sub(2)
                        table.insert(chunks, content)
                    end
                end
            end

            local base_query = table.concat(chunks, "\n")
            local additions = {}

            for _, rule in ipairs(extra_rules) do
                local escaped = rule.node:gsub("%-", "%%-")
                local already_defined = base_query:find("%(" .. escaped .. "[%s%)]") ~= nil
                -- 설치된 C/C++ 파서 버전에서 문법적으로 유효한 규칙만 선별 추가 (에러 원천 차단)
                if not already_defined and pcall(vim.treesitter.query.parse, lang, rule.query) then
                    table.insert(additions, rule.query)
                end
            end

            configured_langs[lang] = true

            if #additions == 0 then
                return
            end

            local full_query = base_query .. "\n\n; C/C++ extra context rules\n" .. table.concat(additions, "\n")
            if pcall(vim.treesitter.query.parse, lang, full_query) then
                vim.treesitter.query.set(lang, "context", full_query)
            end
        end

        -- 이미 파서가 설치되어 있다면 setup 전에 즉시 확장 적용 + 이후 파서 설치 시 FileType 에서 재시도
        extend_context_query("c")
        extend_context_query("cpp")

        local augroup = vim.api.nvim_create_augroup("UserTreesitterContext", { clear = true })

        vim.api.nvim_create_autocmd("FileType", {
            group = augroup,
            pattern = { "c", "cpp", "objc", "objcpp", "cuda" },
            callback = function(ev)
                local lang = vim.treesitter.language.get_lang(vim.bo[ev.buf].filetype) or vim.bo[ev.buf].filetype
                extend_context_query(lang)
            end,
        })

        tsc.setup(opts)

        -- VSCode Dark+ 코드 하이라이트(highlights.lua)와 어울리는 상단 고정 컨텍스트 배경 및 구분선
        local function set_hl()
            vim.api.nvim_set_hl(0, "TreesitterContext", { bg = "#1E1E1E" })
            vim.api.nvim_set_hl(0, "TreesitterContextLineNumber", { fg = "#858585", bg = "#1E1E1E" })
            vim.api.nvim_set_hl(0, "TreesitterContextBottom", { underline = true, sp = "#3C3C3C" })
            vim.api.nvim_set_hl(0, "TreesitterContextLineNumberBottom", {
                fg = "#858585",
                bg = "#1E1E1E",
                underline = true,
                sp = "#3C3C3C",
            })
        end
        set_hl()
        vim.api.nvim_create_autocmd("ColorScheme", {
            group = augroup,
            callback = set_hl,
        })

        -- [x : 상위 스코프(예: #ifdef / 루프 -> 함수 -> class -> namespace)로 점프 (2[x 등 count 지원, <C-o> 로 복귀)
        vim.keymap.set("n", "[x", function()
            vim.cmd("normal! m'")
            tsc.go_to_context(vim.v.count1)
        end, { silent = true, desc = "상위 컨텍스트 시작으로 점프 (Treesitter Context)" })

        -- <leader>tc : 상단 고정 컨텍스트 표시 토글
        vim.keymap.set("n", "<leader>tc", "<cmd>TSContext toggle<cr>",
            { silent = true, desc = "Toggle Treesitter Context" })

        -- <leader>tC : 기준 모드 전환 ("cursor": 편집 위치 스코프 <-> "topline": 대형 .cpp/.h 스크롤 읽기용)
        local current_mode = opts.mode or "cursor"
        vim.keymap.set("n", "<leader>tC", function()
            current_mode = (current_mode == "cursor") and "topline" or "cursor"
            opts.mode = current_mode
            tsc.setup(opts)
            vim.notify("Treesitter Context mode: " .. current_mode, vim.log.levels.INFO, { title = "TSContext" })
        end, { silent = true, desc = "Switch Context Mode cursor/topline (Treesitter Context)" })
    end,
}

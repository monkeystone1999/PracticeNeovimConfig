return {
    {
        "mfussenegger/nvim-dap",
        dependencies = {
            -- 1. DAP UI 및 비동기 I/O 의존성
            "rcarriga/nvim-dap-ui",
            "nvim-neotest/nvim-nio",

            -- 2. 디버깅 중 코드 줄 옆에 변수 값 실시간 표시
            {
                "theHamsta/nvim-dap-virtual-text",
                opts = {
                    commented = true, -- 주석 형태로 깔끔하게 변수 값 표시
                },
            },

            -- 3. Mason을 통한 디버거(codelldb) 자동 설치 및 어댑터 자동 연결
            {
                "jay-babu/mason-nvim-dap.nvim",
                dependencies = { "williamboman/mason.nvim" },
                opts = {
                    ensure_installed = {
                        "codelldb", -- C / C++ / Rust 전용 LLDB 디버거 어댑터
                    },
                    automatic_installation = true,
                    handlers = {}, -- 설치된 디버거를 nvim-dap에 자동 등록
                },
            },
        },
        keys = {
            -- 중단점(Breakpoint) 관리 (<leader>db는 대시보드 토글 단축키이므로 <leader>b 사용)
            {
                "<leader>b",
                function()
                    require("dap").toggle_breakpoint()
                end,
                desc = "DAP: 중단점(Breakpoint) 토글",
            },
            {
                "<leader>B",
                function()
                    require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
                end,
                desc = "DAP: 조건부 중단점 설정",
            },

            -- 실행 제어 (F5~F12 및 <leader>d* 단축키 모두 지원)
            {
                "<F5>",
                function()
                    require("dap").continue()
                end,
                desc = "DAP: 디버깅 시작 / 계속 (Continue)",
            },
            {
                "<leader>dc",
                function()
                    require("dap").continue()
                end,
                desc = "DAP: 디버깅 시작 / 계속 (Continue)",
            },
            {
                "<F10>",
                function()
                    require("dap").step_over()
                end,
                desc = "DAP: 다음 줄로 이동 (Step Over)",
            },
            {
                "<leader>do",
                function()
                    require("dap").step_over()
                end,
                desc = "DAP: 다음 줄로 이동 (Step Over)",
            },
            {
                "<F11>",
                function()
                    require("dap").step_into()
                end,
                desc = "DAP: 함수 내부로 진입 (Step Into)",
            },
            {
                "<leader>di",
                function()
                    require("dap").step_into()
                end,
                desc = "DAP: 함수 내부로 진입 (Step Into)",
            },
            {
                "<F12>",
                function()
                    require("dap").step_out()
                end,
                desc = "DAP: 함수 밖으로 나오기 (Step Out)",
            },
            {
                "<leader>dO",
                function()
                    require("dap").step_out()
                end,
                desc = "DAP: 함수 밖으로 나오기 (Step Out)",
            },

            -- UI 제어 및 표현식 평가 / 세션 종료
            {
                "<leader>du",
                function()
                    require("dapui").toggle()
                end,
                desc = "DAP: 디버거 UI 창 토글",
            },
            {
                "<leader>de",
                function()
                    require("dapui").eval()
                end,
                mode = { "n", "v" },
                desc = "DAP: 커서/선택 영역 변수 값 평가 (Eval)",
            },
            {
                "<leader>dt",
                function()
                    require("dap").terminate()
                end,
                desc = "DAP: 디버깅 종료 (Terminate)",
            },
        },
        config = function()
            local dap = require("dap")
            local dapui = require("dapui")

            -- 1. DAP UI 기본 레이아웃 초기화
            dapui.setup()

            -- 2. 좌측 SignColumn 중단점 및 현재 실행 줄 아이콘 설정
            vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError", linehl = "", numhl = "" })
            vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn", linehl = "", numhl = "" })
            vim.fn.sign_define("DapBreakpointRejected", { text = "○", texthl = "DiagnosticInfo", linehl = "", numhl = "" })
            vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticOk", linehl = "Visual", numhl = "" })

            -- 3. 디버깅 시작/종료 시 DAP UI 자동 열기 및 닫기 연동
            dap.listeners.before.attach.dapui_config = function()
                dapui.open()
            end
            dap.listeners.before.launch.dapui_config = function()
                dapui.open()
            end
            dap.listeners.before.event_terminated.dapui_config = function()
                dapui.close()
            end
            dap.listeners.before.event_exited.dapui_config = function()
                dapui.close()
            end
        end,
    },
}

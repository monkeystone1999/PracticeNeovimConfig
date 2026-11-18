return {
  -- 1. 구문 기반 이동 및 매개변수 스왑 전담 (Neovim 0.12 / main 브랜치 기준)
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      { "nvim-treesitter/nvim-treesitter", branch = "main" },
    },
    config = function()
      local ts_to = require("nvim-treesitter-textobjects")
      local move = require("nvim-treesitter-textobjects.move")
      local swap = require("nvim-treesitter-textobjects.swap")

      -- select 모듈은 mini.ai에 위임하므로 활성화하지 않음
      ts_to.setup({
        move = {
          set_jumps = true, -- Ctrl-o / Ctrl-i 점프 리스트에 기록
        },
      })

      local map = vim.keymap.set
      local modes = { "n", "x", "o" }

      -- 함수 정의 이동 (C/C++ 함수 시작 및 끝)
      map(modes, "]f", function()
        move.goto_next_start("@function.outer", "textobjects")
      end, { desc = "다음 함수 시작" })
      map(modes, "[f", function()
        move.goto_previous_start("@function.outer", "textobjects")
      end, { desc = "이전 함수 시작" })
      map(modes, "]F", function()
        move.goto_next_end("@function.outer", "textobjects")
      end, { desc = "다음 함수 끝" })
      map(modes, "[F", function()
        move.goto_previous_end("@function.outer", "textobjects")
      end, { desc = "이전 함수 끝" })

      -- 클래스 / 구조체(struct) 이동
      map(modes, "]c", function()
        move.goto_next_start("@class.outer", "textobjects")
      end, { desc = "다음 클래스/구조체 시작" })
      map(modes, "[c", function()
        move.goto_previous_start("@class.outer", "textobjects")
      end, { desc = "이전 클래스/구조체 시작" })

      -- 함수 매개변수(인자) 이동 및 순서 바꾸기
      map(modes, "]a", function()
        move.goto_next_start("@parameter.inner", "textobjects")
      end, { desc = "다음 매개변수" })
      map(modes, "[a", function()
        move.goto_previous_start("@parameter.inner", "textobjects")
      end, { desc = "이전 매개변수" })
      map("n", "<leader>a", function()
        swap.swap_next("@parameter.inner")
      end, { desc = "다음 매개변수와 위치 교환" })
      map("n", "<leader>A", function()
        swap.swap_previous("@parameter.inner")
      end, { desc = "이전 매개변수와 위치 교환" })
    end,
  },

  -- 2. 괄호·함수·클래스·인자 텍스트 객체 선택 및 편집 전담
  {
    "echasnovski/mini.ai",
    version = false,
    event = "VeryLazy",
    dependencies = {
      { "nvim-treesitter/nvim-treesitter-textobjects", branch = "main" },
    },
        opts = function()
    local ai = require("mini.ai")

    return {
        n_lines = 500,
        search_method = "cover_or_next",

        mappings = {
            around_next = "",
            inside_next = "",
        },

        custom_textobjects = {
            o = ai.gen_spec.treesitter({
                a = { "@block.outer", "@conditional.outer", "@loop.outer" },
                i = { "@block.inner", "@conditional.inner", "@loop.inner" },
            }),

            f = ai.gen_spec.treesitter({
                a = "@function.outer",
                i = "@function.inner",
            }),

            c = ai.gen_spec.treesitter({
                a = "@class.outer",
                i = "@class.inner",
            }),

            a = ai.gen_spec.treesitter({
                a = "@parameter.outer",
                i = "@parameter.inner",
            }),

            ["<"] = ai.gen_spec.pair("<", ">", {
                type = "balanced",
            }),
        },
    }
end,

  },
}

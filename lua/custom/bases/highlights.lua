local M = {}

-- VSCode Dark+ 공식 C/C++ 색상 팔레트 (UI 배경/테두리는 건드리지 않고 코드 토큰만 정의)
local p = {
    comment      = "#6A9955", -- 주석 (초록)
    keyword_blue = "#569CD6", -- 기본 타입(int, void), storage(static, const), nullptr, true/false, this, 매크로 (파랑)
    control_purp = "#C586C0", -- 제어문(if, for, return, switch) 및 전처리기(#include, #define, #pragma) (보라)
    type_teal    = "#4EC9B0", -- 클래스, 구조체, 열거형, 네임스페이스(std), 템플릿 타입 (청록)
    func_yellow  = "#DCDCAA", -- 함수, 메서드 호출 및 선언 (노랑)
    var_lblue    = "#9CDCFE", -- 일반 변수, 파라미터, 구조체/클래스 멤버 변수 (하늘)
    const_cyan   = "#4FC1FF", -- 상수(const), 열거형 값(EnumMember) (밝은 시안)
    str_orange   = "#CE9178", -- 문자열 리터럴 (주황갈색)
    escape_gold  = "#D7BA7D", -- 이스케이프 문자(\n, \t) 및 포맷 지정자(%d, %s) (금색)
    num_green    = "#B5CEA8", -- 숫자 리터럴 (연두)
    operator_fg  = "#D4D4D4", -- 연산자 및 괄호/구두점 (밝은 회백색)
}

local code_highlights = {
    -- =========================================================================
    -- 1. 기본 Vim Syntax 그룹
    -- =========================================================================
    Comment        = { fg = p.comment, italic = true },
    Constant       = { fg = p.const_cyan },
    String         = { fg = p.str_orange },
    Character      = { fg = p.str_orange },
    Number         = { fg = p.num_green },
    Boolean        = { fg = p.keyword_blue },
    Float          = { fg = p.num_green },

    Identifier     = { fg = p.var_lblue },
    Function       = { fg = p.func_yellow },

    Statement      = { fg = p.control_purp },
    Conditional    = { fg = p.control_purp },
    Repeat         = { fg = p.control_purp },
    Label          = { fg = p.control_purp },
    Operator       = { fg = p.operator_fg },
    Keyword        = { fg = p.keyword_blue },
    Exception      = { fg = p.control_purp },

    PreProc        = { fg = p.control_purp },
    Include        = { fg = p.control_purp },
    Define         = { fg = p.control_purp },
    Macro          = { fg = p.keyword_blue },
    PreCondit      = { fg = p.control_purp },

    Type           = { fg = p.type_teal },
    StorageClass   = { fg = p.keyword_blue },
    Structure      = { fg = p.keyword_blue },
    Typedef        = { fg = p.keyword_blue },

    Special        = { fg = p.escape_gold },
    SpecialChar    = { fg = p.escape_gold },
    Delimiter      = { fg = p.operator_fg },

    -- =========================================================================
    -- 2. Treesitter 캡처 그룹 (Neovim 0.10+ 표준 @* 캡처)
    -- =========================================================================
    ["@comment"]               = { fg = p.comment, italic = true },
    ["@comment.documentation"] = { fg = p.comment, italic = true },

    -- 변수 및 멤버
    ["@variable"]              = { fg = p.var_lblue },
    ["@variable.builtin"]      = { fg = p.keyword_blue }, -- this, self
    ["@variable.parameter"]    = { fg = p.var_lblue },
    ["@variable.member"]       = { fg = p.var_lblue },    -- struct/class 필드
    ["@property"]              = { fg = p.var_lblue },
    ["@constant"]              = { fg = p.const_cyan },
    ["@constant.builtin"]      = { fg = p.keyword_blue }, -- NULL, nullptr
    ["@constant.macro"]        = { fg = p.keyword_blue },

    -- 문자열 및 숫자
    ["@string"]                = { fg = p.str_orange },
    ["@string.escape"]         = { fg = p.escape_gold },
    ["@string.special"]        = { fg = p.escape_gold },
    ["@character"]             = { fg = p.str_orange },
    ["@number"]                = { fg = p.num_green },
    ["@number.float"]          = { fg = p.num_green },
    ["@boolean"]               = { fg = p.keyword_blue },

    -- 함수 및 메서드
    ["@function"]              = { fg = p.func_yellow },
    ["@function.builtin"]      = { fg = p.func_yellow },
    ["@function.call"]         = { fg = p.func_yellow },
    ["@function.method"]       = { fg = p.func_yellow },
    ["@function.method.call"]  = { fg = p.func_yellow },
    ["@function.macro"]        = { fg = p.keyword_blue },
    ["@constructor"]           = { fg = p.type_teal },

    -- 타입 및 네임스페이스 (C/C++ 핵심 구분: int/void는 파랑, class/struct/std는 청록)
    ["@type"]                  = { fg = p.type_teal },
    ["@type.builtin"]          = { fg = p.keyword_blue }, -- int, char, void, double, bool, size_t
    ["@type.definition"]       = { fg = p.type_teal },
    ["@type.qualifier"]        = { fg = p.keyword_blue }, -- const, volatile, constexpr, mutable
    ["@storageclass"]          = { fg = p.keyword_blue }, -- static, extern, register
    ["@module"]                = { fg = p.type_teal },    -- C++ namespace (std::)
    ["@namespace"]             = { fg = p.type_teal },

    -- 키워드 및 전처리기 (VSCode Dark+ 특유의 파랑/보라 분리)
    ["@keyword"]               = { fg = p.keyword_blue }, -- class, struct, enum, template, typename, using, namespace
    ["@keyword.type"]          = { fg = p.keyword_blue },
    ["@keyword.modifier"]      = { fg = p.keyword_blue }, -- const, static, virtual, override, inline
    ["@keyword.operator"]      = { fg = p.keyword_blue }, -- new, delete, sizeof, alignof
    ["@keyword.function"]      = { fg = p.keyword_blue },
    ["@keyword.conditional"]   = { fg = p.control_purp }, -- if, else, switch, case
    ["@keyword.repeat"]        = { fg = p.control_purp }, -- for, while, do
    ["@keyword.return"]        = { fg = p.control_purp }, -- return, co_return, co_yield
    ["@keyword.exception"]     = { fg = p.control_purp }, -- try, catch, throw
    ["@keyword.import"]        = { fg = p.control_purp }, -- #include
    ["@keyword.directive"]     = { fg = p.control_purp }, -- #define, #ifdef, #endif, #pragma
    ["@keyword.directive.define"] = { fg = p.control_purp },

    -- 연산자 및 구두점
    ["@operator"]              = { fg = p.operator_fg },
    ["@punctuation.delimiter"] = { fg = p.operator_fg },
    ["@punctuation.bracket"]   = { fg = p.operator_fg },
    ["@punctuation.special"]   = { fg = p.operator_fg },

    -- =========================================================================
    -- 3. LSP Semantic Tokens (clangd / lua_ls 정밀 타입 하이라이팅)
    -- =========================================================================
    ["@lsp.type.class"]          = { fg = p.type_teal },
    ["@lsp.type.struct"]         = { fg = p.type_teal },
    ["@lsp.type.enum"]           = { fg = p.type_teal },
    ["@lsp.type.interface"]      = { fg = p.type_teal },
    ["@lsp.type.type"]           = { fg = p.type_teal },
    ["@lsp.type.typeParameter"]  = { fg = p.type_teal }, -- template <typename T> 의 T
    ["@lsp.type.namespace"]      = { fg = p.type_teal }, -- std::

    ["@lsp.type.enumMember"]     = { fg = p.const_cyan },
    ["@lsp.type.macro"]          = { fg = p.keyword_blue },

    ["@lsp.type.function"]       = { fg = p.func_yellow },
    ["@lsp.type.method"]         = { fg = p.func_yellow },

    ["@lsp.type.variable"]       = { fg = p.var_lblue },
    ["@lsp.type.parameter"]      = { fg = p.var_lblue },
    ["@lsp.type.property"]       = { fg = p.var_lblue },

    -- const / readonly 변수는 VSCode Dark+처럼 밝은 시안(#4FC1FF)으로 강조
    ["@lsp.mod.readonly"]               = { fg = p.const_cyan },
    ["@lsp.typemod.variable.readonly"]  = { fg = p.const_cyan },
    ["@lsp.typemod.property.readonly"]  = { fg = p.const_cyan },
}

local function apply_code_highlights()
    for group, opts in pairs(code_highlights) do
        vim.api.nvim_set_hl(0, group, opts)
    end
end

function M.setup()
    apply_code_highlights()

    -- 플러그인 로드 등으로 인해 하이라이트가 초기화되더라도 코드 색상만 다시 입힘
    vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("UserCodeHighlights", { clear = true }),
        callback = apply_code_highlights,
    })
end

return M

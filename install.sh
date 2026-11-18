#!/usr/bin/env bash
# Requirement 확인 전용 스크립트 (설치는 수행하지 않음)

echo "Check Requirement"

missing_required=0
missing_optional=0

has() { command -v "$1" >/dev/null 2>&1; }

# 버전 비교: version_ge <현재> <최소>
version_ge() {
    [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]
}

# check <label> <required|optional> <cmd...>  (cmd 중 하나라도 있으면 OK)
check() {
    local label="$1" level="$2"
    shift 2
    local c
    for c in "$@"; do
        if has "$c"; then
            printf "[OK]      %-14s -> %s\n" "$label" "$(command -v "$c")"
            return 0
        fi
    done
    if [ "$level" = "required" ]; then
        printf "[MISSING] %-14s (required)\n" "$label"
        missing_required=$((missing_required + 1))
    else
        printf "[MISSING] %-14s (optional)\n" "$label"
        missing_optional=$((missing_optional + 1))
    fi
    return 1
}

# check_version <label> <현재버전> <최소버전>
check_version() {
    if [ -z "$2" ]; then
        return
    fi
    if version_ge "$2" "$3"; then
        printf "          %-14s version %s (>= %s)\n" "$1" "$2" "$3"
    else
        printf "[OLD]     %-14s version %s (need >= %s)\n" "$1" "$2" "$3"
        missing_required=$((missing_required + 1))
    fi
}

# --- Required ---
if check nvim required nvim; then
    check_version nvim "$(nvim --version | head -n1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)" "0.11.0"
fi
if check git required git; then
    check_version git "$(git --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)" "2.19.0"
fi
check curl required curl
check tar required tar
check unzip required unzip
check gzip required gzip
check "C compiler" required cc gcc clang
check "C++ compiler" required c++ g++ clang++
check make required make
if check tree-sitter required tree-sitter; then
    check_version tree-sitter "$(tree-sitter --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)" "0.26.1"
fi
check ripgrep required rg

# --- C/C++ 개발용 (필수) ---
if check cmake required cmake; then
    check_version cmake "$(cmake --version | head -n1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)" "3.20.0"
fi
check ninja required ninja

# --- Optional ---
check lazygit optional lazygit
check fd optional fd fdfind

echo
if [ "$missing_required" -eq 0 ]; then
    echo "All required tools are available."
    [ "$missing_optional" -gt 0 ] && echo "($missing_optional optional tool(s) missing)"
    exit 0
else
    echo "$missing_required required requirement(s) missing or outdated."
    exit 1
fi

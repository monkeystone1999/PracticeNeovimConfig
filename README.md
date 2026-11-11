# Requirement

이 Neovim 설정(`init.lua` 및 플러그인)이 정상적으로 동작하기 위해 필요한 외부 도구 목록과, **`sudo` / `apt` 권한이 없는 환경**에서 `curl`을 이용한 로컬 설치(`~/.local/bin`) 및 **소스 정적(Static) 컴파일 가이드**입니다.

---

## 1. 필수 및 권장 도구 요약

| 도구 (명령어) | 최소/권장 버전 | 사용되는 곳 (플러그인 / 기능) | 필수 여부 |
| :--- | :--- | :--- | :---: |
| **Neovim (`nvim`)** | `>= 0.11.0` (`0.12+` 권장) | 코어 에디터, 내장 Treesitter/LSP, `nvim-treesitter`(`main` 브랜치), `lazydev.nvim` | **필수** |
| **Git (`git`)** | `>= 2.19.0` | [`init.lua`](./init.lua)의 `lazy.nvim` 부트스트랩(`--filter=blob:none`) 및 플러그인 업데이트 | **필수** |
| **cURL (`curl`)** | 제한 없음 | `nvim-treesitter` 파서 다운로드, `mason.nvim` LSP 설치, `blink.cmp` 바이너리 다운로드 | **필수** |
| **아카이브 도구 (`tar`, `unzip`, `gzip`)** | 제한 없음 | `mason.nvim`(`lua_ls` 등) 및 `nvim-treesitter` 패키지 압축 해제 | **필수** |
| **C/C++ 컴파일러 (`gcc` 또는 `clang`)** | C99 / C++14 지원 | [`treesitter.lua`](./lua/plugins/treesitter.lua)에서 언어별 파서(`.so`) 컴파일 (Windows는 MSVC `cl.exe` 자동 탐색) | **필수** |
| **tree-sitter CLI (`tree-sitter`)** | `>= 0.26.1` | [`treesitter.lua`](./lua/plugins/treesitter.lua) (`nvim-treesitter` `main` 브랜치 파서 생성 및 빌드) | **필수** |
| **ripgrep (`rg`)** | 최신 버전 | [`telescope.lua`](./lua/plugins/telescope.lua)의 `live_grep` (`<leader>fg`) 및 고속 파일 탐색 | **필수** |
| **fd (`fd`)** | 최신 버전 | [`telescope.lua`](./lua/plugins/telescope.lua)의 `find_files` (`<leader>ff`) 고속 탐색 | 권장 |
| **Nerd Font** | v3 이상 | [`oil.lua`](./lua/plugins/oil.lua) (`nvim-web-devicons`), [`lsp.lua`](./lua/plugins/lsp.lua) (`mason.nvim` UI 아이콘) | 권장 |

---

## 2. 사전 준비: 로컬 설치 경로(`~/.local`) 설정

`sudo`나 `apt` 권한이 없는 환경에서는 사용자 홈 디렉터리 하위의 `~/.local/bin`에 바이너리를 배치합니다. 설치 전 아래 명령어로 디렉터리를 생성하고 `PATH`에 등록하세요.

```bash
mkdir -p ~/.local/bin ~/.local/src

# 현재 셸 세션에 즉시 적용
export PATH="$HOME/.local/bin:$PATH"

# ~/.bashrc 또는 ~/.zshrc 에 영구 등록
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
```

---

## 3. `curl`을 이용한 무권한(Non-root) 바이너리 다운로드

리눅스(`x86_64`) 기준 공식 릴리스에서 정적 링크(musl 등)된 프리빌드 바이너리를 `~/.local/bin`에 바로 다운로드하는 방법입니다.

### 3.1 Neovim (`nvim`)
```bash
curl -fL https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz -o /tmp/nvim.tar.gz
tar -xzf /tmp/nvim.tar.gz -C ~/.local --strip-components=1
rm /tmp/nvim.tar.gz
nvim --version
```

### 3.2 ripgrep (`rg` - musl 정적 빌드 바이너리)
`unknown-linux-musl` 타겟은 정적(Static)으로 빌드되어 있어 구형 리눅스 배포판(낮은 `glibc` 버전)에서도 의존성 문제없이 동작합니다.
```bash
RG_VERSION="14.1.1"
curl -fL "https://github.com/BurntSushi/ripgrep/releases/download/${RG_VERSION}/ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl.tar.gz" -o /tmp/rg.tar.gz
tar -xzf /tmp/rg.tar.gz -C /tmp
mv "/tmp/ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl/rg" ~/.local/bin/rg
chmod +x ~/.local/bin/rg
rm -rf /tmp/rg.tar.gz "/tmp/ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl"
rg --version
```

### 3.3 fd (`fd` - musl 정적 빌드 바이너리)
```bash
FD_VERSION="v10.2.0"
curl -fL "https://github.com/sharkdp/fd/releases/download/${FD_VERSION}/fd-${FD_VERSION}-x86_64-unknown-linux-musl.tar.gz" -o /tmp/fd.tar.gz
tar -xzf /tmp/fd.tar.gz -C /tmp
mv "/tmp/fd-${FD_VERSION}-x86_64-unknown-linux-musl/fd" ~/.local/bin/fd
chmod +x ~/.local/bin/fd
rm -rf /tmp/fd.tar.gz "/tmp/fd-${FD_VERSION}-x86_64-unknown-linux-musl"
fd --version
```

### 3.4 tree-sitter CLI (`tree-sitter`)
`nvim-treesitter` (`main` 브랜치)는 `0.26.1` 이상 버전을 요구합니다.
```bash
TS_VERSION="v0.26.1" # 또는 최신 릴리스 태그
curl -fL "https://github.com/tree-sitter/tree-sitter/releases/download/${TS_VERSION}/tree-sitter-linux-x64.gz" -o /tmp/tree-sitter.gz
gzip -dc /tmp/tree-sitter.gz > ~/.local/bin/tree-sitter
chmod +x ~/.local/bin/tree-sitter
rm /tmp/tree-sitter.gz
tree-sitter --version
```

### 3.5 C 컴파일러 (`zig cc` 포터블 래퍼 활용 - 컴파일러 미설치 서버용)
시스템에 `gcc`/`clang`이 없거나 구버전일 때, 단일 정적 바이너리로 배포되는 **Zig**를 다운로드해 `gcc`/`cc` 래퍼로 사용하면 root 권한 없이 완벽한 C/C++ 컴파일러 환경을 구축할 수 있습니다.
```bash
ZIG_VERSION="0.13.0"
curl -fL "https://ziglang.org/download/${ZIG_VERSION}/zig-linux-x86_64-${ZIG_VERSION}.tar.xz" -o /tmp/zig.tar.xz
mkdir -p ~/.local/opt/zig
tar -xJf /tmp/zig.tar.xz -C ~/.local/opt/zig --strip-components=1
rm /tmp/zig.tar.xz

# cc / gcc 대체 스크립트 생성
cat << 'EOF' > ~/.local/bin/cc
#!/usr/bin/env sh
exec "$HOME/.local/opt/zig/zig" cc "$@"
EOF

cat << 'EOF' > ~/.local/bin/gcc
#!/usr/bin/env sh
exec "$HOME/.local/opt/zig/zig" cc "$@"
EOF

chmod +x ~/.local/bin/cc ~/.local/bin/gcc
```

---

## 4. 프리빌드 버전이 없거나 호환되지 않을 때: 정적(Static) 컴파일 안내서

사내 폐쇄망/구형 커널/특수 아키텍처이거나 시스템의 `glibc` 버전이 낮아(`GLIBC_2.xx not found` 오류 등) 공식 바이너리가 실행되지 않는 경우, 아래 절차에 따라 **사용자 공간(`~/.local`)에서 직접 정적(Static) 컴파일**할 수 있습니다.

### 4.1 Rust 기반 도구 정적 빌드 (`ripgrep`, `fd`, `tree-sitter-cli`)

`rg`, `fd`, `tree-sitter`는 모두 Rust로 작성되어 있어 `rustup`과 `musl` 타겟을 이용하면 외부 공유 라이브러리 의존성이 `0`인 완전한 정적 바이너리(`statically linked`)를 직접 빌드할 수 있습니다.

#### 1단계: 무권한 Rust 툴체인 및 `musl` 타겟 설치
```bash
# root 권한 없이 ~/.cargo 및 ~/.rustup 에 설치
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
source "$HOME/.cargo/env"

# 정적 빌드를 위한 musl 타겟 추가
rustup target add x86_64-unknown-linux-musl
```

> **참고 (`musl-tools`가 없는 경우):** 시스템에 `musl-gcc`가 없다면 앞선 **3.5절의 Zig**나 `cargo-zigbuild`를 사용하거나, `RUSTFLAGS="-C target-feature=+crt-static"` 플래그를 사용해 표준 타겟에서 정적 링크를 수행할 수 있습니다.

#### 2단계: `ripgrep` (`rg`) 소스 다운로드 및 정적 컴파일
```bash
cd ~/.local/src
curl -fL https://github.com/BurntSushi/ripgrep/archive/refs/tags/14.1.1.tar.gz -o rg-src.tar.gz
tar -xzf rg-src.tar.gz && cd ripgrep-14.1.1

RUSTFLAGS="-C target-feature=+crt-static" cargo build --release --target x86_64-unknown-linux-gnu
cp target/x86_64-unknown-linux-gnu/release/rg ~/.local/bin/
```

#### 3단계: `fd` 소스 다운로드 및 정적 컴파일
```bash
cd ~/.local/src
curl -fL https://github.com/sharkdp/fd/archive/refs/tags/v10.2.0.tar.gz -o fd-src.tar.gz
tar -xzf fd-src.tar.gz && cd fd-10.2.0

RUSTFLAGS="-C target-feature=+crt-static" cargo build --release --target x86_64-unknown-linux-gnu
cp target/x86_64-unknown-linux-gnu/release/fd ~/.local/bin/
```

#### 4단계: `tree-sitter-cli` (`>= 0.26.1`) 소스 다운로드 및 정적 컴파일
```bash
cd ~/.local/src
curl -fL https://github.com/tree-sitter/tree-sitter/archive/refs/tags/v0.26.1.tar.gz -o ts-src.tar.gz
tar -xzf ts-src.tar.gz && cd tree-sitter-0.26.1

RUSTFLAGS="-C target-feature=+crt-static" cargo build --release -p tree-sitter-cli --target x86_64-unknown-linux-gnu
cp target/x86_64-unknown-linux-gnu/release/tree-sitter ~/.local/bin/
```

---

### 4.2 `curl` 정적(Static) 소스 컴파일 (시스템에 `curl`이 없거나 구버전일 때)

OpenSSL과 `curl` 소스를 받아 외부 공유 라이브러리에 의존하지 않도록 `~/.local`에 정적 링크로 컴파일하는 방법입니다.

```bash
cd ~/.local/src

# 1. OpenSSL 정적 빌드 (shared 비활성화)
OPENSSL_VER="3.3.2"
wget --no-check-certificate "https://www.openssl.org/source/openssl-${OPENSSL_VER}.tar.gz" -O openssl.tar.gz \
  || curl -kL "https://www.openssl.org/source/openssl-${OPENSSL_VER}.tar.gz" -o openssl.tar.gz
tar -xzf openssl.tar.gz && cd "openssl-${OPENSSL_VER}"
./Configure no-shared --prefix="$HOME/.local/openssl-static" --openssldir="$HOME/.local/openssl-static"
make -j"$(nproc)" && make install_sw

# 2. cURL 정적 빌드
cd ~/.local/src
CURL_VER="8.10.1"
wget --no-check-certificate "https://curl.se/download/curl-${CURL_VER}.tar.gz" -O curl.tar.gz \
  || curl -kL "https://curl.se/download/curl-${CURL_VER}.tar.gz" -o curl.tar.gz
tar -xzf curl.tar.gz && cd "curl-${CURL_VER}"

PKG_CONFIG="pkg-config --static" \
LDFLAGS="-static -L$HOME/.local/openssl-static/lib64 -L$HOME/.local/openssl-static/lib" \
CPPFLAGS="-I$HOME/.local/openssl-static/include" \
./configure \
  --prefix="$HOME/.local" \
  --disable-shared \
  --enable-static \
  --with-openssl="$HOME/.local/openssl-static" \
  --without-libpsl \
  --without-libidn2 \
  --without-nghttp2 \
  --without-zstd \
  --without-brotli

make -j"$(nproc)" LDFLAGS="-all-static -L$HOME/.local/openssl-static/lib64 -L$HOME/.local/openssl-static/lib"
make install
```

---

### 4.3 Neovim (`nvim`) 소스 컴파일 (번들 의존성 정적 포함)

시스템의 `glibc`가 너무 낮아 공식 Neovim 바이너리가 실행되지 않을 때, Neovim이 필요로 하는 의존성(`luajit`, `libuv`, `tree-sitter`, `luv` 등)을 모두 내부적으로 정적 빌드(`DEPS_PREFIX`)하여 `~/.local`에 설치하는 방법입니다.

```bash
cd ~/.local/src
curl -fL https://github.com/neovim/neovim/archive/refs/tags/stable.tar.gz -o nvim-src.tar.gz
tar -xzf nvim-src.tar.gz && cd neovim-stable

# 번들 의존성(bundled deps)을 정적으로 빌드하여 ~/.local 에 설치
make CMAKE_BUILD_TYPE=Release \
     CMAKE_INSTALL_PREFIX="$HOME/.local" \
     USE_BUNDLED=ON \
     -j"$(nproc)"
make install
```

---

### 4.4 GCC (C/C++ 컴파일러) 로컬 소스 빌드

Zig를 사용할 수 없는 환경에서 순수 GCC를 root 권한 없이 `~/.local`에 정적 의존성으로 빌드하는 절차입니다.

```bash
cd ~/.local/src
GCC_VER="13.3.0"
curl -fL "https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VER}/gcc-${GCC_VER}.tar.xz" -o gcc.tar.xz
tar -xJf gcc.tar.xz && cd "gcc-${GCC_VER}"

# 필수 수학 라이브러리(gmp, mpfr, mpc, isl) 소스 자동 다운로드 (정적 링크됨)
./contrib/download_prerequisites

mkdir build && cd build
../configure \
  --prefix="$HOME/.local" \
  --enable-languages=c,c++ \
  --disable-multilib \
  --disable-bootstrap

make -j"$(nproc)"
make install
```

---

## 5. 설치 확인 명령어

모든 도구가 정상적으로 경로(`PATH`)에 잡혀 있는지 아래 명령어로 한 번에 점검할 수 있습니다.

```bash
for cmd in nvim git curl tar unzip gzip cc tree-sitter rg fd; do
  if command -v "$cmd" >/dev/null 2>&1; then
    printf "[OK] %-12s -> %s\n" "$cmd" "$(command -v "$cmd")"
  else
    printf "[MISSING] %s\n" "$cmd"
  fi
done
```

이 Neovim 설정(`init.lua` 및 플러그인)이 정상적으로 동작하기 위해 필요한 외부 도구 목록과, **`sudo` / `apt` 권한이 없는 환경**에서 `curl`을 이용한 로컬 설치(`~/.local/bin`) 및 **소스 정적(Static) 컴파일 가이드**입니다.

---

## 1. 필수 및 권장 도구 요약

| 도구 (명령어) | 최소/권장 버전 | 사용되는 곳 (플러그인 / 기능) | 필수 여부 |
| :--- | :--- | :--- | :---: |
| **Neovim (`nvim`)** | `>= 0.11.0` (`0.12+` 권장) | 코어 에디터, 내장 Treesitter/LSP, `nvim-treesitter`(`main` 브랜치), `lazydev.nvim` | **필수** |
| **Git (`git`)** | `>= 2.19.0` | [`init.lua`](./init.lua)의 `lazy.nvim` 부트스트랩(`--filter=blob:none`) 및 플러그인 업데이트 | **필수** |
| **cURL (`curl`)** | 제한 없음 | `nvim-treesitter` 파서 다운로드, `mason.nvim` LSP 설치, `blink.cmp` 바이너리 다운로드 | **필수** |
| **아카이브 도구 (`tar`, `unzip`, `gzip`)** | 제한 없음 | `mason.nvim`(`lua_ls` 등) 및 `nvim-treesitter` 패키지 압축 해제 | **필수** |
| **C/C++ 컴파일러 (`gcc` 또는 `clang`)** | C99 / C++14 지원 | [`treesitter.lua`](./lua/plugins/treesitter.lua)에서 언어별 파서(`.so`) 컴파일 (Windows는 MSVC `cl.exe` 자동 탐색) | **필수** |
| **tree-sitter CLI (`tree-sitter`)** | `>= 0.26.1` | [`treesitter.lua`](./lua/plugins/treesitter.lua) (`nvim-treesitter` `main` 브랜치 파서 생성 및 빌드) | **필수** |
| **ripgrep (`rg`)** | 최신 버전 | [`telescope.lua`](./lua/plugins/telescope.lua)의 `live_grep` (`<leader>fg`) 및 고속 파일 탐색 | **필수** |
| **fd (`fd`)** | 최신 버전 | [`telescope.lua`](./lua/plugins/telescope.lua)의 `find_files` (`<leader>ff`) 고속 탐색 | 권장 |
| **Nerd Font** | v3 이상 | [`oil.lua`](./lua/plugins/oil.lua) (`nvim-web-devicons`), [`lsp.lua`](./lua/plugins/lsp.lua) (`mason.nvim` UI 아이콘) | 권장 |

---

## 2. 사전 준비: 로컬 설치 경로(`~/.local`) 설정

`sudo`나 `apt` 권한이 없는 환경에서는 사용자 홈 디렉터리 하위의 `~/.local/bin`에 바이너리를 배치합니다. 설치 전 아래 명령어로 디렉터리를 생성하고 `PATH`에 등록하세요.

```bash
mkdir -p ~/.local/bin ~/.local/src

# 현재 셸 세션에 즉시 적용
export PATH="$HOME/.local/bin:$PATH"

# ~/.bashrc 또는 ~/.zshrc 에 영구 등록
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
```

---

## 3. `curl`을 이용한 무권한(Non-root) 바이너리 다운로드

리눅스(`x86_64`) 기준 공식 릴리스에서 정적 링크(musl 등)된 프리빌드 바이너리를 `~/.local/bin`에 바로 다운로드하는 방법입니다.

### 3.1 Neovim (`nvim`)
```bash
curl -fL https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz -o /tmp/nvim.tar.gz
tar -xzf /tmp/nvim.tar.gz -C ~/.local --strip-components=1
rm /tmp/nvim.tar.gz
nvim --version
```

### 3.2 ripgrep (`rg` - musl 정적 빌드 바이너리)
`unknown-linux-musl` 타겟은 정적(Static)으로 빌드되어 있어 구형 리눅스 배포판(낮은 `glibc` 버전)에서도 의존성 문제없이 동작합니다.
```bash
RG_VERSION="14.1.1"
curl -fL "https://github.com/BurntSushi/ripgrep/releases/download/${RG_VERSION}/ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl.tar.gz" -o /tmp/rg.tar.gz
tar -xzf /tmp/rg.tar.gz -C /tmp
mv "/tmp/ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl/rg" ~/.local/bin/rg
chmod +x ~/.local/bin/rg
rm -rf /tmp/rg.tar.gz "/tmp/ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl"
rg --version
```

### 3.3 fd (`fd` - musl 정적 빌드 바이너리)
```bash
FD_VERSION="v10.2.0"
curl -fL "https://github.com/sharkdp/fd/releases/download/${FD_VERSION}/fd-${FD_VERSION}-x86_64-unknown-linux-musl.tar.gz" -o /tmp/fd.tar.gz
tar -xzf /tmp/fd.tar.gz -C /tmp
mv "/tmp/fd-${FD_VERSION}-x86_64-unknown-linux-musl/fd" ~/.local/bin/fd
chmod +x ~/.local/bin/fd
rm -rf /tmp/fd.tar.gz "/tmp/fd-${FD_VERSION}-x86_64-unknown-linux-musl"
fd --version
```

### 3.4 tree-sitter CLI (`tree-sitter`)
`nvim-treesitter` (`main` 브랜치)는 `0.26.1` 이상 버전을 요구합니다.
```bash
TS_VERSION="v0.26.1" # 또는 최신 릴리스 태그
curl -fL "https://github.com/tree-sitter/tree-sitter/releases/download/${TS_VERSION}/tree-sitter-linux-x64.gz" -o /tmp/tree-sitter.gz
gzip -dc /tmp/tree-sitter.gz > ~/.local/bin/tree-sitter
chmod +x ~/.local/bin/tree-sitter
rm /tmp/tree-sitter.gz
tree-sitter --version
```

### 3.5 C 컴파일러 (`zig cc` 포터블 래퍼 활용 - 컴파일러 미설치 서버용)
시스템에 `gcc`/`clang`이 없거나 구버전일 때, 단일 정적 바이너리로 배포되는 **Zig**를 다운로드해 `gcc`/`cc` 래퍼로 사용하면 root 권한 없이 완벽한 C/C++ 컴파일러 환경을 구축할 수 있습니다.
```bash
ZIG_VERSION="0.13.0"
curl -fL "https://ziglang.org/download/${ZIG_VERSION}/zig-linux-x86_64-${ZIG_VERSION}.tar.xz" -o /tmp/zig.tar.xz
mkdir -p ~/.local/opt/zig
tar -xJf /tmp/zig.tar.xz -C ~/.local/opt/zig --strip-components=1
rm /tmp/zig.tar.xz

# cc / gcc 대체 스크립트 생성
cat << 'EOF' > ~/.local/bin/cc
#!/usr/bin/env sh
exec "$HOME/.local/opt/zig/zig" cc "$@"
EOF

cat << 'EOF' > ~/.local/bin/gcc
#!/usr/bin/env sh
exec "$HOME/.local/opt/zig/zig" cc "$@"
EOF

chmod +x ~/.local/bin/cc ~/.local/bin/gcc
```

---

## 4. 프리빌드 버전이 없거나 호환되지 않을 때: 정적(Static) 컴파일 안내서

사내 폐쇄망/구형 커널/특수 아키텍처이거나 시스템의 `glibc` 버전이 낮아(`GLIBC_2.xx not found` 오류 등) 공식 바이너리가 실행되지 않는 경우, 아래 절차에 따라 **사용자 공간(`~/.local`)에서 직접 정적(Static) 컴파일**할 수 있습니다.

### 4.1 Rust 기반 도구 정적 빌드 (`ripgrep`, `fd`, `tree-sitter-cli`)

`rg`, `fd`, `tree-sitter`는 모두 Rust로 작성되어 있어 `rustup`과 `musl` 타겟을 이용하면 외부 공유 라이브러리 의존성이 `0`인 완전한 정적 바이너리(`statically linked`)를 직접 빌드할 수 있습니다.

#### 1단계: 무권한 Rust 툴체인 및 `musl` 타겟 설치
```bash
# root 권한 없이 ~/.cargo 및 ~/.rustup 에 설치
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
source "$HOME/.cargo/env"

# 정적 빌드를 위한 musl 타겟 추가
rustup target add x86_64-unknown-linux-musl
```

> **참고 (`musl-tools`가 없는 경우):** 시스템에 `musl-gcc`가 없다면 앞선 **3.5절의 Zig**나 `cargo-zigbuild`를 사용하거나, `RUSTFLAGS="-C target-feature=+crt-static"` 플래그를 사용해 표준 타겟에서 정적 링크를 수행할 수 있습니다.

#### 2단계: `ripgrep` (`rg`) 소스 다운로드 및 정적 컴파일
```bash
cd ~/.local/src
curl -fL https://github.com/BurntSushi/ripgrep/archive/refs/tags/14.1.1.tar.gz -o rg-src.tar.gz
tar -xzf rg-src.tar.gz && cd ripgrep-14.1.1

RUSTFLAGS="-C target-feature=+crt-static" cargo build --release --target x86_64-unknown-linux-gnu
cp target/x86_64-unknown-linux-gnu/release/rg ~/.local/bin/
```

#### 3단계: `fd` 소스 다운로드 및 정적 컴파일
```bash
cd ~/.local/src
curl -fL https://github.com/sharkdp/fd/archive/refs/tags/v10.2.0.tar.gz -o fd-src.tar.gz
tar -xzf fd-src.tar.gz && cd fd-10.2.0

RUSTFLAGS="-C target-feature=+crt-static" cargo build --release --target x86_64-unknown-linux-gnu
cp target/x86_64-unknown-linux-gnu/release/fd ~/.local/bin/
```

#### 4단계: `tree-sitter-cli` (`>= 0.26.1`) 소스 다운로드 및 정적 컴파일
```bash
cd ~/.local/src
curl -fL https://github.com/tree-sitter/tree-sitter/archive/refs/tags/v0.26.1.tar.gz -o ts-src.tar.gz
tar -xzf ts-src.tar.gz && cd tree-sitter-0.26.1

RUSTFLAGS="-C target-feature=+crt-static" cargo build --release -p tree-sitter-cli --target x86_64-unknown-linux-gnu
cp target/x86_64-unknown-linux-gnu/release/tree-sitter ~/.local/bin/
```

---

### 4.2 `curl` 정적(Static) 소스 컴파일 (시스템에 `curl`이 없거나 구버전일 때)

OpenSSL과 `curl` 소스를 받아 외부 공유 라이브러리에 의존하지 않도록 `~/.local`에 정적 링크로 컴파일하는 방법입니다.

```bash
cd ~/.local/src

# 1. OpenSSL 정적 빌드 (shared 비활성화)
OPENSSL_VER="3.3.2"
wget --no-check-certificate "https://www.openssl.org/source/openssl-${OPENSSL_VER}.tar.gz" -O openssl.tar.gz \
  || curl -kL "https://www.openssl.org/source/openssl-${OPENSSL_VER}.tar.gz" -o openssl.tar.gz
tar -xzf openssl.tar.gz && cd "openssl-${OPENSSL_VER}"
./Configure no-shared --prefix="$HOME/.local/openssl-static" --openssldir="$HOME/.local/openssl-static"
make -j"$(nproc)" && make install_sw

# 2. cURL 정적 빌드
cd ~/.local/src
CURL_VER="8.10.1"
wget --no-check-certificate "https://curl.se/download/curl-${CURL_VER}.tar.gz" -O curl.tar.gz \
  || curl -kL "https://curl.se/download/curl-${CURL_VER}.tar.gz" -o curl.tar.gz
tar -xzf curl.tar.gz && cd "curl-${CURL_VER}"

PKG_CONFIG="pkg-config --static" \
LDFLAGS="-static -L$HOME/.local/openssl-static/lib64 -L$HOME/.local/openssl-static/lib" \
CPPFLAGS="-I$HOME/.local/openssl-static/include" \
./configure \
  --prefix="$HOME/.local" \
  --disable-shared \
  --enable-static \
  --with-openssl="$HOME/.local/openssl-static" \
  --without-libpsl \
  --without-libidn2 \
  --without-nghttp2 \
  --without-zstd \
  --without-brotli

make -j"$(nproc)" LDFLAGS="-all-static -L$HOME/.local/openssl-static/lib64 -L$HOME/.local/openssl-static/lib"
make install
```

---

### 4.3 Neovim (`nvim`) 소스 컴파일 (번들 의존성 정적 포함)

시스템의 `glibc`가 너무 낮아 공식 Neovim 바이너리가 실행되지 않을 때, Neovim이 필요로 하는 의존성(`luajit`, `libuv`, `tree-sitter`, `luv` 등)을 모두 내부적으로 정적 빌드(`DEPS_PREFIX`)하여 `~/.local`에 설치하는 방법입니다.

```bash
cd ~/.local/src
curl -fL https://github.com/neovim/neovim/archive/refs/tags/stable.tar.gz -o nvim-src.tar.gz
tar -xzf nvim-src.tar.gz && cd neovim-stable

# 번들 의존성(bundled deps)을 정적으로 빌드하여 ~/.local 에 설치
make CMAKE_BUILD_TYPE=Release \
     CMAKE_INSTALL_PREFIX="$HOME/.local" \
     USE_BUNDLED=ON \
     -j"$(nproc)"
make install
```

---

### 4.4 GCC (C/C++ 컴파일러) 로컬 소스 빌드

Zig를 사용할 수 없는 환경에서 순수 GCC를 root 권한 없이 `~/.local`에 정적 의존성으로 빌드하는 절차입니다.

```bash
cd ~/.local/src
GCC_VER="13.3.0"
curl -fL "https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VER}/gcc-${GCC_VER}.tar.xz" -o gcc.tar.xz
tar -xJf gcc.tar.xz && cd "gcc-${GCC_VER}"

# 필수 수학 라이브러리(gmp, mpfr, mpc, isl) 소스 자동 다운로드 (정적 링크됨)
./contrib/download_prerequisites

mkdir build && cd build
../configure \
  --prefix="$HOME/.local" \
  --enable-languages=c,c++ \
  --disable-multilib \
  --disable-bootstrap

make -j"$(nproc)"
make install
```

---

## 5. 설치 확인 명령어

모든 도구가 정상적으로 경로(`PATH`)에 잡혀 있는지 아래 명령어로 한 번에 점검할 수 있습니다.

```bash
for cmd in nvim git curl tar unzip gzip cc tree-sitter rg fd; do
  if command -v "$cmd" >/dev/null 2>&1; then
    printf "[OK] %-12s -> %s\n" "$cmd" "$(command -v "$cmd")"
  else
    printf "[MISSING] %s\n" "$cmd"
  fi
done
```

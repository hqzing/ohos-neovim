#!/bin/sh
set -e

alpine_repository="http://dl-cdn.alpinelinux.org/alpine/v3.22/main/aarch64/"

download_alpine_index() {
    curl -fsSL ${alpine_repository}/APKINDEX.tar.gz | tar -zx -C /tmp
}

get_apk_url() {
    package_name=$1
    package_version=$(grep -A1 "^P:${package_name}$" /tmp/APKINDEX | sed -n "s/^V://p")
    apk_file_name=${package_name}-${package_version}.apk
    echo ${alpine_repository}/${apk_file_name}
}

# 准备一些杂项的命令行工具
download_alpine_index
curl -L -O $(get_apk_url busybox-static)
curl -L -O $(get_apk_url make)
curl -L -O $(get_apk_url grep)
curl -L -O $(get_apk_url pcre2)
for file in *.apk; do
  tar -zxf $file -C /
done
rm -rf *.apk
rm /bin/xargs
ln -s /bin/busybox.static /bin/xargs
ln -s /bin/busybox.static /bin/tr
ln -s /bin/busybox.static /bin/expr
ln -s /bin/busybox.static /bin/awk
ln -s /bin/busybox.static /bin/unzip

# 准备 ohos-sdk
sdk_ohos_download_url="https://cidownload.openharmony.cn/version/Master_Version/ohos-sdk-public_ohos/20251030_020613/version-Master_Version-ohos-sdk-public_ohos-20251030_020613-ohos-sdk-public_ohos.tar.gz"
curl $sdk_ohos_download_url -o ohos-sdk-public_ohos.tar.gz
mkdir /opt/ohos-sdk
tar -zxf ohos-sdk-public_ohos.tar.gz -C /opt/ohos-sdk
cd /opt/ohos-sdk/ohos/
unzip -q native-*.zip
unzip -q toolchains-*.zip
cd - >/dev/null

# 准备环境变量
export PATH=$PATH:/opt/ohos-sdk/ohos/native/llvm/bin                # 编译器在这里面
export PATH=$PATH:/opt/ohos-sdk/ohos/native/build-tools/cmake/bin   # cmake 和 ninja 在这里面
export PATH=$PATH:/opt/ohos-sdk/ohos/toolchains/lib                 # 代码签名工具在这里面
export CC=clang                                                     # 编 gettext、conv、ncurses 需要这几个变量
export CXX=clang++
export AR=llvm-ar
export LD=ld.lld

# 编译 gettext。要有这个库才能正常编出 neovim。
curl -L -O http://mirrors.ustc.edu.cn/gnu/gettext/gettext-0.22.tar.gz
tar -zxf gettext-0.22.tar.gz
cd gettext-0.22
./configure --prefix=/opt/gettext-0.22-ohos-arm64 --host=aarch64-linux --disable-shared 
make -j$(nproc)
make install
cd ..

# 编译 libiconv。要有这个库才能正常编出 neovim。
curl -L -O http://mirrors.ustc.edu.cn/gnu/libiconv/libiconv-1.17.tar.gz
tar -zxf libiconv-1.17.tar.gz
cd libiconv-1.17
./configure --prefix=/opt/libiconv-1.17-ohos-arm64 --host=aarch64-linux  --disable-shared
make -j$(nproc)
make install
cd ..

# 准备 neovim 源码
curl -L https://github.com/neovim/neovim/archive/refs/tags/v0.11.4.tar.gz -o neovim-0.11.4.tar.gz
tar -zxf neovim-0.11.4.tar.gz
cd neovim-0.11.4

# 将 neovim 依赖的 libuv 版本改成最新版（1.50.0 改成 1.51.0）
# libuv 1.51.0 做了鸿蒙适配，解决了 pthread_getaffinity_np 接口不存在的编译报错
sed -i 's|https://github.com/libuv/libuv/archive/v1.50.0.tar.gz|https://github.com/libuv/libuv/archive/v1.51.0.tar.gz|g' cmake.deps/deps.txt
sed -i 's|b1ec56444ee3f1e10c8bd3eed16ba47016ed0b94fe42137435aaf2e0bd574579|27e55cf7083913bfb6826ca78cde9de7647cded648d35f24163f2d31bb9f51cd|g' cmake.deps/deps.txt

# 由于 ohos-sdk 里面的 cmake 不支持下载 https 链接，所以这里先手动把依赖的文件下载好
# cmake 检测到文件存在就不会去实时下载，这样可以避免报错
curl --create-dirs -L https://github.com/luajit/luajit/archive/538a82133ad6fddfd0ca64de167c4aca3bc1a2da.tar.gz -o .deps/build/downloads/luajit/538a82133ad6fddfd0ca64de167c4aca3bc1a2da.tar.gz
curl --create-dirs -L https://github.com/libuv/libuv/archive/v1.51.0.tar.gz -o .deps/build/downloads/libuv/v1.51.0.tar.gz
curl --create-dirs -L https://github.com/neovim/unibilium/archive/v2.1.2.tar.gz -o .deps/build/downloads/unibilium/v2.1.2.tar.gz
curl --create-dirs -L https://github.com/lunarmodules/lua-compat-5.3/archive/v0.13.tar.gz -o .deps/build/downloads/lua_compat53/v0.13.tar.gz
curl --create-dirs -L https://github.com/tree-sitter/tree-sitter-c/archive/v0.24.1.tar.gz -o .deps/build/downloads/treesitter_c/v0.24.1.tar.gz
curl --create-dirs -L https://github.com/neovim/tree-sitter-vimdoc/archive/v4.0.0.tar.gz -o .deps/build/downloads/treesitter_vimdoc/v4.0.0.tar.gz
curl --create-dirs -L https://github.com/tree-sitter-grammars/tree-sitter-lua/archive/v0.4.0.tar.gz -o .deps/build/downloads/treesitter_lua/v0.4.0.tar.gz
curl --create-dirs -L https://github.com/tree-sitter-grammars/tree-sitter-markdown/archive/v0.5.0.tar.gz -o .deps/build/downloads/treesitter_markdown/v0.5.0.tar.gz
curl --create-dirs -L https://github.com/tree-sitter-grammars/tree-sitter-vim/archive/v0.7.0.tar.gz -o .deps/build/downloads/treesitter_vim/v0.7.0.tar.gz
curl --create-dirs -L https://github.com/tree-sitter/tree-sitter/archive/v0.25.6.tar.gz -o .deps/build/downloads/treesitter/v0.25.6.tar.gz
curl --create-dirs -L https://github.com/JuliaStrings/utf8proc/archive/v2.10.0.tar.gz -o .deps/build/downloads/utf8proc/v2.10.0.tar.gz
curl --create-dirs -L https://github.com/tree-sitter-grammars/tree-sitter-query/archive/v0.6.2.tar.gz -o .deps/build/downloads/treesitter_query/v0.6.2.tar.gz
curl --create-dirs -L https://github.com/luvit/luv/archive/1.50.0-1.tar.gz -o .deps/build/downloads/luv/1.50.0-1.tar.gz
curl --create-dirs -L https://github.com/neovim/deps/raw/d495ee6f79e7962a53ad79670cb92488abe0b9b4/opt/lpeg-1.1.0.tar.gz -o .deps/build/downloads/lpeg/lpeg-1.1.0.tar.gz

# 把 ar 命令创建出来，避免编到 luajit 的时候报错
ln -s llvm-ar /opt/ohos-sdk/ohos/native/llvm/bin/ar

# 编译 neovim 的捆绑依赖项
cmake -S cmake.deps -B .deps -G Ninja \
  -D CMAKE_BUILD_TYPE=Release \
  -D CMAKE_C_COMPILER=clang \
  -D CMAKE_AR=llvm-ar \
  -D CMAKE_LINKER=ld.lld \
  -D CMAKE_SYSTEM_NAME=Linux \
  -D CMAKE_SYSTEM_PROCESSOR=aarch64
ninja -C .deps

# 编译 neovim 本体
cmake -B build -G Ninja \
  -D CMAKE_BUILD_TYPE=Release \
  -D CMAKE_C_COMPILER=clang \
  -D CMAKE_AR=llvm-ar \
  -D CMAKE_LINKER=ld.lld \
  -D CMAKE_SYSTEM_NAME=Linux \
  -D CMAKE_SYSTEM_PROCESSOR=aarch64 \
  -D LIBINTL_INCLUDE_DIR=/opt/gettext-0.22-ohos-arm64/include \
  -D LIBINTL_LIBRARY=/opt/gettext-0.22-ohos-arm64/lib/libintl.a \
  -D ICONV_INCLUDE_DIR=/opt/libiconv-1.17-ohos-arm64/include \
  -D ICONV_LIBRARY=/opt/libiconv-1.17-ohos-arm64/lib/libiconv.a \
  -D BUILD_SHARED_LIBS=OFF \
  -D CMAKE_INSTALL_PREFIX=/opt/neovim-0.11.4-ohos-arm64
ninja -C build install
cd ..

# 编译 ncurses，获取 terminfo 数据库，并把 terminfo 数据库复制到 neovim 的安装目录中
# 并不是所有 OpenHarmony 环境上都有 terminfo 数据库，为了保证尽量在更多的环境可用，这里需要放一份 terminfo 数据库到 neovim 的安装目录中，随 neovim 一同发布
# terminfo 数据库可以通过编译 ncurses 得到
curl -L -O https://mirrors.ustc.edu.cn/gnu/ncurses/ncurses-6.5.tar.gz
tar -zxf ncurses-6.5.tar.gz
cd ncurses-6.5
./configure \
  --host=aarch64-linux \
  --prefix=/opt/ncurses-6.5-ohos-arm64 \
  --enable-database
make -j$(nproc)
make install
cd ..
cp -r /opt/neovim-0.11.4-ohos-arm64/share/terminfo /opt/neovim-0.11.4-ohos-arm64/share/

# 履行开源义务，把使用的开源软件的 license 全部聚合起来放到制品中
neovim_txt=$(cat neovim-0.11.4/LICENSE.txt; echo)
gettext_txt=$(cat gettext-0.22/COPYING; echo)
libiconv_txt=$(cat libiconv-1.17/COPYING; echo)
ncurses_txt=$(cat ncurses-6.5/COPYING; echo)
printf '%s' "$(cat <<EOF
This document describes the licenses of all software distributed with the
bundled application.
==========================================================================


neovim
=========
$neovim_txt

gettext
=========
$gettext_txt

libiconv
=========
$libiconv_txt

ncurses
=========
$ncurses_txt

EOF
)" >> licenses.txt
cp licenses.txt /opt/neovim-0.11.4-ohos-arm64/

# 代码签名
binary-sign-tool sign -inFile /opt/neovim-0.11.4-ohos-arm64/bin/nvim -outFile /opt/neovim-0.11.4-ohos-arm64/bin/nvim -selfSign 1
find /opt/neovim-0.11.4-ohos-arm64/lib/nvim/parser | xargs -I {} binary-sign-tool sign -inFile {} -outFile {} -selfSign 1 

# 打包最终产物
cd /opt
tar -zcf neovim-0.11.4-ohos-arm64.tar.gz neovim-0.11.4-ohos-arm64

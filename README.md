# ohos-neovim

本项目为 OpenHarmony 平台编译了 neovim，并发布预构建包。

## 获取软件包
前往 [release 页面](https://github.com/Harmonybrew/ohos-zsh/releases) 获取。

## 基础用法
**1\. 在鸿蒙 PC 中使用**

鸿蒙 PC 内置了 vim，在“终端”（HiShell）中默认就能执行 vim 命令，已经可以满足文本编辑的要求，一般情况下不需要再自己安装 neovim 了。

如果你一定要使用 neovim，那也是可以的，只是操作比较复杂。

由于当前鸿蒙 PC 还不支持 在 HiShell 里面运行二进制，所以我们不能以“解压 + 配 PATH” 方式使用。你需要把它做成 hnp 包，然后才能在 HiShell 中调用。详情请参考 [Termony
](https://github.com/TermonyHQ/Termony) 的方案。

**2\. 在鸿蒙开发板中使用**

开发板默认都是 root 环境，我们可以用 hdc 把它推到设备上，然后以“解压 + 配 PATH” 方式使用。

示例：
```sh
hdc file send neovim-0.11.4-ohos-arm64.tar.gz /data
hdc shell

cd /data
tar -zxf neovim-0.11.4-ohos-arm64.tar.gz
export PATH=$PATH:/data/neovim-0.11.4-ohos-arm64/bin
export HOME=/data
export TERM=screen-256color
export TERMINFO=/data/neovim-0.11.4-ohos-arm64/share/terminfo

# 现在可以使用 nvim 命令了
```

这个 nvim 在不同的上位机终端环境中都是适配的，包括 Cmd、PowerShell、Windows Terminal。

不过需要注意，HOME、TERM、TERMINFO 这几个变量缺一不可，因为它们各自处理了不同的问题。

尤其 TERM 变量的值，是有约束的。我们设置的 TERM 值必须是 screen 家族或者 tmux 家族的值。比如这些：screen, screen-256color, tmux, tmux-256color。

存在这个约束，是因为 hdc 在连接 OpenHarmony 设备时会创建一个伪终端（pseudo-terminal），它的行为并不完全像一个标准的 xterm 或 xterm-256color 终端，而更接近于 screen 或 tmux 这类多路复用器的终端模拟方式。只有设置成这两个家族的值，hdc 发送的键码和 terminfo 定义的键码才能匹配，才不会出现按键错位。

**3\. 在 [鸿蒙容器](https://github.com/hqzing/docker-mini-openharmony) 中使用**

容器环境内置了 curl，所以我们可以直接在容器中下载这个软件包，然后以“解压 + 配 PATH” 方式使用。

示例：
```sh
docker run -itd --name=ohos ghcr.io/hqzing/docker-mini-openharmony:latest
docker exec -it ohos sh

cd ~
curl -L -O https://github.com/Harmonybrew/ohos-neovim/releases/download/0.11.4/neovim-0.11.4-ohos-arm64.tar.gz
tar -zxf neovim-0.11.4-ohos-arm64.tar.gz -C /opt
export PATH=/opt/neovim-0.11.4-ohos-arm64/bin

# 现在可以使用 nvim 命令了
```

## 进阶用法
**1\. 单文件使用**

这个 neovim 静态链接了 libc 以外的库，因此具备单文件使用的条件。单文件跑起来是没问题的，只是不完美，你可以根据你的实际情况来权衡是否能接受这些缺陷。

不完美的点：
1. neovim 软件包里面有一些 `lib/nvim/parser/*.so` 文件，里面是一些编程语言的语法解析引擎，供 neovim 做语法高亮、缩进、折叠、增量选择、文本对象、查询等功能使用。如果单文件使用、不带这些文件到安装目录中，neovim 就无法正常使用这些功能，并退回到正则高亮模式。
2. 我们在分发 neovim 的时候，在软件包里面里面放置了一个 `share/terminfo` 目录，里面包含了一个完整的 terminfo 数据库，可以供用户应对各种复杂的终端环境。如果单文件使用、且系统上没有提供你所需的 terminfo 数据库，那可能会导致 neovim 出现键盘错位、鼠标不可用等异常情况。

**2\. 使用自定义的 TERM**

如果这个 zsh 在你的设备上不能正常运行（如键盘按键异常等），可以尝试先设置 TERM 这个环境变量，再启动它。

```sh
export TERM=xterm
zsh
```

这个 zsh 内置了一些常用的 terminfo：xterm, xterm-256color, xterm-color, screen, screen-256color, tmux, tmux-256color, linux, vt100, vt102, ansi

建议结合你自己所使用的终端环境情况，优先从这个列表里面选一个适合你的值作为你的 TERM 环境变量值。

如果这里的值也不能满足（极小概率，只有一些非常深度的使用场景可能遇到），你需要自己弄一套 terminfo 数据库到设备上，把 TERMINFO 环境变量值设置成你自己的 terminfo 数据库目录，再设一个自己想要的 TERM 环境变量值。

## 从源码构建
需要用一台 Linux x64 服务器来运行项目里的 build.sh，以实现 zsh 的交叉编译。

这里以 Ubuntu 24.04 x64 作为示例：
```sh
sudo apt update && sudo apt install -y build-essential unzip
./build.sh
```

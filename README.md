# ohos-neovim

本项目为 OpenHarmony 平台编译了 neovim，并发布预构建包。

我们仅编译了 neovim 软件本身，没有提供插件方面的解决方案，有插件需求的用户需要自己动手解决。

## 获取软件包

前往 [release 页面](https://github.com/Harmonybrew/ohos-neovim/releases) 获取。

## 用法
**1\. 在鸿蒙 PC 中使用**

鸿蒙 PC 内置了 vim，已经可以满足一般的文本编辑需求，建议直接使用系统自带的 vim。

如果你仍希望使用 neovim，那也是可以的，只是操作比较复杂。

因系统限制，我们无法以“解压 + 配 PATH” 的方式使用这个 neovim。你需要把它做成 hnp 包装入系统中，然后才能在“终端”（HiShell）中调用。详情请参考 [Termony
](https://github.com/TermonyHQ/Termony) 的方案。

**2\. 在鸿蒙开发板中使用**

用 hdc 把它推到设备上，然后以“解压 + 配 PATH” 的方式使用。

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

这个 neovim 在不同的上位机终端环境中都是可用的，包括 Cmd、PowerShell、Windows Terminal。

只是需要注意，HOME、TERM、TERMINFO 这几个变量缺一不可，因为它们各自处理了不同的问题。

尤其 TERM 变量的值，是有约束的。当前已知可用的 TERM 值有这些：screen, screen-256color, tmux, tmux-256color。

存在这个约束，是因为 hdc 在连接 OpenHarmony 设备时会创建一个伪终端（pseudo-terminal），它的行为并不完全像一个标准的 xterm 或 xterm-256color 终端，而更接近于 screen 或 tmux 这类多路复用器的终端模拟方式。当我们设置成 screen 或 tmux 家族的值之后，hdc 发送的键码和 terminfo 定义的键码就能匹配了，就不会出现按键错位。

**3\. 在 [鸿蒙容器](https://github.com/hqzing/docker-mini-openharmony) 中使用**

在容器中用 curl 下载这个软件包，然后以“解压 + 配 PATH” 的方式使用。

示例：
```sh
docker run -itd --name=ohos ghcr.io/hqzing/docker-mini-openharmony:latest
docker exec -it ohos sh

cd /root
curl -L -O https://github.com/Harmonybrew/ohos-neovim/releases/download/0.11.4/neovim-0.11.4-ohos-arm64.tar.gz
tar -zxf neovim-0.11.4-ohos-arm64.tar.gz -C /opt
export PATH=/opt/neovim-0.11.4-ohos-arm64/bin

# 现在可以使用 nvim 命令了
```

一般情况下，在容器中不需要额外设置环境变量就能正常使用这个 neovim 。如果你仍遇到了问题，请看下一个章节“常见问题”。

## 从源码构建

**1\. 手动构建**

这个项目使用本地编译（native compilation，也可以叫本机编译或原生编译）的做法来编译鸿蒙版 neovim，而不是交叉编译。

需要在鸿蒙容器中运行项目里的 build.sh，以实现 neovim 的本地编译。

示例：
```sh
git clone https://github.com/Harmonybrew/ohos-neovim.git

docker run -itd --name=ohos ghcr.io/hqzing/docker-mini-openharmony:latest
docker cp ohos-neovim ohos:/root
docker exec -it ohos sh

cd /root/ohos-neovim
./build.sh

# 构建完成后会在容器中生成 /opt/neovim-0.11.4-ohos-arm64.tar.gz
```

**2\. 使用流水线构建**

如果你熟悉 GitHub Actions，你可以直接复用项目内的工作流配置，使用 GitHub 的流水线来完成构建。

这种情况下，你使用的是 GitHub 提供的构建机，不需要自己准备构建环境。

只需要这么做，你就可以进行你的个人构建：
1. Fork 本项目，生成个人仓
2. 在个人仓的“Actions”菜单里面启用工作流
3. 在个人仓提交代码或发版本，触发流水线运行

## 常见问题

**1\. 键盘按键异常**

如果这个 neovim 在你的环境上出现了键盘按键异常的情况，可以尝试先设置 TERM 和 TERMINFO 环境变量，再启动它。

```sh
export TERM=screen-256color
export TERMINFO=<neovim安装目录的绝对路径>/share/terminfo
nvim
```

为了让用户能应对各种复杂的终端场景，我们在软件包里面里面放置了一个 `share/terminfo` 目录，里面包含了一个完整的 terminfo 数据库。

因此，你只要将 TERMINFO 环境变量填成我们带进来的这个`share/terminfo` 目录，你就可以让 neovim 以及其他使用 terminfo 的程序识别这个 terminfo 数据库。

在这基础上，设置一个与你终端环境匹配的 TERM 值，这应该可以解决你的绝大多数问题。如果还不能解决，可以在 issue 里面发起讨论。

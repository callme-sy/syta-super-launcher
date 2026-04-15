<div align="center">

# SYTA Super Launcher

**面向 WSL 优先 AI 编码环境的单文件 Windows 启动器**

<p>
  <img src="https://img.shields.io/badge/Windows-10%2F11-0078D4?style=for-the-badge&logo=windows&logoColor=white" alt="Windows 10/11" />
  <img src="https://img.shields.io/badge/WSL-Ubuntu-0EAD69?style=for-the-badge&logo=ubuntu&logoColor=white" alt="WSL Ubuntu" />
  <img src="https://img.shields.io/badge/Distribution-Single%20File-111111?style=for-the-badge" alt="Single file" />
  <img src="https://img.shields.io/badge/License-MIT-4CAF50?style=for-the-badge" alt="MIT License" />
</p>

</div>

---

## 概览

`syta-super-launcher.bat` 是一个**便携、单文件**的命令入口，用于在 Windows + WSL 上启动和维护 AI 编码环境。

它提供一个统一的交互入口，可以：

- 在 `C:\.CODEX` 下创建和重新打开项目
- 以大小写不敏感、支持部分匹配的方式搜索项目
- 在 WSL 中启动 AI 编码 CLI
- 安装缺失工具
- 直接从主菜单运行清理助手
- 重置已跟踪的工具配置
- 运行轻量或完整更新流程
- 在启动前显示诊断信息

整个运行时都内嵌在 batch 文件本身中。启动时，它会把辅助脚本解包到临时目录，从那里运行 UI，同时把真实安装保留在用户环境中。

## 一览

| 功能 | 说明 |
| --- | --- |
| `Code` | 打开项目并在 WSL 中启动编码 CLI |
| `Install` | 安装或修复环境与受支持工具 |
| `Cleaner helper` | 从主菜单扫描旧 AI CLI 安装与重复 PATH 项 |
| `Reset tool configs` | 检查已跟踪配置/认证路径，只删除你确认的项 |
| `Light update` | 仅更新 AI 编码 CLI |
| `Update all` | 运行更广泛的工具链维护更新 |
| Diagnostics | 显示安装状态、版本与认证/配置提示 |
| Responsive menus | 在较慢菜单准备期间显示加载进度 |
| Update prompt | 检测到新版本时可提示更新启动器 |
| Portability | 以单个 `.bat` 文件发布 |
| Language | 启动器 UI 可自动识别法语 / 英语 / 中文 |

## 支持的工具

### Code 菜单

启动器可在 WSL 中启动：

- `Codex`
- `OMX`
- `OpenCode`
- `Claude Code`
- `Gemini CLI`

### Install 菜单

当前支持：

- `First install`
- `WSL Ubuntu`
- `PowerShell 7`
- `Install core AI CLI tools`
- `Cleaner helper`
- `Reset tool configs`
- `Codex CLI`
- `OpenCode`
- `Oh My OpenAgent`
- `Oh My Codex / OMX`
- `Claude Code`
- `Gemini CLI`
- `DROID CLI`
- `Oh My OpenCode Slim`

`First install` 是面向新手的路径：在需要时先启动 WSL Ubuntu，再询问是否安装或修复 PowerShell 7，最后在 Ubuntu 真正就绪后安装核心 AI CLI 工具。

## 语言

启动器 UI 现在会在 **法语**、**英语**、**中文** 之间自动检测。

也支持手动覆盖：

```powershell
syta-super-launcher.bat -UiLanguage fr
syta-super-launcher.bat -UiLanguage en
syta-super-launcher.bat -UiLanguage zh
```

也可以使用环境变量：

```powershell
set SYTA_LANGUAGE=zh
```

启动器 UI 会遵循该偏好。第三方安装器或 CLI 的输出仍可能使用它们自己的语言。

## 项目目录

所有项目都放在：

```text
C:\.CODEX
```

最近项目状态保存在：

```text
C:\.CODEX\.syta-launcher-state.json
```

## 运行模型

发布文件只有：

```text
syta-super-launcher.bat
```

执行时，启动器会把内嵌脚本解包到 `%TEMP%` 并从那里运行，从而同时保持：

- 单文件分发
- 更丰富的交互 UI
- 安装与更新流程
- WSL 桥接
- 启动前诊断

## 推荐环境

- Windows 10 或 Windows 11
- 已启用 WSL
- WSL 中安装 Ubuntu
- 已安装 Windows Terminal

## 快速开始

```text
1. 下载 syta-super-launcher.bat
2. 双击运行
3. 在新机器上使用 Install -> First install
4. 使用 Code 创建或打开项目并启动工具
```

## 为什么仓库保持极简

此仓库只发布便携启动器和文档。

包含文件：

- `syta-super-launcher.bat`
- `README.md`
- `README.fr.md`
- `README.zh.md`
- `LICENSE`

项目不单独发布解包后的辅助脚本，因为它的目标就是保持**单文件启动器**分发。

## 作者

**Made by Sylvain T.**

## 许可证

基于 **MIT License** 发布。

参见 [LICENSE](./LICENSE)。

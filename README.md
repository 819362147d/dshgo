# dshgo / GroqChat

自制 Groq 聊天 App（iOS），用 Groq 免费 API 跑 gpt-oss-120b 等模型。

- App 名：GroqChat
- Bundle ID：`com.kn.dshgo`
- iOS 17+，Swift 5，SwiftUI
- 聊天界面：消息列表、输入框、发送、新会话、清空
- 设置页：在 App 内填自己的 Groq API Key（存在本机钥匙串，不进仓库）、选模型、调 temperature / max_tokens

## 模型

| 模型 | 说明 |
| --- | --- |
| `openai/gpt-oss-120b`（默认） | 最强，适合复杂任务 |
| `openai/gpt-oss-20b` | 更快更轻，适合日常对话 |
| `qwen/qwen3-32b` | Qwen3，适合中文与代码 |

调用的是 Groq 的 OpenAI 兼容接口 `https://api.groq.com/openai/v1/chat/completions`，非流式。

## 在 App 里填 Key

1. 装好 App 后打开，点右上角齿轮（设置）。
2. 在 console.groq.com 申请一个免费 API Key（`gsk_…` 开头）。
3. 粘贴到设置页的 Key 输入框，点“保存 API Key”。
4. 选模型，回到聊天页就能发消息了。

Key 只存在本机钥匙串里，每次聊天只发给 `api.groq.com`，仓库和源码里没有任何真实 Key。不要把自己的 Key 发给别人或贴到公开地方。

## 用 Codemagic 打未签名 IPA

仓库没有接 Codemagic webhook，也没有 API token，push 不会自动构建，需要手动触发：

1. 打开 Codemagic，添加这个 GitHub 仓库为 app（如果还没加）。
2. 点 **Start build**。
3. Workflow 选 **ios-unsigned**。
4. Branch 选 **master**。
5. 等构建完成，在 Artifacts 里下载 `dshgo_unsigned.ipa`。

构建脚本会校验 `.app` 是否存在，打包后打印 IPA 的 SHA256。

## 安装未签名 IPA

这个 IPA 是**未签名**的，不能直接装，需要自己签名，常用办法：

- AltStore / SideStore：用自己的 Apple ID 签名安装，免费账号 7 天有效期，到期重签。
- TrollStore（如果设备支持）：永久安装，不用重签。

## 本地开发

需要 macOS + Xcode 15+（本仓库是在 Linux 上准备的材料，未在本地编译验证，以 Codemagic 构建结果为准）：

```sh
open GroqChat.xcodeproj
```

## 文件结构

```
GroqChat/
  GroqChatApp.swift   入口
  ContentView.swift   聊天界面
  SettingsView.swift  设置页（Key、模型、参数）
  GroqClient.swift    Groq API 客户端
  Models.swift        数据模型、钥匙串、设置
  Info.plist
  Assets.xcassets/    图标、主题色
GroqChat.xcodeproj/
  project.pbxproj
  xcshareddata/xcschemes/GroqChat.xcscheme
codemagic.yaml        Codemagic 构建配置
```

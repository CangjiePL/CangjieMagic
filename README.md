<div align="center">
  <img src="https://raw.gitcode.com/user-images/assets/4883625/129822f9-5211-43ec-a8b3-3946eb515c17/cj_magic_logo.png" style="width:300px" />
  <br/>
  <img alt="Cangjie Magic" src="https://img.shields.io/badge/Cangjie_Magic-1.0.0-purple">

  <img alt="Cangjie Lang" src="https://img.shields.io/badge/Cangjie_Lang.-1.0.0-blue">

  <img alt="LLM Agent" src="https://img.shields.io/badge/LLM_Agent-green">
</div>

# Cangjie Magic: Make Apps Grow Intelligence and Creativity
---

<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [Cangjie Magic: Make Apps Grow Intelligence and Creativity](#cangjie-magic-make-apps-grow-intelligence-and-creativity)
  - [核心特性 ✨ / Key Features](#核心特性--key-features)
  - [Hello Example](#hello-example)
  - [Install 🔨](#install-)
  - [Tutorial 📚](#tutorial-)
  - [API Manual 📖](#api-manual-)
  - [Examples 🚀](#examples-)
  - [Cangjie Magic 开发者讨论群组](#cangjie-magic-开发者讨论群组)
  - [Other Tutorials](#other-tutorials)
  - [重要变更/Import Changes](#重要变更import-changes)

<!-- /code_chunk_output -->

## 核心特性 ✨ / Key Features

Cangjie Magic 是一个面向 LLM Agent 应用开发的仓颉原生框架。它把 Agent 定义、提示词、工具调用、模型接入、RAG、多 Agent 协作和 MCP 集成封装为仓颉 DSL 与运行时 API，帮助开发者用更少样板代码构建可执行、可组合、可扩展的智能应用。

Cangjie Magic is a Cangjie-native framework for building LLM Agent applications. It provides DSLs and runtime APIs for agent definition, prompting, tool calling, model integration, RAG, multi-agent collaboration, and MCP integration.

**Feature Index**

- Agent 编程模型：仓颉原生 Agent DSL、快捷 AI 函数
- 工具与外部系统：工具调用、Toolset、MCP Client/Server
- 执行与编排：内置执行器、规划 DSL、多 Agent 协作
- 知识增强：RAG、语义检索、向量数据库
- 模型生态：多模型服务商接入、Chat/Embedding/Image 模型
- 人机协同：Human-in-the-Loop、事件处理、执行观察
- 开发者体验：示例、教程、API 文档

| 特性 / Feature | 说明 / Description |
|---|---|
| 仓颉原生 Agent DSL <br/> Cangjie-native Agent DSL | 使用 `@agent`、`@prompt`、`@tool`、`@toolset` 等宏定义 Agent、系统提示词和工具。DSL 基于仓颉元编程机制实现，最终转换为普通仓颉代码并由仓颉编译器编译。<br/> Define agents, system prompts, and tools with macros such as `@agent`, `@prompt`, `@tool`, and `@toolset`. |
| 快捷 AI 函数 <br/> AI functions | 使用 `@ai` 修饰 `foreign func`，把 LLM 能力直接暴露为类型化函数。函数参数和返回值满足 `Jsonable` 即可参与模型调用，也可以配置模型、提示词和工具。<br/> Use `@ai` on `foreign func` to expose LLM capabilities as typed functions with optional prompts, models, and tools. |
| 工具调用与 MCP 集成 <br/> Tools and MCP integration | 工具可以来自全局函数、Agent 成员方法、`Toolset`，也可以来自 MCP Server。支持 `stdioMCP`、`sseMCP`、`httpMCP`，并支持把本地 Agent 或工具暴露为 MCP Server。<br/> Tools can be local functions, agent methods, toolsets, or remote MCP tools over stdio, SSE, or HTTP. |
| 多种执行器与规划 DSL <br/> Executors and planning DSL | 内置 `naive`、`react`、`tool-loop` 执行器；`react`/`tool-loop` 支持最大迭代次数配置。实验性的 `@execution` DSL 支持组合 `plan`、`think`、`action`、`repeat`、`answer` 等执行步骤。<br/> Built-in executors cover direct Q&A, ReAct-style loops, and tool loops; the experimental execution DSL enables custom planning flows. |
| RAG 与语义检索 <br/> RAG and semantic retrieval | 支持在 `@agent` 中配置外部知识源，并提供 embedding、向量数据库、索引映射、`SemanticMap`、`SemanticSet` 等语义检索组件。向量数据库支持内存实现和 Faiss。<br/> Configure external knowledge sources for agents and use semantic retrieval primitives including embeddings, vector databases, and semantic collections. |
| 多模型服务商接入 <br/> Multi-provider model support | 统一使用 `<provider>:<model>` 配置模型，支持 OpenAI、DeepSeek、DashScope、火山方舟、Ollama、Llama.cpp、Anthropic、SiliconFlow、智谱 AI、Google、Moonshot、OpenRouter 等服务商，并支持注册自定义模型。<br/> Configure models with `<provider>:<model>`, use multiple chat/embedding/image providers, or register custom model implementations. |
| 多 Agent 协作 <br/> Multi-agent collaboration | 支持线性协同 `ag1 |> ag2`、主从协同 `leader <= [worker]`、自由讨论 `ag1 \| ag2`，并支持把 AgentGroup 作为子组组合到更复杂流程中。<br/> Compose agents through linear pipelines, leader-worker groups, free discussion groups, and nested subgroups. |
| Human-in-the-Loop | 提供事件处理和交互机制，允许开发者在 Agent 执行过程中观察、拦截或接入人工反馈，适合审批、调试和敏感工具调用场景。<br/> Intercept and interact with agent execution through event handlers for approval, debugging, and human feedback. |
| 示例和文档完善 <br/> Examples and documentation | `src/examples` 提供 quick start、Markdown QA、文档翻译、文件助手、MCP server/client 等示例；`docs/` 提供安装、教程、HITL 和 API 文档。<br/> Example applications and documentation cover quick start, RAG Q&A, document translation, file assistants, MCP servers/clients, HITL, and API references. |

相关入口 / Useful entry points:

- [用户教程 / Tutorial](./docs/tutorial.md)
- [Human-in-the-Loop Tutorial](./docs/hitl.md)
- [API Manual](./docs/api_reference.md)
- [Examples](./src/examples)

## Hello Example

```cangjie
import magic.dsl.*
import magic.prelude.*

@ai[model: "deepseek:deepseek-chat"]
foreign func translate(text: String, targetLang: String): String

main() {
  let msg = translate("你好，Cangjie Magic!", "en")
  println(msg)
}
```

## Install 🔨

👀 详见 [docs/install.md](./docs/install.md)

👀 See [docs/install.md](./docs/install.md)

## Tutorial 📚

👀 详见 [docs/tutorial.md](./docs/tutorial.md)

👀 See [docs/tutorial-en.md](../docs/tutorial-en.md)

❓ Cangjie Magic 的各种 How-To 案例 [docs/how-to.md](./docs/how-to.md)

❓ Various How-To examples of Cangjie Magic [docs/how-to.md](../docs/how-to.md)

## API Manual 📖

👀 详见 [docs/api_reference.md](./docs/api_reference.md)

👀 See [docs/api_reference.md](./docs/api_reference.md)

注意：API 手册由 `doc_generator` 自动生成，大部分情况下是正确的，但如果有不清楚的说明，请直接查看源代码

Note: The API documentation is automatically generated by `doc_generator` and is correct in most cases. However, if any part of the reference is unclear, please refer directly to the source code.

## Examples 🚀

在目录 `src/examples` 下有一些示例程序：

There are some sample programs in the directory src/examples:

| \<name\>  | 说明   |
|---|---|
| `doc_generator`  | 为本项目生成 API 手册 <br> Generates API documentation for this project |
| `doc_translator` | 翻译项目中的中文文档<br> Translate Chinese documents for this project |
| `markdown_qa` | 根据本项目的文档实现问答助手 <br> Implements a Q&A assistant using this project's documentation |
| `quick_start` | 快速开始程序 <br> The quick start program |
| `file_assistant` | 文件管理助手，接入开源 MCP 工具 <br> File management assistant integrated with MCP tools |
| `mcp_server` | 展示如何编写 Agent 并作为 MCP Server <br> Demonstrates how to write an Agent as an MCP Server |
| `mcp_client` | 展示如何接入自己编写的 MCP Server <br> Demonstrates how to connect to a custom MCP Server |

可以通过 `cjpm run --name magic.examples.<name>` 运行。

Run them with `cjpm run --name magic.examples.<name>`.

MCP Server 集合示例：https://gitcode.com/Cangjie-TPC/CangjieMagic-MCPServer

MCP Server Collection Example: https://gitcode.com/Cangjie-TPC/CangjieMagic-MCPServer

## Cangjie Magic 开发者讨论群组

🤝 欢迎加入开发者讨论者群组，一起交流碰撞创意想法，构建最具创意的 Agent 应用！

🤝 Welcome to join the official developer discussion group, where we can exchange and spark creative ideas together to build the most innovative Agent applications!

<div align="center">
  <img src="https://raw.gitcode.com/user-images/assets/4865175/5524b8ff-7dd7-4025-bfd3-07da9e86934b/2026-04-20.png" style="width:300px" />
</div>

## Other Tutorials

大家可以在B站学习东北大学 张引 老师分享的教程
https://www.bilibili.com/video/BV1hQQzYAEHL/?spm_id_from=333.337.search-card.all.click&vd_source=ac4d1bb6a8e4a3751bba687720bd6fd9

## 重要变更/Import Changes
**2025/8/8**:
- 增加 `@tool` 中 `compactable` 配置
  Introduced the `compactable` config of `@tool`

**2025/8/4**:
- 增加 `@toolset` 语法，能够定义工具集
  Introduced the `@toolset` syntax, enabling the definition of toolset classes.

**2025/7/8**:
- `@agent` 的工具配置语法变更；修改 `@ai` 函数语法；新语法详见 [docs/tutorial.md](./docs/tutorial.md)
  The tool configuration syntax for `@agent` has been updated, and the `@ai` function syntax has been modified. Refer to [docs/tutorial-en.md](./docs/tutorial-en.md) for the new syntax details.

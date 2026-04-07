# API Reference

This index tracks the current user-facing packages in `src/`.
Historical package names such as `storage.*`, `vdb`, and `rag.graph` are no longer part of the current public API surface and are not listed as primary entry points here.
Internal helper packages and provider-specific implementation packages may still exist in `src/`, but they are intentionally omitted from this top-level index when they are not recommended as direct user entry points.

## Entry Packages

- 📁 [dsl](./package_docs/dsl.md)
- 📁 [prelude](./package_docs/prelude.md)
- 📁 [config](./package_docs/config.md)
- 📁 [model](./package_docs/model.md)
- 📁 [tool](./package_docs/tool.md)
- 📁 [agent](./package_docs/agent.md)
- 📁 [agent_group](./package_docs/agent_group.md)
- 📁 [interaction](./package_docs/interaction.md)
- 📁 [mcp](./package_docs/mcp.md)
- 📁 [prompt](./package_docs/prompt.md)
- 📁 [rag](./package_docs/rag.md)
- 📁 [rag.splitter](./package_docs/rag.splitter.md)
- 📁 [rag.vdb](./package_docs/rag.vdb.md)
- 📁 [memory](./package_docs/memory.md)
- 📁 [parser](./package_docs/parser.md)
- 📁 [jsonable](./package_docs/jsonable.md)
- 📁 [tokenizer](./package_docs/tokenizer.md)

## Execution Packages

- 📁 [agent_executor](./package_docs/agent_executor.md)
- 📁 [agent_executor.dsl](./package_docs/agent_executor.dsl.md)
- 📁 [agent_executor.naive](./package_docs/agent_executor.naive.md)
- 📁 [agent_executor.react](./package_docs/agent_executor.react.md)
- 📁 [agent_executor.tool_loop](./package_docs/agent_executor.tool_loop.md)

## Low-Level Core Packages

- 📁 [core](./package_docs/core.md)
- 📁 [core.agent](./package_docs/core.agent.md)
- 📁 [core.interaction](./package_docs/core.interaction.md)
- 📁 [core.memory](./package_docs/core.memory.md)
- 📁 [core.message](./package_docs/core.message.md)
- 📁 [core.model](./package_docs/core.model.md)
- 📁 [core.rag](./package_docs/core.rag.md)
- 📁 [core.tokenizer](./package_docs/core.tokenizer.md)
- 📁 [core.tool](./package_docs/core.tool.md)
- 📁 [agent.base](./package_docs/agent.base.md)

## Historical Pages

The following pages remain in `docs/package_docs/` only as migration notes for old package names:

- 📁 [rag.graph](./package_docs/rag.graph.md)
- 📁 [storage](./package_docs/storage.md)
- 📁 [storage.graph](./package_docs/storage.graph.md)
- 📁 [storage.kv](./package_docs/storage.kv.md)
- 📁 [storage.vdb](./package_docs/storage.vdb.md)
- 📁 [vdb](./package_docs/vdb.md)

## Package prelude

`magic.prelude` is the recommended convenience import for application code:

```cangjie
import magic.prelude.*
```

It currently re-exports these Cangjie Magic packages:

- `magic.core.message.*`
- `magic.core.*`
- `magic.agent.base.*`
- `magic.agent.*`
- `magic.prompt.*`
- `magic.agent_group.*`
- `magic.jsonable.*`
- `magic.model.ModelManager`
- `magic.agent_executor.AgentExecutorManager`
- `magic.memory.ShortMemory`
- `magic.rag.RetrieverUtils`
- `magic.tool.{SimpleToolManager, NativeFuncTool}`
- `magic.mcp.*`
- `magic.agent_executor.dsl.{ExecutionDSL, ExecutionState}`
- `magic.skill.{SkillManager, SkillPrompt}`
- `magic.agent_executor.common.{SkillTool, SkillToolsBuilder, ListDirectoryTool, FileReadTool, GlobSearchTool, GrepSearchTool, ShellExecuteTool}`

It also re-exports these standard-library symbols for common workflows:

- `stdx.encoding.json.{JsonValue, JsonObject, JsonException, JsonKind, JsonInt, JsonString, JsonBool, JsonFloat, JsonArray, JsonNull}`
- `std.collection.{ArrayList, HashMap}`

If you want the macro layer as well, pair it with:

```cangjie
import magic.dsl.*
```

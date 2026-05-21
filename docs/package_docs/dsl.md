## Package dsl

```cangjie
import magic.dsl.*
```

`magic.dsl` exports the macro-based authoring layer used throughout Cangjie Magic.

### Public Re-export

```cangjie
public import std.convert.Parsable
```

### Agent And Prompt Macros

#### `@agent`
```cangjie
public macro agent(input: Tokens): Tokens
public macro agent(attr: Tokens, input: Tokens): Tokens
```

Defines an Agent class and wires model, executor, tools, memory, retriever, MCP, and skill configuration.

Recognized attributes:

| Attribute | Type | Description |
|---|---|---|
| `model` | `String` or expression | LLM to use, e.g. `"deepseek:deepseek-chat"`. Defaults to `"deepseek:deepseek-chat"`. |
| `executor` | `String` | Executor name; one of `naive`, `react`, `tool-loop`, `react:<n>`, `tool-loop:<n>`. Defaults to `react`. |
| `description` | `String` | Free-form agent description. |
| `temperature` | expression | Sampling temperature. |
| `rag` | map | Retriever configuration. |
| `memory` | `Bool` | Enables short-term memory. |
| `tools` | array | MCP servers, tool functions, and toolsets the agent can use. |
| `enableToolFilter` | `Bool` | Enables LLM-driven tool filtering. |
| `skillRoot` | `String` or expression | Directory containing per-skill subfolders. Defaults to `None`. When set, the macro instantiates a `SkillManager`, appends the skill instructions block to the system prompt, and injects the `runSkill` tool. When left at its default, the skill feature is fully disabled: no `skillManager` property, no prompt block, and no skill tools (including the file/shell helpers) are added. |
| `skillBuiltinTools` | `Bool` or expression | Whether to also inject the general-purpose skill helpers (`listDirectory`, `fileRead`, `globSearch`, `grepSearch`, `shellExecute`) alongside `runSkill`. Accepts a literal `true`/`false` or any `Bool` expression evaluated at runtime (e.g. `skillBuiltinTools: config.skillBuiltinTools`). Defaults to `true`, but only takes effect when `skillRoot` is set; if `skillRoot` is `None`, this attribute is ignored and no built-in tools are injected. |
| `dump` | `Bool` | Prints the transformed AST for debugging. |

When `skillRoot` is set, the agent exposes a `skillManager: SkillManager` property
backed by the loaded skill root. See the [skill](./skill.md) package for the
loader and prompt helpers and [agent_executor.common](./agent_executor.common.md)
for the injected tools.

#### `@prompt`
```cangjie
public macro prompt(input: Tokens): Tokens
public macro prompt(attr: Tokens, input: Tokens): Tokens
```

Defines the system prompt inside an `@agent`.

#### `@user`
```cangjie
public macro user(input: Tokens): Tokens
public macro user(attr: Tokens, input: Tokens): Tokens
```

Defines the user prompt template inside an `@agent`.

#### `@ai`
```cangjie
public macro ai(input: Tokens): Tokens
public macro ai(attrTokens: Tokens, input: Tokens): Tokens
```

Transforms a `foreign func` into an AI-backed function call.

### Tool And Retriever Macros

#### `@tool`
```cangjie
public macro tool(input: Tokens): Tokens
public macro tool(attrTokens: Tokens, input: Tokens): Tokens
```

Wraps a function as a Magic tool.

#### `@toolset`
```cangjie
public macro toolset(input: Tokens): Tokens
public macro toolset(attrTokens: Tokens, input: Tokens): Tokens
```

Builds a toolset type from a class or struct.

#### `@retriever`
```cangjie
public macro retriever(input: Tokens): Tokens
public macro retriever(attr: Tokens, input: Tokens): Tokens
```

Builds a retriever class or struct and fills in the standard retriever contracts.

### Execution And Interaction Macros

#### `@execution`
```cangjie
public macro execution(input: Tokens): Tokens
public macro execution(attr: Tokens, input: Tokens): Tokens
```

Defines a custom execution pipeline for an `@agent`, backed by `magic.agent_executor.dsl`.

#### `@interact`
```cangjie
public macro interact(attrTokens: Tokens, input: Tokens): Tokens
```

Builds an interaction block around event handlers and a synchronous interaction call.

#### `@asyncInteract`
```cangjie
public macro asyncInteract(attrTokens: Tokens, input: Tokens): Tokens
```

Builds an interaction block around event handlers and an asynchronous interaction call.

#### `@conversation`
```cangjie
public macro conversation(attrTokens: Tokens, input: Tokens): Tokens
```

Creates a conversation-scoped interaction flow.

### Schema And Prompt-Pattern Macros

#### `@jsonable`
```cangjie
public macro jsonable(input: Tokens): Tokens
public macro jsonable(attrTokens: Tokens, input: Tokens): Tokens
```

Generates `Jsonable` support for classes and structs.

#### `@field`
```cangjie
public macro field(attr: Tokens, input: Tokens): Tokens
```

Annotates schema fields used by `@jsonable`.

#### `@constraint`
```cangjie
public macro constraint(attr: Tokens, input: Tokens): Tokens
```

Adds validation constraints to a schema field.

#### `@promptPattern`
```cangjie
public macro promptPattern(input: Tokens): Tokens
public macro promptPattern(attr: Tokens, input: Tokens): Tokens
```

Builds a prompt-pattern class.

#### `@element`
```cangjie
public macro element(input: Tokens): Tokens
public macro element(attr: Tokens, input: Tokens): Tokens
```

Declares a prompt-pattern element.

### Supporting Macros

#### `@handler`
```cangjie
public macro handler(input: Tokens): Tokens
public macro handler(attr: Tokens, input: Tokens): Tokens
```

Declares an event handler.

#### `@alias`
```cangjie
public macro alias(attr: Tokens, input: Tokens): Tokens
```

Declares an alias mapping used by the DSL layer.

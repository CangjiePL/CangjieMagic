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

Defines an Agent class and wires model, executor, tools, memory, retriever, and MCP configuration.

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

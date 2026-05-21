## Package agent_executor.common
- [Package agent_executor.common](#package-agent_executor.common)
  - [class AgentExecutionInfo](#class-agentexecutioninfo)
    - [func addMessage](#func-addmessage)
    - [func addMessages](#func-addmessages)
    - [func addRequest](#func-addrequest)
    - [func addStepMessage](#func-addstepmessage)
    - [prop chatRound](#prop-chatround)
    - [prop events](#prop-events)
    - [func init](#func-init)
    - [func markCancellation](#func-markcancellation)
    - [prop messages](#prop-messages)
    - [func removeLastMessage](#func-removelastmessage)
    - [prop retrievalInfo](#prop-retrievalinfo)
    - [func setAnswer](#func-setanswer)
  - [Skill built-in tools](#skill-built-in-tools)
    - [class SkillTool](#class-skilltool)
    - [class ListDirectoryTool](#class-listdirectorytool)
    - [class FileReadTool](#class-filereadtool)
    - [class GlobSearchTool](#class-globsearchtool)
    - [class GrepSearchTool](#class-grepsearchtool)
    - [class ShellExecuteTool](#class-shellexecutetool)
    - [struct SkillToolsBuilder](#struct-skilltoolsbuilder)

### class AgentExecutionInfo
#### func addMessage
```
func addMessage(msg: Message): Unit
```
- Description: Adds a single message to the execution.
- Parameters:
  - `msg`: `Message`, The message to be added.

#### func addMessages
```
func addMessages(msgs: Array<Message>): Unit
```
- Description: Adds multiple messages to the execution.
- Parameters:
  - `msgs`: `Array<Message>`, The messages to be added.

#### func addRequest
```
func addRequest(request: AgentRequest): Unit
```
- Description: Adds a new request to the execution and processes it.
- Parameters:
  - `request`: `AgentRequest`, The request to be added.

#### func addStepMessage
```
func addStepMessage(msg: Message): Unit
```
- Description: Adds a step message to the execution.
- Parameters:
  - `msg`: `Message`, The step message to be added.

#### prop chatRound
```
prop chatRound: ChatRound
```
- Description: Gets the chat round information for this execution.

#### prop events
```
prop events: EventStream
```
- Description: Gets the event stream associated with this execution.

#### func init
```
init(agent: Agent, request: AgentRequest)
```
- Description: Initializes the AgentExecutionInfo with the given agent and request.
- Parameters:
  - `agent`: `Agent`, The agent associated with this execution.
  - `request`: `AgentRequest`, The request associated with this execution.

#### func markCancellation
```
func markCancellation(): Unit
```
- Description: Marks the execution as cancelled.

#### prop messages
```
prop messages: MessageList
```
- Description: Gets the list of messages associated with this execution.

#### func removeLastMessage
```
func removeLastMessage(): Unit
```
- Description: Removes the last message from the execution.

#### prop retrievalInfo
```
prop retrievalInfo: ArrayList<RetrievalInfo>
```
- Description: Gets the retrieval information associated with this execution.

#### func setAnswer
```
func setAnswer(answer: String): Unit
```
- Description: Sets the answer for the execution.
- Parameters:
  - `answer`: `String`, The answer to be set.


### Skill built-in tools

These tools are auto-injected by the `@agent` macro **only when the `skillRoot`
attribute is set**. `skillRoot` defaults to `None`; with the default, none of
these tools are added to the agent and `skillBuiltinTools` is ignored. When
`skillRoot` is set, `SkillTool` (the `runSkill` tool) is always added, and the
five general-purpose tools below are added when `skillBuiltinTools` is left
at its default of `true`. To use these tools without enabling the skill
system you would need to instantiate them directly and add them via
`agent.toolManager.addTool(...)`. See the [skill](./skill.md) package for the
underlying loader and the `dsl` doc for the `@agent` attributes that drive
injection.

When a user-supplied tool has the same name as a built-in, the user tool wins
(built-ins are added first, then overwritten by name). `SkillToolsBuilder`
logs a status line at agent construction so silent overrides are visible.

#### class SkillTool
```
public class SkillTool <: NativeFuncTool {
    public init(skillManager: SkillManager)
}
```
- Tool name: `runSkill`.
- Description: Loads the body of a skill and returns it so the agent can
  follow the skill's instructions. Parameters: `name: String` — the name
  of the skill to load.

#### class ListDirectoryTool
```
public class ListDirectoryTool <: NativeFuncTool {
    public init()
}
```
- Tool name: `listDirectory`.
- Description: Lists the entries of an absolute directory path. Directories
  are suffixed with `/`. Relative paths are rejected.

#### class FileReadTool
```
public class FileReadTool <: NativeFuncTool {
    public init()
}
```
- Tool name: `fileRead`.
- Description: Reads a file at an absolute path and returns its contents
  wrapped in a `<file-content>` block. Optional `startLine` / `endLine`
  parameters narrow the result to a 1-based inclusive line range.

#### class GlobSearchTool
```
public class GlobSearchTool <: NativeFuncTool {
    public init()
}
```
- Tool name: `globSearch`.
- Description: Recursively finds files matching a glob `pattern` under an
  absolute `path`. Skips common build/VCS directories (`.git`,
  `node_modules`, `target`, `build`, `dist`, `.cache`).

#### class GrepSearchTool
```
public class GrepSearchTool <: NativeFuncTool {
    public init()
}
```
- Tool name: `grepSearch`.
- Description: Searches file contents for a regex `pattern` under an
  absolute `path`. Supports an optional `fileType` glob filter.

#### class ShellExecuteTool
```
public class ShellExecuteTool <: NativeFuncTool {
    public init()
}
```
- Tool name: `shellExecute`.
- Description: Runs a shell command (PowerShell on Windows, `/bin/sh`
  elsewhere). Optional `workDir` must be an absolute path. Output is
  truncated to ~30 KB per stream; default timeout is 180 s (max 600 s).

#### struct SkillToolsBuilder
```
public struct SkillToolsBuilder {
    public static func build(skillManager: SkillManager,
                             builtinEnabled!: Bool): Array<Tool>
    public static func computeSkillToolStatus(tm: ToolManager,
                                              builtinEnabled: Bool): Array<String>
    public static func logSkillToolStatus(agentName: String,
                                          tm: ToolManager,
                                          builtinEnabled: Bool): Unit
}
```
- Description: Builds and reports on the skill built-in tool set.
- `build` returns `[SkillTool]` when `builtinEnabled` is `false`, otherwise
  `SkillTool` plus the five general-purpose tools above.
- `computeSkillToolStatus` returns the status messages that
  `logSkillToolStatus` writes at INFO level — useful in tests.


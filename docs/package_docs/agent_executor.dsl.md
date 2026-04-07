## Package agent_executor.dsl

```cangjie
import magic.agent_executor.dsl.*
```

This package provides the execution-state model and operators used by `@execution` and `DslExecutor`.

### type DSLExecutionOp
```cangjie
public type DSLExecutionOp = (ExecutionState) -> ExecutionState
```

The basic execution operator signature.

### class DSLOperator
```cangjie
open public class DSLOperator
public operator func ()(state: ExecutionState): ExecutionState
public operator func ()(clause: DSLWhenClause): DSLWhenClause
```

Wraps a `DSLExecutionOp` and allows pipeline composition.

### class DSLAction
```cangjie
public class DSLAction <: DSLOperator
public operator func ()(tool!: Tool): DSLOperator
```

Represents an action step and can be specialized to a concrete tool.

### struct DSLWhenClause
```cangjie
public struct DSLWhenClause
public init(condition: String)
public init()
```

Represents one branch used by `ExecutionDSL.decide(...)`.

### struct ExecutionDSL
```cangjie
public struct ExecutionDSL
public static let plan = DSLOperator(doPlan)
public static let think = DSLOperator(doThink)
public static let action = DSLAction()
public static let done = DSLOperator(doDone)
public static let answer = DSLOperator(doAnswer)
public static let otherwise = DSLWhenClause()
public static func repeat(op: DSLExecutionOp, until!: String): DSLOperator
public static func orchestrate(op: DSLExecutionOp): DSLOperator
public static func decide(whenClauses: Array<DSLWhenClause>): DSLOperator
public static func decide(whenClause: DSLWhenClause): DSLOperator
public static func when(condition: String): DSLWhenClause
```

Provides the standard execution operators used inside `@execution`.

### class ExecutionState
```cangjie
public class ExecutionState
public init()
```

The runtime state object passed through DSL execution operators. Its public surface is intentionally narrow; most state mutation and inspection is performed through the DSL operators and package internals.

### class DslExecutor
```cangjie
public class DslExecutor <: AgentExecutor
override public prop name: String
override public func run(agent: Agent, request: AgentRequest): AgentResponse
override public func asyncRun(agent: Agent, request: AgentRequest): AsyncAgentResponse
```

Runs agents that define a custom `@execution` pipeline.

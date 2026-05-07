## Package prompt

```cangjie
import magic.prompt.*
```

`magic.prompt` contains prompt-building interfaces and the built-in prompt-pattern classes.

### Interfaces

#### interface ToPrompt
```cangjie
public interface ToPrompt
```

Contract for values that can be rendered into prompt text.

#### interface Template
```cangjie
public interface Template
```

Base contract used by prompt templating helpers.

### Built-in Prompt Patterns

#### class APE
```cangjie
public init(action!: String, purpose!: String, expectation!: String)
public func toString(): String
```

Action, Purpose, Expectation.

#### class BROKE
```cangjie
public init(background!: String, role!: String, objectives!: String, keyResult!: String, evolve!: String)
public func toString(): String
```

Background, Role, Objectives, Key Result, Evolve.

#### class CARE
```cangjie
public init(context!: String, action!: String, result!: String, example!: String)
public func toString(): String
```

Context, Action, Result, Example.

#### class COAST
```cangjie
public init(context!: String, objective!: String, action!: String, scenario!: String, task!: String)
public func toString(): String
```

Context, Objective, Action, Scenario, Task.

#### class CRISPE
```cangjie
public init(capacityAndRole!: String, insight!: String, statement!: String, personality!: String, experiment!: String)
public func toString(): String
```

Capacity and Role, Insight, Statement, Personality, Experiment.

#### class ERA
```cangjie
public init(expectation!: String, role!: String, action!: String)
public func toString(): String
```

Expectation, Role, Action.

#### class ICIO
```cangjie
public init(instruction!: String, context!: String, input!: String, output!: String)
public func toString(): String
```

Instruction, Context, Input, Output.

#### class RACE
```cangjie
public init(role!: String, action!: String, context!: String, expectation!: String)
public func toString(): String
```

Role, Action, Context, Expectation.

#### class RISE
```cangjie
public init(role!: String, input!: String, steps!: String, expectation!: String)
public func toString(): String
```

Role, Input, Steps, Expectation.

#### class ROSES
```cangjie
public init(role!: String, objective!: String, scenario!: String, expectation!: String, steps!: String)
public func toString(): String
```

Role, Objective, Scenario, Expectation, Steps.

#### class SAGE
```cangjie
public init(situation!: String, action!: String, goal!: String, expectation!: String)
public func toString(): String
```

Situation, Action, Goal, Expectation.

#### class TAG
```cangjie
public init(task!: String, action!: String, goal!: String)
public func toString(): String
```

Task, Action, Goal.

#### class TRACE
```cangjie
public init(task!: String, request!: String, action!: String, context!: String, example!: String)
public func toString(): String
```

Task, Request, Action, Context, Example.

## Package core

`magic.core` is the low-level aggregator package:

```cangjie
import magic.core.*
```

It currently re-exports the foundational contracts from these packages:

- `magic.core.agent.*`
- `magic.core.tool.*`
- `magic.core.memory.*`
- `magic.core.model.*`
- `magic.core.rag.*`

Use `magic.core.*` when you want the core interfaces without importing the higher-level conveniences from `magic.prelude.*`.

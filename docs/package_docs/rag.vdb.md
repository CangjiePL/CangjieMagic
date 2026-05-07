## Package rag.vdb

```cangjie
import magic.rag.vdb.*
```

`magic.rag.vdb` is the current vector-store package. It replaces the old `vdb` and `storage.vdb` package names that still exist only as migration notes in this repository.

### class InMemoryVectorDatabase
```cangjie
public class InMemoryVectorDatabase <: VectorDatabase<InMemoryVectorDatabase>
public func setVector(index: Int64, vector: Vector): Unit
public override func addVector(vector: Vector): Unit
public override func search(queryVec: Vector, number!: Int64 = 5, minDistance!: Float64 = 0.6): Array<SearchResult>
public override func save(filePath: String): Unit
public static redef func load(filePath: String): InMemoryVectorDatabase
```

In-memory vector database implementation.

### class FaissVectorDatabase
```cangjie
@When[faiss == "enable"]
public class FaissVectorDatabase <: VectorDatabase<FaissVectorDatabase>
public init(dimension!: Int64 = 1536)
public func close(): Unit
public override func save(filePath: String): Unit
public static redef func load(filePath: String): FaissVectorDatabase
public override func addVector(vector: Vector): Unit
public override func search(queryVec: Vector, number!: Int64 = 5, minDistance!: Float64 = 0.6): Array<SearchResult>
```

Faiss-backed vector database, available only when `faiss == "enable"`.

### class SimpleIndexMap
```cangjie
public class SimpleIndexMap <: IndexMap<SimpleIndexMap, String> & Serializable<SimpleIndexMap>
public func set(index: Int64, content: String): Unit
public override func add(content: String): Unit
public override func get(index: Int64): String
public override func save(filePath: String): Unit
public static redef func load(filePath: String): SimpleIndexMap
```

Simple string index map implementation.

### class JsonlIndexMap<T>
```cangjie
public class JsonlIndexMap<T> <: IndexMap<JsonlIndexMap<T>, T> where T <: Jsonable<T> & ToPrompt
public init()
public override func add(content: T): Unit
public override func get(index: Int64): T
public override func save(filePath: String): Unit
public static redef func load(filePath: String): JsonlIndexMap<T>
```

JSONL-backed index map implementation.

### class VectorBuilder
```cangjie
public class VectorBuilder
public VectorBuilder(private let model!: EmbeddingModel)
public func createEmbeddingVector(content: String): Vector
```

Turns promptable content into embedding vectors.

### class SemanticMap<VDB, IMAP, T>
```cangjie
public class SemanticMap<VDB, IMAP, T> where VDB <: VectorDatabase<VDB>, IMAP <: IndexMap<IMAP, T>, T <: ToPrompt
public let vectorDB: VDB
public let indexMap: IMAP
public init(vectorDB!: VDB, indexMap!: IMAP, embeddingModel!: Option<EmbeddingModel> = None)
public mut prop embeddingModel: EmbeddingModel
public func put(key: String, value: T): Unit
public func search(query: String, number!: Int64 = 5, minDistance!: Float64 = 0.3): Array<T>
public func save(dirPath: String): Unit
public static func load(dirPath: String): SemanticMap<VDB, IMAP, T>
```

Stores promptable values in a vector database plus an index map.

### class SemanticSet<VDB, IMAP, T>
```cangjie
public class SemanticSet<VDB, IMAP, T> where VDB <: VectorDatabase<VDB>, IMAP <: IndexMap<IMAP, T>, T <: ToString
public init(vectorDB!: VDB, indexMap!: IMAP, embeddingModel!: Option<EmbeddingModel> = None)
public mut prop embeddingModel: EmbeddingModel
public func put(value: T): Unit
public func search(query: String, number!: Int64 = 5, minDistance!: Float64 = 0.3): Array<T>
public func save(dirPath: String): Unit
public static func load(dirPath: String): SemanticSet<VDB, IMAP, T>
```

Convenience wrapper for semantic search where key and value are the same logical object.

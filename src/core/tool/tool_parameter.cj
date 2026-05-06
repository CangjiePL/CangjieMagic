/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.core.tool

import magic.jsonable.TypeSchema

public struct ToolParameter {
    public let name: String
    public let description: String
    public let typeSchema: TypeSchema
    public let required: Bool

    public init(name: String, description: String, typeSchema: TypeSchema, required!: Bool = true) {
        this.name = name
        this.description = description
        this.typeSchema = typeSchema
        this.required = required
    }
}

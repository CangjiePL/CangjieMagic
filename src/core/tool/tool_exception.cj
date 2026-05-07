/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.core.tool

open public class ToolException <: Exception {
    public let reason: String
    public init(reason: String) {
        super(reason)
        this.reason = reason
    }
}

public class ToolArgumentValidationException <: ToolException {
    public let toolName: String
    public let parameterName: String

    public init(toolName!: String, parameterName!: String = "", reason!: String) {
        super(reason)
        this.toolName = toolName
        this.parameterName = parameterName
    }
}

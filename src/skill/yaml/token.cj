/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.skill.yaml

/**
 * Represents a token in YAML parsing.
 */
public class Token {
    public var tokenType: TokenType
    public var raw: String
    public let line: Int
    public let col: Int

    public init(tokenType: TokenType, raw: String, line: Int, col: Int) {
        this.tokenType = tokenType
        this.raw = raw
        this.line = line
        this.col = col
    }

    public func changeTokenType(tokenType: TokenType): Unit {
        this.tokenType = tokenType
    }

    public func changeRaw(raw: String): Unit {
        this.raw = raw
    }

}
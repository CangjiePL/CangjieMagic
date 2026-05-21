/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.skill.yaml

/**
 * Token types for YAML parsing.
 */
public enum TokenType <: ToString {
    | Scalar
    | Dash
    | Colon
    | Eol
    | Eof

    public operator func ==(other: TokenType): Bool {
        match((this, other)) {
            case (TokenType.Scalar, TokenType.Scalar) => return true
            case (TokenType.Dash, TokenType.Dash) => return true
            case (TokenType.Colon, TokenType.Colon) => return true
            case (TokenType.Eol, TokenType.Eol) => return true
            case (TokenType.Eof, TokenType.Eof) => return true
            case _ => return false
        }
    }

    public operator func !=(other: TokenType): Bool {
        !(this == other)
    }
    
    public func toString(): String {
        match (this) {
            case TokenType.Scalar => return "Scalar"
            case TokenType.Dash => return "Dash"
            case TokenType.Colon => return "Colon"
            case TokenType.Eol => return "Eol"
            case TokenType.Eof => return "Eof"
        }
    }
}
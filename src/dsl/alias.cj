/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
macro package magic.dsl

import std.collection.ArrayList
import std.ast.*

/**
 * @jsonable
 * class A {
 *   @alias("alias_a")
 *   let a: String
 * }
 */
public macro alias(attr: Tokens, input: Tokens): Tokens {
    assertParentContext("jsonable")
    let jsonName = if (let Some(d) <- getAttrJsonName(attr)) {
        d
    } else {
        throw DslException("@alias must contain string literals as attributes")
    }

    let decl: Decl = parseDecl(input)
    if (!decl.isVarDecl()) {
        throw DslException("@alias must annotate variable definitions")
    }
    let varDecl = decl.asVarDecl()
    let varName = varDecl.identifier.value
    setItem("alias", "${varName}:${jsonName}")
    return input
}

func getAttrJsonName(attr: Tokens): Option<String> {
    let buffer = ArrayList<String>()
    for (token in attr) {
        if (isTokenOfKind(token, [TokenKind.NL, TokenKind.COMMA])) {
            continue
        }
        if (!isTokenStringLiteral(token)) {
            throw DslException("@alias accepts only string values as attributes")
        }
        buffer.add(token.value)
    }
    if (buffer.size != 1) {
        throw DslException("@alias accepts only one string value as attribute")
    }
    return buffer[0]
}
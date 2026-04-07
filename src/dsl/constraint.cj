/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
macro package magic.dsl

import std.ast.*

public macro constraint(attr: Tokens, input: Tokens): Tokens {
    assertParentContext("jsonable")

    let decl: Decl = parseDecl(input)
    if (!decl.isVarDecl()) {
        throw DslException("@constraint must annotate variable definitions")
    }
    if (attr.size == 0) {
        throw DslException("@constraint must contain a boolean expression")
    }

    let varDecl = decl.asVarDecl()
    setItem("fieldName", varDecl.identifier.value)
    setItem("expr", attr)
    return input
}

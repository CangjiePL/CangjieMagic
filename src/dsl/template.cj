/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
macro package magic.dsl

import std.ast.*
import std.collection.{ArrayList, map, collectArray, HashMap}
import std.fs.*
import std.regex.{Regex, MatchData}
import stdx.encoding.base64.*



class TemplateAttr <: Attr {
    TemplateAttr(map: AttrMap) { super(map) }

    init() { super(AttrMap()) }

    prop path: Option<String> {
        get() {
            getLiteral("path")
        }
    }

    prop prefix: Option<String> {
        get() {
            getLiteral("prefix")
        }
    }

    prop compile: Bool {
        get() {
            getBool("compile", default: true)
        }
    }

    prop category: Option<String> {
        get() {
            getLiteral("category")
        }
    }

    prop thumbnail: Option<String> {
        get() {
            getLiteral("thumbnail")
        }
    }

    prop title: Option<String> {
        get() {
            getLiteral("title")
        }
    }

    prop desc: Option<String> {
        get() {
            getLiteral("desc")
        }
    }

    static func parse(attrTokens: Tokens): TemplateAttr {
        let map = AttrParser(attrTokens).parseAttr(
            macroName: "template",
            validKeys: ["prefix", "path", "compile", "dump", "thumbnail", "title", "desc", "category"]
        )
        return TemplateAttr(map)
    }
}

/**
 * This macro is used to define a template.
 * Its function body has a single string literal that is the template content.
 */
public macro template(input: Tokens): Tokens {
    let attr = TemplateAttr()
    return transformTemplate(input, attr)
}

public macro template(attrTokens: Tokens, input: Tokens): Tokens {
    let attr = TemplateAttr.parse(attrTokens)
    let content = transformTemplate(input, attr)
    if (attr.dump) {
        printTokens(content)
    }
    return content
}

func imgToBase64(imagePath: String) {
    let imageBytes = File.readFrom(imagePath)
     return toBase64String(imageBytes)
}

/**
 * Transform the function as a render of a template.
 * @template
 * func foo(<args>) { <body> }
 * AS
 * func foo(<args>) {
 *   let engine = TemplateEngine()
 *   engine.set("<arg0>", <arg0>)
 *   engine.set("<arg1>", <arg1>)
 *   ...
 *   return engine.render(<body>)
 * }
 */
func transformTemplate(input: Tokens, attr: TemplateAttr): Tokens {
    let decl = parseDecl(input)
    if (!decl.isFuncDecl()) {
        throw DslException("@template should be called on function declarations")
    }
    let funcDecl = decl.asFuncDecl()
    let modifier = funcDecl.modifiers
    let genericTypeParam = getGenericTypeParamsTokens(funcDecl)
    let genericConstraint = getGenericConstraintsTokens(funcDecl)
    let args: Tokens = joinTokens(
        getFuncParamNames(funcDecl) |>
            map { name: String => newIdentifierToken(name) } |>
            collectArray,
        Token(TokenKind.COMMA)
    )

    let prefix = attr.prefix ?? ""
    let category = attr.category ?? ""
    let thumbnail = attr.thumbnail ?? ""
    let title = attr.title ?? ""
    let desc = attr.desc ?? ""
    var template = if (let Some(path) <- attr.path) {
        if (!exists(path)) {
            throw DslException("`path` refers to non-existing file: ${path}")
        }
        escapeStringForTemplate(readFile(path))
    } else {
        let body = funcDecl.block.nodes[0]
        if (funcDecl.block.nodes.size != 1 || !body.isStringLiteral()) {
            throw DslException("@template should have a single string literal as the body")
        }
        body.asLitConstExpr().literal.value
    }

    let retType = checkFuncRetString(funcDecl)
    let templateClassName = newIdentifierToken("__Template_of_${funcDecl.identifier.value}")
    let identStr = funcDecl.identifier.value
    // When compile is true, we compile the template into a function body
    // Otherwise, we use the TemplateEngine to render the template during execution
    if (attr.compile) {
        if (category == "resume") {
            var styleStr = ""
            var bodyStr = ""
            var scriptStr = ""
            var endStr = ""
            let styleArr = template.split("</style>")
            if (styleArr.size > 1) {
                styleStr = styleArr[0] + moreResumeButtonCss + "\n</style>\n"
            }
            var bodyArr = styleArr[1].split("<script>")
            if (bodyArr.size > 1) {
                bodyStr = bodyArr[0] + moreResumeButtonBody + "\n"
                let scriptArr = bodyArr[1].split("</script>")
                scriptStr = "\n<script>\n" + scriptArr[0] + moreResumeButtonScript + "\n</script>\n"
                endStr = scriptArr[1]
            } else {
                bodyArr = styleArr[1].split("</body>")
                bodyStr = bodyArr[0] + moreResumeButtonBody + "\n"
                scriptStr = "\n<script>\n" + moreResumeButtonScript + "\n</script>\n"
                endStr = bodyArr[1]
            }
            template = styleStr + bodyStr + scriptStr + endStr
        }

        let body = TemplateCompiler().compile(prefix + template)
        if (category == "resume") {
            let base64 = "data:image/png;base64," + imgToBase64(thumbnail)
            return quote(

                $modifier class $templateClassName <: Template {
                    public redef static prop metadata: TemplateMetadata {
                        get() { metadata }
                    }

                    public override prop html: String {
                        get() { html }
                    }

                    static init() {
                        let metadata = TemplateMetadata($base64, $title, $desc, $category, $identStr)
                        TemplateManager.register(metadata)
                    }
                }

                $modifier func $(funcDecl.identifier) $genericTypeParam ( $(funcDecl.funcParams) ): $retType $genericConstraint {
                    $templateClassName()
                    let sb = StringBuilder()
                    let thumbnails = TemplateManager.get($category)
                    let title = $title
                    $body
                    return sb.toString()
                }
            )
        }
        return quote(
            $modifier func $(funcDecl.identifier) $genericTypeParam ( $(funcDecl.funcParams) ): $retType $genericConstraint {
                let sb = StringBuilder()
                $body
                return sb.toString()
            }
        )
    } else {
        let initContext = Tokens()
        for (name in getFuncParamNames(funcDecl)) {
            initContext.append(quote(
                engine.set($(newLiteralToken(name)), $(newIdentifierToken(name)))
            ))
        }
        return quote(
            $modifier func $(funcDecl.identifier) $genericTypeParam ( $(funcDecl.funcParams) ): $retType $genericConstraint {
                let engine = TemplateEngine()
                $initContext
                return engine.render($(newMultilineStringLiteralToken(prefix + template)))
            }
        )
    }
}

private func escapeStringForTemplate(input: String): String {
    // Escape `${` to `\${` to prevent it from being interpreted as a variable in the template engine
    return input.replace("\${", "\\\${")
}

enum TagType {
    | ForStart
    | ForEnd
    | IfStart
    | ElseBlock
    | IfEnd
    | Normal
}

private struct IfElse {
    IfElse(
        let cond: String,
        let ifbody: String,
        let elsebody: String) {
    }
}

private struct Loop {
    Loop(
        let varName: String,
        let arrayExpr: String,
        let body: String) {
    }
}

/**
 * Extract top-level loops/if-else from the string and split the string by these loops
 * Split "...{% for ...%} xxx {% /for %}...{% for ...%} xxx {% /for %}..."
 * Or split "...{% if ...%} xxx {% else ...%} xxx {% /if %}..."
*/
private func split(str: String): (Array<Loop>, Array<IfElse>, Array<String>, Array<TagType>) {
    let loops = ArrayList<Loop>()
    let ifStmts = ArrayList<IfElse>()
    let splitStrings = ArrayList<String>()
    let stmtsSeq = ArrayList<TagType>()

    // Regex to match loops in the format "{for item in <expr>}...{/for}"
    // Or match if-else in the format "{if (cond)}...{else}...{/if}"
    // <expr> allows identifiers, member access, array access, and map access
    let startForRegex = Regex("{%\\s*for\\s+((?:\\(\\s*\\w+\\s*,\\s*\\w+\\s*\\))|(?:\\w+))\\s+in\\s+([\\w\\d\\.\\[\\]\"'\\s\\(\\)]+?)\\s*%}")
    let endForRegex = Regex("{%\\s*/for\\s*%}")
    let startIfRegex = Regex("{%\\s*if\\s+(\\(.*?\\))\\s*%}")
    let elseRegex = Regex("{%\\s*else\\s*%}")
    let endIfRegex = Regex("{%\\s*/if\\s*%}")

    // 收集所有标签的位置信息
    let tagPositions = ArrayList<(Int64, TagType)>()

    // 收集所有 for 标签
    var pos = 0
    while (true) {
        let startMatcher = startForRegex.matcher(str)
        let startMatch = startMatcher.find(pos)
        if (startMatch.isNone()) {
            break
        }
        let matchData = startMatch.getOrThrow()
        let matchPos = matchData.matchPosition()
        tagPositions.add((matchPos.start, ForStart))
        pos = matchPos.end
    }

    pos = 0
    while (true) {
        let endMatcher = endForRegex.matcher(str)
        let endMatch = endMatcher.find(pos)
        if (endMatch.isNone()) {
            break
        }
        let matchData = endMatch.getOrThrow()
        let matchPos = matchData.matchPosition()
        tagPositions.add((matchPos.start, ForEnd))
        pos = matchPos.end
    }

    // 收集所有 if 标签
    pos = 0
    while (true) {
        let startMatcher = startIfRegex.matcher(str)
        let startMatch = startMatcher.find(pos)
        if (startMatch.isNone()) {
            break
        }
        let matchData = startMatch.getOrThrow()
        let matchPos = matchData.matchPosition()
        tagPositions.add((matchPos.start, IfStart))
        pos = matchPos.end
    }

    pos = 0
    while (true) {
        let elseMatcher = elseRegex.matcher(str)
        let elseMatch = elseMatcher.find(pos)
        if (elseMatch.isNone()) {
            break
        }
        let matchData = elseMatch.getOrThrow()
        let matchPos = matchData.matchPosition()
        tagPositions.add((matchPos.start, ElseBlock))
        pos = matchPos.end
    }

    pos = 0
    while (true) {
        let endMatcher = endIfRegex.matcher(str)
        let endMatch = endMatcher.find(pos)
        if (endMatch.isNone()) {
            break
        }
        let matchData = endMatch.getOrThrow()
        let matchPos = matchData.matchPosition()
        tagPositions.add((matchPos.start, IfEnd))
        pos = matchPos.end
    }

    // 按位置排序
    for (i in 0..tagPositions.size) {
        for (j in i+1..tagPositions.size) {
            if (tagPositions[i][0] > tagPositions[j][0]) {
                let temp = tagPositions[i]
                tagPositions[i] = tagPositions[j]
                tagPositions[j] = temp
            }
        }
    }

    var currIndex = 0
    var forDepth = 0
    var ifDepth = 0
    var forStartPos = 0
    var forVarName = ""
    var forArrayExpr = ""
    var ifStartPos = 0
    var ifCond = ""
    var elseStartPos = 0
    var hasElse = false

    for (tagInfo in tagPositions) {
        let (pos, tagType) = tagInfo

        match (tagType) {
            case ForStart =>
                if (forDepth == 0 && ifDepth == 0) {
                    splitStrings.add(str[currIndex..pos])
                    stmtsSeq.add(TagType.Normal)

                    let startMatcher = startForRegex.matcher(str)
                    let startMatch = startMatcher.find(pos)
                    if (startMatch.isSome()) {
                        let matchData = startMatch.getOrThrow()
                        forVarName = matchData.matchString(1)
                        forArrayExpr = matchData.matchString(2)
                        forStartPos = matchData.matchPosition().end
                    }
                }
                forDepth += 1

            case ForEnd =>
                forDepth -= 1
                if (forDepth < 0) {
                    throw DslException("Invalid {% /for %} loop without beginning")
                }
                if (forDepth == 0 && ifDepth == 0) {
                    loops.add(Loop(forVarName, forArrayExpr, str[forStartPos..pos]))
                    stmtsSeq.add(ForEnd)
                    let endMatcher = endForRegex.matcher(str)
                    let endMatch = endMatcher.find(pos)
                    if (endMatch.isSome()) {
                        let matchData = endMatch.getOrThrow()
                        currIndex = matchData.matchPosition().end
                    } else {
                        currIndex = pos
                    }
                }

            case IfStart =>
                if (forDepth == 0 && ifDepth == 0) {
                    splitStrings.add(str[currIndex..pos])
                    stmtsSeq.add(TagType.Normal)

                    let startMatcher = startIfRegex.matcher(str)
                    let startMatch = startMatcher.find(pos)
                    if (startMatch.isSome()) {
                        let matchData = startMatch.getOrThrow()
                        ifCond = matchData.matchString(1)
                        ifStartPos = matchData.matchPosition().end
                    }
                }
                ifDepth += 1

            case ElseBlock =>
                if (ifDepth == 1 && forDepth == 0) {
                    hasElse = true
                    let elseMatcher = elseRegex.matcher(str)
                    let elseMatch = elseMatcher.find(pos)
                    if (elseMatch.isSome()) {
                        let matchData = elseMatch.getOrThrow()
                        elseStartPos = matchData.matchPosition().end
                    } else {
                        elseStartPos = pos
                    }
                }

            case IfEnd =>
                ifDepth -= 1
                if (forDepth == 0 && ifDepth == 0) {
                    let ifBodyEnd = if (hasElse) {
                        elseStartPos - 10
                    } else {
                        pos
                    }
                    let ifBody = str[ifStartPos..ifBodyEnd]
                    let elseBody = if (hasElse) {
                        str[elseStartPos..pos]
                    } else {
                        ""
                    }
                    ifStmts.add(IfElse(ifCond, ifBody, elseBody))
                    stmtsSeq.add(IfEnd)
                    let endMatcher = endIfRegex.matcher(str)
                    let endMatch = endMatcher.find(pos)
                    if (endMatch.isSome()) {
                        let matchData = endMatch.getOrThrow()
                        currIndex = matchData.matchPosition().end
                    } else {
                        currIndex = pos
                    }
                }
                hasElse = false
            case _ => ''
        }
    }

    // 处理剩余的字符串
    if (currIndex < str.size) {
        splitStrings.add(str[currIndex..])
        stmtsSeq.add(TagType.Normal)
    }

    return (loops.toArray(), ifStmts.toArray(), splitStrings.toArray(), stmtsSeq.toArray())
}

class TemplateCompiler {
    private static const ESCAPED_NEWLINE = "#^#"

    public func compile(template: String): Tokens {
        // Since the regex does not support DOTALL, we replace all newlines with a special symbol
        let template2 = template.replace("\n", ESCAPED_NEWLINE)
        return this.compileStmts(template2)
    }

    private func compileStmts(template: String): Tokens {
        let (loops, ifStmts, splitStrings, stmtsSeq) = split(template)
        // Compile loop content and construct the final string
        let tokens = Tokens()
        var loopIndex = 0;
        var ifIndex = 0;
        var normalIndex = 0;
        for (s in stmtsSeq) {
            match(s) {
                case ForEnd =>
                    tokens.append(this.compileLoop(loops[loopIndex]))
                    loopIndex += 1
                case IfEnd =>
                    tokens.append(this.compileIfStmt(ifStmts[ifIndex]))
                    ifIndex += 1
                case Normal =>
                    tokens.append(this.compileExprs(splitStrings[normalIndex]))
                    normalIndex += 1
                case _ => ''
            }
        }
        return tokens
    }

    private func compileLoop(loop: Loop): Tokens {
        let itemVar = newIdentifierToken(loop.varName)
        let array = this.parseExpr(loop.arrayExpr)
        let loopBody = this.compileStmts(loop.body)
        return quote(
            for ($itemVar in $array) {
                $loopBody
            }
        )
    }

    private func compileIfStmt(ifStmt: IfElse): Tokens {
        let cond = this.parseExpr(ifStmt.cond)
        let ifBody = this.compileStmts(ifStmt.ifbody)
        if (ifStmt.elsebody.isEmpty()) {
            return quote (
                if $cond {
                    $ifBody
                }
            )
        } else {
            let elseBody = this.compileStmts(ifStmt.elsebody)
            return quote (
                if $cond {
                    $ifBody
                } else {
                    $elseBody
                }
            )
        }
    }

    private func compileExprs(template: String): Tokens {
        // Regex to match placeholder expressions in the format
        // like "{% expr %}"
        let regex = Regex("{%\\s*(.+?)\\s*%}")
        let matcher = regex.matcher(template)
        // Split "... {expr1}...{expr2}...{exprN}..."
        let subStrings = matcher.split() |>
            map { s => s.replace(ESCAPED_NEWLINE, "\n") } |> // Recover ESCAPED_NEWLINE
            collectArray
        // And find all expressions
        let exprs = match (matcher.findAll()) {
            case Some(mdArray) => mdArray |>
                map { md: MatchData =>
                    this.parseExpr(md.matchString(1).replace(ESCAPED_NEWLINE, "\n"))
                } |>
                collectArray
            case None => Array<Expr>()
        }
        if (subStrings.size != exprs.size + 1) {
            throw DslException("Template format error: the number of variables does not match the number of substrings")
        }
        // Construct the string part by part
        let tokens = Tokens()
        tokens.append(quote(
            sb.append( $(newMultilineStringLiteralToken(subStrings[0])) )
        ))
        for (i in 0..exprs.size) {
            tokens.append(quote(
                sb.append( $(exprs[i]) .toString() )
                sb.append( $(newMultilineStringLiteralToken(subStrings[i+1])) )
            ))
        }
        return tokens
    }

    /**
     * Parse the expression string into an AST expression
     */
    private func parseExpr(str: String): Expr {
        try {
            return parseExpr(cangjieLex(str))
        } catch (ex: IllegalArgumentException) {
            // eprintln("Invalid expression `${str}` in template")
            throw DslException("Invalid expression `${str}` in template")
        } catch (ex: ParseASTException) {
            // eprintln("Failed to parse expression `${str}` in template")
            throw DslException("Failed to parse expression `${str}` in template")
        }
    }
}
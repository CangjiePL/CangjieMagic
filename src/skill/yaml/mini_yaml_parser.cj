/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.skill.yaml

import std.collection.*
import std.regex.Regex
import std.convert.*

/**
Support basic YAML parsing.
- Only support block style. Flow style is not supported
- Only support `: ` as key-value separator, `- ` as list item separator, `#` as comment, and `"` as string delimiter. Other special YAML features are not supported
- You must put a string in one line (use escape when changing lines), unless you use quotes

Example: The following YAML document is invalid for this mini parser (though it is valid YAML):
```yaml
list:
 - item1
    item2
```
The above is actually valid YAML, `{list: ["item1 item2"]}`, but is not valid for our mini parser. 

By contrast, the following two are valid for our mini parser
```yaml
list:
 - "item1
 item2"
```
or
```yaml
list:
 - item1\nitem2
```
Both are `{list: ["item1\nitem2"]}`.
*/
public class MiniYamlParser {
    private let src: String
    private let srcRunes: Array<Rune>
    private var idx: Int
    private var line: Int
    private var col: Int
    private var ahead: ?Token
    private let indentStack: ArrayList<Int>
    private var ignoreColon: Bool = false

    private prop lastIndent: Int { 
        get() {
            if (this.indentStack.size == 0) {
                throw YamlParseException("indent error", this.line, this.col)
            }
            return this.indentStack[this.indentStack.size - 1]
        }
    }

    public init(src: String) {
        this.src = src
        this.srcRunes = src.toRuneArray()
        this.idx = 0
        this.line = 1
        this.col = 1
        this.ahead = None
        this.indentStack = ArrayList<Int>()
        this.next()
    }

    /* --------------- 语法分析入口 --------------- */
    public func parse(): YamlNode {
        let doc = this.parseDocument()
        if (this.ahead.getOrThrow().tokenType != TokenType.Eof) {
            throw YamlParseException("trailing content", this.line, this.col)
        }
        return doc
    }

    private func cur(): Rune {
        if (this.idx < this.srcRunes.size) {
            let chars = this.srcRunes
            return chars[this.idx]
        } else {
            return r'\0'
        }
    }

    private func updateIndentStack() {
        let curLine = src.split("\n")[this.line - 1].trimAscii()
        if (curLine.isEmpty() || curLine.startsWith("#") || this.indentStack.isEmpty()) {
            // ignore a comment or empty line
            return
        }
        let curIndent = getCurIndent()
        if (curIndent == lastIndent) {
            return
        }
        if (curIndent > lastIndent) {
            this.indentStack.add(curIndent)
            return
        }
        while (curIndent < lastIndent) {
            this.indentStack.remove(at: this.indentStack.size - 1)
        }
        if (curIndent != lastIndent) {
            throw YamlParseException("indent error", this.line, this.col)
        }
    }

    private func getCurIndent(): Int {
        let curLine = src.split("\n")[this.line - 1].toRuneArray()
        var rst = 0
        for (ch in curLine) {
            if (ch != r' ') {
                break
            }
            rst += 1
        }
        return rst
    }

    private func advance() {
        if (this.cur() == r'\n') { // '\n'
            this.line += 1
            this.col = 1
            this.updateIndentStack()
        } else {
            this.col += 1
        }
        this.idx += 1
    }

    private func skipLineComment() {
        while (this.cur() != r'\n' && this.idx < this.srcRunes.size) {
            this.advance()
        }
    }

    private func isAtTrimmedLineStart(): Bool {
        let curIndent = getCurIndent()
        return this.idx - curIndent <= 0 || this.srcRunes[this.idx - curIndent - 1] == r'\n'
    }

    /* --------------- 词法分析 --------------- */
    private func next(): Unit {
        while (true) {
            // 跳过所有空格
            while (this.idx < this.srcRunes.size && this.cur() == r' ') {
                this.advance()
            }
            let l = this.line
            let c = this.col

            if (this.cur() == r'\0') {
                this.ahead = Token(TokenType.Eof, "", l, c)
                return
            }
            if (this.cur() == r'\n') {
                this.advance()
                this.ignoreColon = false
                this.ahead = Token(TokenType.Eol, "", l, c)
                return
            }
            // `#` beginning a comment should satisfy: 1. at the beginning of a line; 2. followed by a space or newline
            // Otherwise, it's a char in a string scalar
            if (this.cur() == r'#' && isAtTrimmedLineStart()) {
                this.skipLineComment()
                continue
            }
            // `-` beginning an indicator of a list item should satisfy: 1. at the beginning of a line; 2. followed by a space or newline
            // Otherwise, it's a char in a string scalar
            if (this.cur() == r'-' && isAtTrimmedLineStart() && this.idx < this.srcRunes.size && (this.srcRunes[this.idx + 1] == r' ' || this.srcRunes[this.idx + 1] == r'\n')) {
                this.advance()
                this.ignoreColon = true
                this.ahead = Token(TokenType.Dash, "-", l, c)
                return
            }
            // `:` being a key-value seperator should satisfy: 1. first `:` in a line; 2. not in a list item;  3. followed by a space or newline
            // Otherwise, it's a char in a string scalar
            if (this.cur() == r':' && !this.ignoreColon && this.idx < this.srcRunes.size && (this.srcRunes[this.idx + 1] == r' ' || this.srcRunes[this.idx + 1] == r'\n')) {
                this.advance()
                this.ignoreColon = true
                this.ahead = Token(TokenType.Colon, ":", l, c)
                return
            }
            // `"` treated as string delimiter should satisfy: not escaped
            // Otherwise, it's a char in a string scalar
            if (this.cur() == r'"' && this.idx > 0 && this.srcRunes[this.idx - 1] != r'\\') {
                this.advance()
                var sb = StringBuilder()
                while (this.idx < this.srcRunes.size && !(this.cur() == r'"' && this.srcRunes[this.idx - 1] != r'\\')) {
                    sb.append(this.cur().toString())
                    this.advance()
                }
                if (!(this.cur() == r'"' && this.srcRunes[this.idx - 1] != r'\\')) {
                    throw YamlParseException("unterminated string", this.line, this.col)
                }
                this.advance()
                this.ahead = Token(TokenType.Scalar, unescapeString(sb.toString()), l, c)
                return
            }
            var sb = StringBuilder()
            while (this.idx < this.srcRunes.size && this.cur() != r'\n') {
                if (this.cur() == r':' && !this.ignoreColon) {
                    break
                }
                sb.append(this.cur().toString())
                this.advance()
            }
            this.ahead = Token(TokenType.Scalar, unescapeString(sb.toString()).trimAscii(), l, c)
            return
        }
    }

    private func consume(tokenType: TokenType): Token {
        let token = this.ahead.getOrThrow { => YamlParseException("unexpected eof", this.line, this.col)}
        if (token.tokenType == tokenType) {
            this.next()
            return token
        }
        throw YamlParseException("expected ${tokenType} got ${token.tokenType}", this.line, this.col)
    }


    /* 解析顶层或子文档 */
    private func parseDocument(): YamlNode {
        this.skipEmptyLines()
        if (this.ahead.getOrThrow().tokenType == TokenType.Eof) {
            return YamlNode.None
        }
        this.indentStack.add(getCurIndent())
        return this.parseNode(this.lastIndent)
    }

    /* 跳过空行和注释行 */
    private func skipEmptyLines() {
        while (this.ahead.getOrThrow().tokenType == TokenType.Eol) {
            this.consume(TokenType.Eol)
        }
    }

    /* 递归解析节点：Map / List / Scalar */
    private func parseNode(currentIndent: Int): YamlNode {
        this.skipEmptyLines()
        match (this.ahead.getOrThrow().tokenType) {
            case TokenType.Dash => 
                return this.parseSequence(currentIndent)
            case TokenType.Scalar => 
                let keyTok = this.consume(TokenType.Scalar)
                if (this.ahead.getOrThrow().tokenType == TokenType.Colon) {
                    this.consume(TokenType.Colon)
                    return this.parseMapping(currentIndent, keyTok.raw)
                }
                return this.deserializeScalar(keyTok.raw)
            case TokenType.Eol => 
                this.consume(TokenType.Eol)
                return this.parseNode(currentIndent)
            case TokenType.Eof => 
                return YamlNode.None
            case _ => 
                throw YamlParseException("expected node", this.line, this.col)
        }
    }

    /* 解析映射：第一个 key 已读，继续读同级 key */
    private func parseMapping(baseIndent: Int, firstKey: String): YamlNode {
        let map = HashMap<String, YamlNode>()
        this.putKV(map, firstKey, baseIndent)
        var co = 0
        while (true) {
            this.skipEmptyLines()
            if (this.ahead.getOrThrow().tokenType == TokenType.Eof) {
                break
            }
            if (this.lastIndent < baseIndent) {
                break
            }
            if (this.ahead.getOrThrow().tokenType != TokenType.Scalar) {
                break // 不是同级 key
            }
            let keyTok = this.consume(TokenType.Scalar)
            this.consume(TokenType.Colon)
            this.putKV(map, keyTok.raw, baseIndent)
            co ++ 
        }
        return YamlNode.Map(map)
    }

    /* 解析序列 */
    private func parseSequence(baseIndent: Int): YamlNode {
        var list = ArrayList<YamlNode>()
        while (this.ahead.getOrThrow().tokenType == TokenType.Dash) {
            if (this.lastIndent != baseIndent) {
                throw YamlParseException("indent error", this.line, this.col)
            }
            this.consume(TokenType.Dash)
            list.add(this.parseNode(this.lastIndent))
            this.skipEmptyLines()
        }
        return YamlNode.List(list)
    }

    /* 写一对 key-value */
    private func putKV(map: HashMap<String, YamlNode>, key: String, baseIndent: Int) {
        if (map.contains(key)) {
            throw YamlParseException("duplicate key '${key}'", this.line, this.col)
        }

        var value: YamlNode
        if (this.ahead.getOrThrow().tokenType == TokenType.Eol || this.ahead.getOrThrow().tokenType == TokenType.Eof) {
            this.consume(TokenType.Eol)
            this.skipEmptyLines()
            if (this.lastIndent <= baseIndent) {
                // throw YamlParseException("value required for key '${key}'", this.line, this.col)
                value = YamlNode.None
            }
            value = this.parseNode(this.lastIndent)
        } else {   // 行内值
            value = this.deserializeScalar(this.consume(TokenType.Scalar).raw)
        }
        map[key] = value
    }

    /* 最简单的标量反序列化 */
    private func deserializeScalar(s: String): YamlNode {
        if (s.isEmpty() || s == "null") {
            return YamlNode.None
        }
        if (s == "true") {
            return YamlNode.BoolScalar(true)
        }
        if (s == "false") {
            return YamlNode.BoolScalar(false)
        }
        let regex = Regex("^\\d+$")
        if (regex.matches(s)) {
            return YamlNode.IntScalar(Int.parse(s))
        }
        return YamlNode.StringScalar(s)
    }
    
    // Helper function to unescape strings
    private func unescapeString(escaped: String): String {
        let sb = StringBuilder()
        var i = 0
        let escapedRunes = escaped.toRuneArray()
        while (i < escapedRunes.size) {
            let c = escapedRunes[i]
            if (c == r'\\' && i + 1 < escapedRunes.size) {
                let next = escapedRunes[i + 1]
                match(next) {
                    case r'\\' => 
                        sb.append("\\")
                        i += 2
                    case r'"' =>
                        sb.append('"')
                        i += 2
                    case r'\'' =>
                        sb.append("'")
                        i += 2
                    case r'n' =>
                        sb.append("\n")
                        i += 2
                    case r'r' =>
                        sb.append("\r")
                        i += 2
                    case r't' =>
                        sb.append("\t")
                        i += 2
                    case r'b' =>
                        sb.append("\b")
                        i += 2
                    case r'f' =>
                        sb.append("\f")
                        i += 2
                    case _ =>
                        sb.append(c)
                        i ++
                }
            } else {
                sb.append(c)
                i ++
            }
        } 
        return sb.toString()
    }
}

// Helper function for easy parsing
public func parseYaml(content: String): YamlNode {
    let parser = MiniYamlParser(content)
    return parser.parse()
}

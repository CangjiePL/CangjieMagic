/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.skill.yaml

import std.collection.{ ArrayList, HashMap }

/**
 * Represents a YAML node.
 */
public enum YamlNode <: ToString {
    | None
    | Map(HashMap<String, YamlNode>)
    | List(ArrayList<YamlNode>)
    | BoolScalar(Bool)
    | IntScalar(Int)
    | StringScalar(String)

    public func isNone(): Bool {
        match(this) {
            case YamlNode.None => return true
            case _ => return false
        }
    }

    public func toString(): String {
        match (this) {
            case YamlNode.None => return "null"
            case YamlNode.Map(m) => 
                var sb = StringBuilder()
                sb.append("{")
                var first = true
                for ((k, v) in m) {
                    if (!first) {
                        sb.append(", ")
                    }
                    sb.append("${k}: ${v.toString()}")
                    first = false
                }
                sb.append("}")
                return sb.toString()
            case YamlNode.List(l) => 
                var sb = StringBuilder()
                sb.append("[")
                var first = true
                for (item in l) {
                    if (!first) {
                        sb.append(", ")
                    }
                    sb.append(item.toString())
                    first = false
                }
                sb.append("]")
                return sb.toString()
            case YamlNode.BoolScalar(b) => return b.toString()
            case YamlNode.IntScalar(i) => return i.toString()
            case YamlNode.StringScalar(s) => return "\"${toEscapeString(s)}\""
        }
    }

    public func stringScalarToString(): String { 
        match(this) {
            case StringScalar(s) => return s
            case _ => throw Exception("Yaml node is not a string")
        }
    }
    
    // Helper function to escape special characters in strings
    private func toEscapeString(input: String): String {
        let sb = StringBuilder()
        for (c in input.toRuneArray()) {
            match(c) {
                case r'\\' => sb.append("\\\\")
                case r'\"' => sb.append("\\\"")
                case r'\'' => sb.append("\\'")
                case r'\n' => sb.append("\\n")
                case r'\r' => sb.append("\\r")
                case r'\t' => sb.append("\\t")
                case r'\b' => sb.append("\\b")
                case r'\f' => sb.append("\\f")
                case _ => sb.append(c)
            }
        }
        return sb.toString()
    }
}
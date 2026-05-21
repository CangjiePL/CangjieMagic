/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.skill.yaml

/**
 * Exception thrown during YAML parsing.
 */
public class YamlParseException <: Exception {
    public init(msg: String, line: Int, col: Int) {
        super("${line}:${col}: ${msg}")
    }

    public override func getClassName(): String {
        "YamlParseException"
    }
}
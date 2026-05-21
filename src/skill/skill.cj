/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.skill

import std.fs.File

import std.collection.{HashMap, map, collectArray}
import std.fs.{Path, canonicalize, exists, Directory}
import std.regex.Regex
import std.deriving.Derive

import magic.skill.yaml.{parseYaml, YamlNode, YamlParseException}
import magic.utils.readFile

// Constants for skill validation
private const NAME_MAX_LENGTH = 64
private const DESCRIPTION_MAX_LENGTH = 1024
private const COMPATIBILITY_MAX_LENGTH = 500

// Skill metadata structure
public struct SkillMetadata {
    let name: String
    let description: String
    let license: ?String
    let compatibility: ?String
    let metadata: YamlNode
    let allowedTools: YamlNode

    public init(
        name: String,
        description: String,
        license!: ?String = None,
        compatibility!: ?String = None,
        metadata!: YamlNode = None,
        allowedTools!: YamlNode = None
    ) {
        this.name = name
        this.description = description
        this.license = license
        this.compatibility = compatibility
        this.metadata = metadata
        this.allowedTools = allowedTools
        try {
            this.validateName()
            this.validateDescription()
            this.validateCompatibility()
        } catch (ex: Exception) {
            throw Exception("Invalid SkillMetadata: ${ex.message}")
        }
    }

    private func validateName() {
        if (this.name.size > NAME_MAX_LENGTH) {
            throw Exception(
                "Skill name has ${this.name.size} characters, exceeding the limit of ${NAME_MAX_LENGTH} characters")
        }
        if (this.name.isEmpty()) {
            throw Exception("Skill name cannot be empty")
        }
        if (this.name.startsWith("-")) {
            throw Exception("Skill name cannot start with '-'")
        }
        if (this.name.contains("--")) {
            throw Exception("Skill name cannot contain consecutive hyphens '--'")
        }
    }

    private func validateDescription() {
        if (this.description.size > DESCRIPTION_MAX_LENGTH) {
            throw Exception(
                "Skill description has ${this.description.size} characters, exceeding the limit of ${DESCRIPTION_MAX_LENGTH} characters")
        }
        if (this.description.isEmpty()) {
            throw Exception("Skill description cannot be empty")
        }
    }

    private func validateCompatibility() {
        if (this.compatibility.isNone()) {
            return
        }
        if (this.compatibility.getOrThrow().size > COMPATIBILITY_MAX_LENGTH) {
            throw Exception(
                "Skill compatibility has ${this.compatibility.getOrThrow().size} characters, exceeding the limit of ${COMPATIBILITY_MAX_LENGTH} characters")
        }
    }
}

// Helper function to generate directory structure string
private func generateDirectoryStructure(path: Path, prefix!: String = ""): String {
    let items = try {
        Directory.readFrom(path)
    } catch (e: Exception) {
        return ""
    }
    
    let strBuilder = StringBuilder()
    
    for (i in 0..items.size) {
        let item = items[i]
        let isLast = (i == items.size - 1)
        var itemPrefix: String
        var nextPrefix: String
        
        if (isLast) {
            itemPrefix = "└── "
            nextPrefix = prefix + "    "
        } else {
            itemPrefix = "├── "
            nextPrefix = prefix + "│   "
        }
        
        strBuilder.append("${prefix}${itemPrefix}${item.name}")
        
        if (item.isDirectory()) {
            strBuilder.append("/")
        }
        
        strBuilder.append("\n")
        
        // Only provide the top-level directory contents to reduce the agent context
        // if (item.isDirectory()) {
        //     strBuilder.append(generateDirectoryStructure(path.join(item.name), prefix: nextPrefix))
        // }
    }
    
    return strBuilder.toString()
}

// Skill class
public class Skill <: Hashable & Equatable<Skill> {
    public let name: String
    public let skillRoot: Path
    public let skillMetadata: SkillMetadata
    public let bodyContent: String
    public let directoryStructure: String
    
    public init(skillRoot: Path, name: String) {
        this.skillRoot = canonicalize(skillRoot)
        this.name = name
        let skillPath = skillRoot.join(name)
        
        if (!exists(skillPath)) {
            throw Exception("Skill directory does not exist: ${skillPath.toString()}")
        }
        
        let skillMdPath = skillPath.join("SKILL.md")
        let (skillMetadata, body) = loadSkillMd(skillMdPath)
        
        if (name != skillMetadata.name) {
            throw Exception("Skill directory name ${name} does not match the skill name: ${skillMetadata.name}")
        }
        
        this.skillMetadata = skillMetadata
        this.bodyContent = body
        
        // Generate and store directory structure
        this.directoryStructure = generateDirectoryStructure(skillPath)
    }
    
    public override func hashCode(): Int {
        return name.hashCode()
    }
    
    public operator override func ==(other: Skill): Bool {
        return name == other.name
    }
    
    public operator override func !=(other: Skill): Bool {
        return name != other.name
    }
    
    public static func load(skillRoot: Path, name: String): Skill {
        return Skill(skillRoot, name)
    }
    
    public static func load(skillRoot: String, name: String): Skill {
        return Skill(Path(skillRoot), name)
    }
    
    private static func loadSkillMd(skillMdPath: Path): (SkillMetadata, String) {
        if (!exists(skillMdPath)) {
            throw Exception("Skill metadata file does not exist: ${skillMdPath.toString()}")
        }
        let content = readFile(skillMdPath)
        if (!content.startsWith("---")) {
            throw Exception("Content in SKILL.md is not in the expected format: ${skillMdPath.toString()}")
        }
        let parts = content.split("---")
        if (parts.size < 3) {
            throw Exception("Content in SKILL.md is not in the expected format: ${skillMdPath.toString()}")
        }
        let skillMetadata = try {
            Skill.parseYamlFrontmatter(parts[1])
        } catch (ex: Exception) {
            throw Exception("Failed to parse skill metadata YAML in ${skillMdPath.toString()}: ${ex.message}")
        }
        return (skillMetadata, String.join(parts[2..], delimiter: "---"))
    }

    // Parse YAML frontmatter using the MiniYamlParser
    private static func parseYamlFrontmatter(content: String): SkillMetadata {
        let rst: YamlNode = parseYaml(content)

        var name: ?String = None
        var description: ?String = None
        var license: ?String = None
        var compatibility: ?String = None
        var metadata: YamlNode = None
        var allowedTools: YamlNode = None

        match (rst) {
            case Map(m) => for ((key, value) in m) {
                match (key) {
                    case "name" => name = stringScalarToString(value, "name")
                    case "description" => description = stringScalarToString(value, "description")
                    case "license" => license = stringScalarToString(value, "license")
                    case "compatibility" => compatibility = stringScalarToString(value, "compatibility")
                    case "metadata" => metadata = value
                    case "allowed_tools" => allowedTools = value
                    case _ => continue
                }
            }
            case _ => throw Exception("Skill frontmatter is not in the expected format.")
        }

        if (name.isNone()) {
            throw Exception("Skill metadata must contain the `name` fields.")
        }
        if (description.isNone()) {
            throw Exception("Skill metadata must contain the `description` fields.")
        }
        try {
            return SkillMetadata(name.getOrThrow(), description.getOrThrow(), license: license,
                compatibility: compatibility, metadata: metadata, allowedTools: allowedTools)
        } catch (ex: Exception) {
            throw Exception("Failed to create SkillMetadata: ${ex.message}")
        }
    }

    private static func stringScalarToString(node: YamlNode, nodeName: String): String {
        return try {
            node.stringScalarToString()
        } catch (ex: Exception) {
            throw Exception("Failed to parse `${nodeName}`'value in skill metadata: ${ex.message}")
        }
    }
}
/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.skill

import magic.log.LogUtils
import magic.config.Config

import std.collection.*
import std.fs.*

/**
 * Manages skills in the CangjieMagic framework.
 * Responsible for loading, storing, and providing access to skills.
 */
public class SkillManager {
    private let skillMap: HashMap<String, Skill>
    // TODO: currently only supports loading skills from a single directory
    private let _skillRoot: Path

    public prop skillRoot: Path {
        get() { return this._skillRoot }
    }
    
    public init(skillRoot: Path) {
        this._skillRoot = skillRoot
        this.skillMap = HashMap<String, Skill>()
        this.loadSkills()
    }

    public init(skillRoot: String) {
        this(Path(skillRoot))
    }
    
    /**
     * Loads skills from the specified root directory.
     */
    private func loadSkills() {
        if (!exists(this.skillRoot)) {
            LogUtils.info("Skill root directory does not exist: ${this.skillRoot.toString()}")
            return
        }
        
        let skillFileInfos = try {
            Directory.readFrom(this.skillRoot)
        } catch (e: Exception) {
            LogUtils.error("Failed to read skill root directory: ${e.message}")
            return
        }
        
        let skillNames = skillFileInfos |> map { info: FileInfo => info.name } |> collectArray
        loadSkills(skillNames)
    }
    
    /**
     * Loads specific skills from the specified root directory.
     */
    private func loadSkills(skillNames: Array<String>) {
        var loadedCount = 0
        
        for (skillName in skillNames) {
            let skillPath = this.skillRoot.join(skillName)
            if (!exists(skillPath)) {
                LogUtils.error("Skill directory does not exist: ${skillPath.toString()}")
                continue
            }
            
            try {
                let skill = Skill.load(skillRoot, skillName)
                this.skillMap.add(skillName, skill)
                loadedCount += 1
            } catch (e: Exception) {
                LogUtils.error("Failed to load skill ${skillName}: ${e.message}")
            }
        }
        
        LogUtils.info("Successfully loaded ${loadedCount} of ${skillNames.size} skills")
    }
    
    /**
     * Gets all loaded skills.
     */
    public func getAllSkills(): ArrayList<Skill> {
        return ArrayList<Skill>(this.skillMap.values())
    }
    
    /**
     * Gets a skill by name.
     */
    public func getSkill(name: String): ?Skill {
        return this.skillMap.get(name)
    }
    
    /**
     * Deletes a skill by name.
     * Optionally deletes the skill folder as well.
     */
    public func deleteSkill(name: String, deleteSkillFolder!: Bool = false) {
        let skillOpt = this.skillMap.get(name)
        if (skillOpt.isNone()) {
            LogUtils.info("Skill not found: ${name}")
            return
        }
        
        let skill = skillOpt.getOrThrow()
        if (deleteSkillFolder) {
            let skillPath = skill.skillRoot.join(name)
            try {
                remove(skillPath, recursive: true)
            } catch (e: Exception) {
                LogUtils.error("Failed to delete skill folder ${skillPath.toString()}: ${e.message}")
            }
        }
        
        this.skillMap.remove(name)
        LogUtils.info("Skill deleted: ${name}")
    }
    
    /**
     * Adds a skill to the manager.
     */
    public func addSkill(skill: Skill) {
        // TODO: handling duplicated skills if they are from different locations. Currently just overwriting
        if (this.skillMap.contains(skill.name)) {
            LogUtils.info("Skill with name ${skill.name} already exists. Overwriting.")
        }
        this.skillMap.add(skill.name, skill)
    }
    
    /**
     * Generates an XML string representation of all available skills.
     * This format is suitable for including in system prompts.
     */
    public func toXmlString(): String {
        let targetSkills = this.getAllSkills()
        var prompt = "<available_skills>\n"
        
        for (skill in targetSkills) {
            prompt += "  <skill>\n"
            prompt += "    <name>${skill.name}</name>\n"
            prompt += "    <description>\n"
            prompt += "      ${skill.skillMetadata.description}\n"
            prompt += "    </description>\n"
            prompt += "    <location>${skill.skillRoot}</location>\n"
            
            // Add directory structure with proper indentation
            let indentedStructure = String.join(skill.directoryStructure
                .split("\n")
                .map { line => "      ${line}" },  // Indent each line to match XML structure
                delimiter: "\n")
            prompt += "    <directory_structure>\n"
            prompt += "${indentedStructure}\n"
            prompt += "    </directory_structure>\n"
            
            prompt += "  </skill>\n"
        }
        
        prompt += "</available_skills>\n"
        return prompt
    }
    
    /**
     * Generates a markdown string representation of all available skills.
     */
    public func toMarkdownString(): String {
        let targetSkills = this.getAllSkills()
        var md = "# Available Skills\n\n"
        
        for (skill in targetSkills) {
            md += "## ${skill.name}\n"
            md += "${skill.skillMetadata.description}\n\n"
            if (skill.skillMetadata.license.isSome()) {
                md += "**License:** ${skill.skillMetadata.license.getOrThrow()}\n\n"
            }
            if (skill.skillMetadata.compatibility.isSome()) {
                md += "**Compatibility:** ${skill.skillMetadata.compatibility.getOrThrow()}\n\n"
            }
            
            // Add directory structure in a code block
            if (!skill.directoryStructure.isEmpty()) {
                md += "**Directory Structure:**\n"
                md += "```\n"
                md += skill.directoryStructure
                md += "```\n\n"
            }
            
            md += "---\n\n"
        }
        
        return md
    }
}
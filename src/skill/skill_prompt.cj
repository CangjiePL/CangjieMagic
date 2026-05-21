/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.skill

/**
 * Provides prompt templates for skills functionality.
 */

public struct SkillPrompt {
    /**
     * Generates a prompt section that explains how to use skills.
     */
    public static func getSkillInstructions(skillManager: SkillManager): String {
        let availableSkills = skillManager.toXmlString()
        let skillRoot = skillManager.skillRoot.toString()
        
        return """
# Skill System

<skills_instructions>
When users ask you to perform tasks, check if any of the available skills
below can help complete the task more effectively. Skills provide specialized
capabilities and domain knowledge.

How to use skills:
- Invoke skills using the `runSkill` tool with the skill name only
- The skill's prompt will expand and provide detailed instructions on how to complete the task. Examples:
    - `runSkill(name: "pdf")` - invoke the pdf skill
    - `runSkill(name: "xlsx")` - invoke the xlsx skill
- The detailed instructions may tell you to use or read prepared scripts, resources, or files providing more detailed instructions. These extra resources can be found in `${skillRoot}/<skill_name>`

Important:
- Only use skills listed in <available_skills> below
- Always remember to read those extra scripts, resources, and files, if needed. They could be very helpful
    - They are located in the `${skillRoot}/<skill_name>` folder. **Do not** try to access them from outside the skill folder
- Strictly follow the instructions provided by the skill
    - Strictly follow EVERY detailed instruction in the instruction files in the SKILL folder as well
- Always remember to copy the needed scripts/modules into your working directory to run or import them properly
</skills_instructions>

${availableSkills}
"""
    }
    
    /**
     * Generates a minimal prompt section that just lists available skills.
     */
    public static func getSkillsList(skillManager: SkillManager): String {
        let skills = skillManager.getAllSkills()
        
        if (skills.size == 0) {
            return "No skills available."
        }
        
        var prompt = "Available skills:\n"
        for (skill in skills) {
            prompt += "- ${skill.name}: ${skill.skillMetadata.description}\n"
        }
        
        return prompt
    }
}
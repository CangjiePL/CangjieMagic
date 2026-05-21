## Package skill
- [Package skill](#package-skill)
  - [class Skill](#class-skill)
    - [let bodyContent](#let-bodycontent)
    - [let directoryStructure](#let-directorystructure)
    - [func init](#func-init)
    - [static func load](#static-func-load)
    - [let name](#let-name)
    - [let skillMetadata](#let-skillmetadata)
    - [let skillRoot](#let-skillroot)
  - [struct SkillMetadata](#struct-skillmetadata)
    - [let compatibility](#let-compatibility)
    - [let description](#let-description)
    - [let license](#let-license)
    - [let name](#let-name-1)
  - [class SkillManager](#class-skillmanager)
    - [func addSkill](#func-addskill)
    - [func deleteSkill](#func-deleteskill)
    - [func getAllSkills](#func-getallskills)
    - [func getSkill](#func-getskill)
    - [func init](#func-init-1)
    - [prop skillRoot](#prop-skillroot)
    - [func toMarkdownString](#func-tomarkdownstring)
    - [func toXmlString](#func-toxmlstring)
  - [struct SkillPrompt](#struct-skillprompt)
    - [static func getSkillInstructions](#static-func-getskillinstructions)
    - [static func getSkillsList](#static-func-getskillslist)

`magic.skill` provides the runtime representation of "skills" — self-contained folders
of instructions, scripts, and resources that an Agent can load on demand via the
`runSkill` built-in tool. A skill lives under a *skill root* directory and is
defined by a `SKILL.md` file with YAML frontmatter (`name`, `description`,
optional `license`, `compatibility`, `metadata`, `allowed_tools`) followed by a
markdown body that describes how to use the skill.

Typical layout:

```
<skillRoot>/
  <skill-name>/
    SKILL.md          # YAML frontmatter + markdown body
    scripts/...       # optional helper scripts the skill instructs the agent to use
    data/...          # optional resource files
```

To attach a skill root to an Agent, use the `skillRoot` attribute on `@agent`.
`skillRoot` defaults to `None`; with the default, the skill feature is fully
disabled — no `skillManager` is created, the system prompt is untouched, and
no skill tools (neither `runSkill` nor the file/shell built-ins) are
injected. When `skillRoot` is set, the DSL macro injects the corresponding
`runSkill` tool and (by default) the general-purpose `listDirectory` /
`fileRead` / `globSearch` / `grepSearch` / `shellExecute` built-in tools.
See the `dsl` and `agent_executor.common` package docs for details on these
injected tools.

### class Skill
A loaded skill, parsed from `<skillRoot>/<name>/SKILL.md`.

#### let bodyContent
```
public let bodyContent: String
```
- Description: The markdown body of `SKILL.md` (the content after the YAML
  frontmatter). This is the text returned to the agent when `runSkill` is
  invoked for this skill.

#### let directoryStructure
```
public let directoryStructure: String
```
- Description: A printable tree of the skill folder's top-level entries,
  generated once at load time. Embedded into the system prompt by
  `SkillPrompt.getSkillInstructions` so the model can see what scripts and
  files ship with each skill.

#### func init
```
public init(skillRoot: Path, name: String)
```
- Description: Loads the skill at `<skillRoot>/<name>`. Throws if the
  directory is missing, `SKILL.md` is missing or malformed, or the YAML
  `name` does not match the directory name.
- Parameters:
  - `skillRoot`: `Path`, the directory that contains one folder per skill.
  - `name`: `String`, the folder name (and `name:` field) of the skill.

#### static func load
```
public static func load(skillRoot: Path, name: String): Skill
public static func load(skillRoot: String, name: String): Skill
```
- Description: Convenience wrapper around `init`. Returns the loaded skill.

#### let name
```
public let name: String
```
- Description: The skill's name (matches both the folder name and the
  `name:` field in `SKILL.md`).

#### let skillMetadata
```
public let skillMetadata: SkillMetadata
```
- Description: Parsed frontmatter for the skill.

#### let skillRoot
```
public let skillRoot: Path
```
- Description: The canonical path of the skill root directory (the parent
  of the skill folder).

### struct SkillMetadata
Parsed YAML frontmatter from `SKILL.md`. Constructed by `Skill.load`; users do
not normally build this directly.

Validation rules enforced in `init`:
- `name` is required, non-empty, must not start with `-`, must not contain
  `--`, and is capped at 64 characters.
- `description` is required, non-empty, and capped at 1024 characters.
- `compatibility`, when present, is capped at 500 characters.

#### let compatibility
```
public let compatibility: ?String
```
- Description: Optional free-form compatibility note from the frontmatter.

#### let description
```
public let description: String
```
- Description: Short summary of when this skill applies. Surfaced to the
  agent in the system prompt so it can decide whether to call `runSkill`.

#### let license
```
public let license: ?String
```
- Description: Optional license identifier from the frontmatter.

#### let name
```
public let name: String
```
- Description: The skill's name from the frontmatter.

### class SkillManager
Loads every skill under a skill root directory and exposes lookup, listing,
and prompt-rendering helpers.

#### func addSkill
```
public func addSkill(skill: Skill): Unit
```
- Description: Adds a skill to the manager. If a skill with the same name
  already exists it is overwritten.
- Parameters:
  - `skill`: `Skill`, the skill to register.

#### func deleteSkill
```
public func deleteSkill(name: String, deleteSkillFolder!: Bool = false): Unit
```
- Description: Removes a skill from the manager. When `deleteSkillFolder` is
  `true`, the skill's folder on disk is removed as well.
- Parameters:
  - `name`: `String`, the skill name to remove.
  - `deleteSkillFolder`: `Bool`, whether to also delete the on-disk folder.

#### func getAllSkills
```
public func getAllSkills(): ArrayList<Skill>
```
- Description: Returns every currently loaded skill.

#### func getSkill
```
public func getSkill(name: String): ?Skill
```
- Description: Looks up a skill by name. Returns `None` if no such skill is
  registered.
- Parameters:
  - `name`: `String`, the skill name.

#### func init
```
public init(skillRoot: Path)
public init(skillRoot: String)
```
- Description: Creates a manager and immediately loads every direct
  subdirectory of `skillRoot` as a skill. Skills that fail to load are
  logged and skipped rather than throwing.
- Parameters:
  - `skillRoot`: the directory that contains one folder per skill.

#### prop skillRoot
```
public prop skillRoot: Path
```
- Description: The root directory the manager was constructed from.

#### func toMarkdownString
```
public func toMarkdownString(): String
```
- Description: Renders the loaded skills as a markdown document, one
  section per skill, including license, compatibility, and the directory
  structure.

#### func toXmlString
```
public func toXmlString(): String
```
- Description: Renders the loaded skills as an `<available_skills>` XML
  block listing each skill's name, description, location, and directory
  structure. This is the format embedded into the system prompt.

### struct SkillPrompt
Static helpers that turn a `SkillManager` into prompt text.

#### static func getSkillInstructions
```
public static func getSkillInstructions(skillManager: SkillManager): String
```
- Description: Builds the full Skill System prompt block — usage rules plus
  the `<available_skills>` listing. The `@agent` macro automatically
  appends this to the system prompt when `skillRoot` is set.
- Parameters:
  - `skillManager`: `SkillManager`, the manager whose skills should be
    advertised.

#### static func getSkillsList
```
public static func getSkillsList(skillManager: SkillManager): String
```
- Description: Renders a minimal `- name: description` list of available
  skills, suitable for embedding into custom prompts.
- Parameters:
  - `skillManager`: `SkillManager`, the manager whose skills should be
    listed.

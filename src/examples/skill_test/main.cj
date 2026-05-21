/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 *
 * Unified test for the skill module: tool-manager composition, name-collision
 * resolution, direct (offline) invocation of every built-in tool, and an
 * end-to-end LLM workflow that exercises runSkill -> shellExecute / listDirectory
 * / fileRead.
 *
 * The LLM section is skipped automatically when the provider's API key env var
 * is not set, so this can be run as an offline smoke test by default.
 *
 *   Offline only:   cjpm run --name magic.examples.skill_test
 *   With LLM:       set ARK_API_KEY (and optionally MODEL), then run the same.
 *
 * MODEL defaults to "ark:deepseek-v3-2-251201" and is env-overridable.
 */
package magic.examples.skill_test

import magic.dsl.*
import magic.prelude.*
import magic.config.Config
import magic.utils.{exists, canonicalize}

import std.collection.{ArrayList, HashMap}
import std.fs.{Directory, File, Path, remove}
import stdx.encoding.json.{JsonValue, JsonString, JsonInt}

//---------------------------------------------------------------------
// Configuration
//---------------------------------------------------------------------

private let TEST_DIR_NAME = "./test-skill-tmp"
private const MARKER = "MARKER-XYZ-12345"
private const SECRET = "hyacinth-orchid-poppy"

// Env-overridable model for the end-to-end section.
// Provider-specific base URL and API key are read by ModelManager from
// the corresponding env vars (e.g. ARK_BASE_URL / ARK_API_KEY).
private let MODEL_NAME = Config.env["MODEL"] ?? "ark:deepseek-v3-2-251201"

//---------------------------------------------------------------------
// Test agents (compile-time @agent macro expansion)
//---------------------------------------------------------------------

@agent[
    model: "deepseek:deepseek-chat",   // unused: composition tests don't call chat
    skillRoot: "./test-skill-tmp"
]
class DefaultAgent {
    @prompt("test")
}

@agent[
    model: "deepseek:deepseek-chat",
    skillRoot: "./test-skill-tmp",
    skillBuiltinTools: false
]
class NoBuiltinsAgent {
    @prompt("test")
}

// skillBuiltinTools accepts a runtime Bool expression, not just a literal.
// Here it reads a global flag computed at runtime (set to false below).
let RUNTIME_BUILTIN_FLAG = false

@agent[
    model: "deepseek:deepseek-chat",
    skillRoot: "./test-skill-tmp",
    skillBuiltinTools: RUNTIME_BUILTIN_FLAG
]
class ExprSwitchAgent {
    @prompt("test")
}

// skillRoot accepts a runtime expression, not just a string literal.
// Here it reads a global path computed at runtime.
let RUNTIME_SKILL_ROOT = "./test-skill-tmp"

@agent[
    model: "deepseek:deepseek-chat",
    skillRoot: RUNTIME_SKILL_ROOT
]
class ExprSkillRootAgent {
    @prompt("test")
}

// User-supplied tool with the same name as a built-in.
// Used by the collision test to verify the user's tool wins (built-ins are
// added first to the tool manager, then user tools overwrite by name).
@tool[
    description: "User-defined fileRead that always returns the same sentinel",
    parameters: { filePath: "ignored" }
]
private func fileRead(filePath: String): String {
    return "USER_FILE_READ_SENTINEL"
}

@agent[
    model: "deepseek:deepseek-chat",
    skillRoot: "./test-skill-tmp",
    tools: [ fileRead ]
]
class CollidingAgent {
    @prompt("test")
}

@agent[
    model: ModelManager.createChatModel(MODEL_NAME),
    executor: "tool-loop",
    skillRoot: "./test-skill-tmp"
]
class SkillE2EAgent {
    @prompt("""
    You are a careful test runner. Use the available skills when the user asks you to.
    Follow skill instructions exactly. When you finish, return only the requested values.
    """)
}

//---------------------------------------------------------------------
// Helpers
//---------------------------------------------------------------------

var failures = 0

private func check(name: String, ok: Bool, detail!: String = "") {
    if (ok) {
        println("  PASS: ${name}")
    } else {
        failures += 1
        println("  FAIL: ${name}${if (detail.isEmpty()) { "" } else { " — ${detail}" }}")
    }
}

private func setupTestDir(): Path {
    let testDir = Path(TEST_DIR_NAME)
    if (exists(testDir)) {
        try { remove(testDir, recursive: true) } catch (_: Exception) {}
    }
    let skillDir = testDir.join("system-info")
    let dataDir = skillDir.join("data")
    let scriptsDir = skillDir.join("scripts")
    Directory.create(dataDir, recursive: true)
    Directory.create(scriptsDir, recursive: true)

    let skillMd =
"""
---
name: system-info
description: Report basic system status. Use this whenever the user asks about system info, status, or the data folder.
---
# system-info Skill

Follow these steps in order using the available tools, then combine the
results into one concise final answer.

1. Use the `shellExecute` tool with command `echo ${MARKER}` and remember
   the stdout.
2. Use `listDirectory` on the `data/` subdirectory under the Base Path
   shown above. (Build the absolute path by joining Base Path + `/data`.)
3. Use `fileRead` to read `data/info.txt` under the Base Path.
4. Final answer must include:
   - The exact stdout string from step 1.
   - The names of the files in `data/`.
   - The full content of `info.txt`.
"""
    File.writeTo(skillDir.join("SKILL.md"), skillMd.toArray())
    File.writeTo(skillDir.join("README.md"), "# README\nA readme file.\nFinal line.\n".toArray())
    File.writeTo(dataDir.join("info.txt"), "secret-content: ${SECRET}".toArray())
    File.writeTo(dataDir.join("extra.txt"), "another file".toArray())
    File.writeTo(scriptsDir.join("hello.py"), "print('hello')\nprint('world')\n".toArray())
    File.writeTo(scriptsDir.join("util.sh"), "#!/bin/sh\necho UTIL\n".toArray())

    return testDir
}

private func cleanupTestDir(testDir: Path) {
    if (exists(testDir)) {
        try { remove(testDir, recursive: true) } catch (_: Exception) {}
    }
}

private func invokeTool(tool: Tool, args: Array<(String, JsonValue)>): String {
    let argMap = HashMap<String, JsonValue>()
    for ((k, v) in args) {
        argMap.add(k, v)
    }
    return tool.invoke(argMap).content
}

private func collectToolNames(agent: Agent): Array<String> {
    let names = ArrayList<String>()
    for (tool in agent.toolManager.tools) {
        names.add(tool.name)
    }
    names.sortBy(comparator: { a: String, b: String => a.compare(b) })
    return names.toArray()
}

private func equalsArr(a: Array<String>, b: Array<String>): Bool {
    if (a.size != b.size) { return false }
    for (i in 0..a.size) {
        if (a[i] != b[i]) { return false }
    }
    return true
}

//---------------------------------------------------------------------
// Sections
//---------------------------------------------------------------------

private func sectionComposition() {
    println("\n=== A. Tool-manager composition ===")

    println("\n[A.1] DefaultAgent — all 6 tools present")
    let names1 = collectToolNames(DefaultAgent())
    let expected1 = ["fileRead", "globSearch", "grepSearch", "listDirectory", "runSkill", "shellExecute"]
    check("default agent tool set", equalsArr(names1, expected1),
          detail: "got ${names1}, expected ${expected1}")

    println("\n[A.2] NoBuiltinsAgent — only runSkill (literal false)")
    let names2 = collectToolNames(NoBuiltinsAgent())
    check("disabled agent tool set", equalsArr(names2, ["runSkill"]),
          detail: "got ${names2}")

    println("\n[A.2b] ExprSwitchAgent — skillBuiltinTools from a runtime expression (false)")
    let names2b = collectToolNames(ExprSwitchAgent())
    check("expression switch honored", equalsArr(names2b, ["runSkill"]),
          detail: "got ${names2b}")

    println("\n[A.2c] ExprSkillRootAgent — skillRoot from a runtime expression")
    let names2c = collectToolNames(ExprSkillRootAgent())
    check("expression skillRoot loads full tool set", equalsArr(names2c, expected1),
          detail: "got ${names2c}, expected ${expected1}")

    println("\n[A.3] CollidingAgent — user's fileRead overrides built-in")
    let collidingAgent = CollidingAgent()
    let names3 = collectToolNames(collidingAgent)
    check("tool set size unchanged", names3.size == 6,
          detail: "expected 6 distinct tool names, got ${names3.size}: ${names3}")
    let foundFileRead = collidingAgent.toolManager.findTool("fileRead")
    let isUserTool = match (foundFileRead) {
        case Some(t) =>
            let argMap = HashMap<String, JsonValue>()
            argMap.add("filePath", JsonString("/anything"))
            t.invoke(argMap).content == "USER_FILE_READ_SENTINEL"
        case None => false
    }
    check("user's fileRead wins collision", isUserTool,
          detail: "expected USER_FILE_READ_SENTINEL when invoking 'fileRead'")
}

private func sectionDirectInvocation(canonRoot: Path, skillDirCanon: String, readmeAbs: String) {
    println("\n=== B. Direct tool invocation ===")

    //--- listDirectory ---
    println("\n[B.1] listDirectory")
    let listTool = ListDirectoryTool()

    let r1a = invokeTool(listTool, [("path", JsonString(skillDirCanon))])
    check("lists README.md", r1a.contains("README.md"))
    check("lists data/ as dir", r1a.contains("data/"))
    check("lists scripts/ as dir", r1a.contains("scripts/"))
    check("lists SKILL.md", r1a.contains("SKILL.md"))

    let r1b = invokeTool(listTool, [("path", JsonString("./relative-path"))])
    check("rejects relative path", r1b.startsWith("Error:"))

    let r1c = invokeTool(listTool, [("path", JsonString("${skillDirCanon}/does-not-exist"))])
    check("error on missing dir", r1c.startsWith("Error:"))

    //--- fileRead ---
    println("\n[B.2] fileRead")
    let readTool = FileReadTool()

    let r2a = invokeTool(readTool, [("filePath", JsonString(readmeAbs))])
    check("returns full content", r2a.contains("# README") && r2a.contains("A readme file.") && r2a.contains("Final line."))
    check("wraps in <file-content>", r2a.contains("<file-content") && r2a.contains("</file-content>"))

    let r2b = invokeTool(readTool, [
        ("filePath", JsonString(readmeAbs)),
        ("startLine", JsonInt(2)),
        ("endLine", JsonInt(2))
    ])
    check("respects line range", r2b.contains("A readme file.") && !r2b.contains("# README") && !r2b.contains("Final line."))

    let r2c = invokeTool(readTool, [("filePath", JsonString("./relative.md"))])
    check("rejects relative path", r2c.startsWith("Error:"))

    let r2d = invokeTool(readTool, [
        ("filePath", JsonString(readmeAbs)),
        ("startLine", JsonInt(5)),
        ("endLine", JsonInt(2))
    ])
    check("rejects endLine < startLine", r2d.startsWith("Error:"))

    //--- globSearch ---
    println("\n[B.3] globSearch")
    let globTool = GlobSearchTool()

    let r3a = invokeTool(globTool, [
        ("pattern", JsonString("*.py")),
        ("path", JsonString(canonRoot.toString()))
    ])
    check("finds *.py recursively", r3a.contains("hello.py"))

    let r3b = invokeTool(globTool, [
        ("pattern", JsonString("**/*.md")),
        ("path", JsonString(canonRoot.toString()))
    ])
    check("**/*.md finds README.md", r3b.contains("README.md"))
    check("**/*.md finds SKILL.md", r3b.contains("SKILL.md"))

    let r3c = invokeTool(globTool, [
        ("pattern", JsonString("*.no-such-ext")),
        ("path", JsonString(canonRoot.toString()))
    ])
    check("empty result message", r3c.contains("No files matching"))

    //--- grepSearch ---
    println("\n[B.4] grepSearch")
    let grepTool = GrepSearchTool()

    let r4a = invokeTool(grepTool, [
        ("pattern", JsonString("hello")),
        ("path", JsonString(canonRoot.toString()))
    ])
    check("matches 'hello' in hello.py", r4a.contains("hello.py"))

    let r4b = invokeTool(grepTool, [
        ("pattern", JsonString("readme file")),
        ("path", JsonString(canonRoot.toString())),
        ("fileType", JsonString("*.md"))
    ])
    check("matches with fileType filter", r4b.contains("README.md"))

    let r4c = invokeTool(grepTool, [
        ("pattern", JsonString("zzz-no-such-string-zzz")),
        ("path", JsonString(canonRoot.toString()))
    ])
    check("empty result message", r4c.contains("No matches"))

    //--- shellExecute ---
    println("\n[B.5] shellExecute")
    let shellTool = ShellExecuteTool()

    let r5a = invokeTool(shellTool, [
        ("command", JsonString("echo hello-from-shell"))
    ])
    check("echoes string", r5a.contains("hello-from-shell"))
    check("contains Exit:", r5a.contains("Exit:"))

    let r5b = invokeTool(shellTool, [
        ("command", JsonString("echo wd-test")),
        ("workDir", JsonString(canonRoot.toString()))
    ])
    check("workDir accepted", r5b.contains("wd-test"))

    let r5c = invokeTool(shellTool, [
        ("command", JsonString("echo x")),
        ("workDir", JsonString("./relative-workdir"))
    ])
    check("relative workDir rejected", r5c.startsWith("Error:"))
}

/**
 * Verify the status messages SkillToolsBuilder emits to the log.
 * The macro wires `logSkillToolStatus` into every @agent[skillRoot: ...]
 * tool-manager init; here we call the pure `computeSkillToolStatus`
 * helper directly so we can assert on the strings instead of having to
 * capture log output.
 */
private func sectionStatusMessages() {
    println("\n=== C. Status messages emitted to the log ===")

    println("\n[C.1] DefaultAgent — built-ins enabled, no overrides")
    let s1 = SkillToolsBuilder.computeSkillToolStatus(DefaultAgent().toolManager, true)
    for (m in s1) { println("  status: ${m}") }
    check("emits exactly one status line", s1.size == 1, detail: "got ${s1.size}: ${s1}")
    check("line says 'enabled'", s1.size == 1 && s1[0].contains("enabled"))

    println("\n[C.2] NoBuiltinsAgent — built-ins disabled")
    let s2 = SkillToolsBuilder.computeSkillToolStatus(NoBuiltinsAgent().toolManager, false)
    for (m in s2) { println("  status: ${m}") }
    check("emits exactly one status line", s2.size == 1, detail: "got ${s2.size}: ${s2}")
    check("line says 'disabled'", s2.size == 1 && s2[0].contains("disabled"))
    check("line names the switch", s2.size == 1 && s2[0].contains("skillBuiltinTools"))

    println("\n[C.3] CollidingAgent — built-ins enabled but fileRead overridden")
    let s3 = SkillToolsBuilder.computeSkillToolStatus(CollidingAgent().toolManager, true)
    for (m in s3) { println("  status: ${m}") }
    check("emits two status lines", s3.size == 2, detail: "got ${s3.size}: ${s3}")
    check("first line says 'enabled'", s3.size >= 1 && s3[0].contains("enabled"))
    check("second line flags override", s3.size >= 2 && s3[1].contains("overridden") && s3[1].contains("fileRead"))
}

private func sectionEndToEnd() {
    println("\n=== D. End-to-end LLM workflow ===")

    let provider = MODEL_NAME.split(":")[0]
    let apiKeyEnvVar = "${provider.toAsciiUpper()}_API_KEY"
    if (Config.env[apiKeyEnvVar].isNone()) {
        println("  SKIP: ${apiKeyEnvVar} not set in environment.")
        println("  To run the LLM-driven test, set ${apiKeyEnvVar} (and optionally MODEL).")
        return
    }

    println("  Model: ${MODEL_NAME}")
    let question = "Please report the system info as instructed by the system-info skill."
    println("  Question: ${question}")

    let response = try {
        SkillE2EAgent().chat(question)
    } catch (e: Exception) {
        check("agent.chat did not throw", false, detail: "${e}")
        return
    }
    println("  Answer: ${response}")

    check("response contains shellExecute marker", response.contains(MARKER))
    check("response contains listDirectory output", response.contains("info.txt") && response.contains("extra.txt"))
    check("response contains fileRead content", response.contains(SECRET))
}

//---------------------------------------------------------------------
// Main
//---------------------------------------------------------------------

main(): Int64 {
    Config.logLevel = "ERROR"
    println("=== Skill Module Tests ===")

    let testDir = setupTestDir()
    let canonRoot = canonicalize(testDir)
    let skillDirCanon = canonicalize(testDir.join("system-info")).toString()
    let readmeAbs = canonicalize(testDir.join("system-info").join("README.md")).toString()
    println("Test root: ${canonRoot}")

    sectionComposition()
    sectionDirectInvocation(canonRoot, skillDirCanon, readmeAbs)
    sectionStatusMessages()
    sectionEndToEnd()

    cleanupTestDir(testDir)

    println("\n=== Done. Failures: ${failures} ===")
    return if (failures == 0) { 0 } else { 1 }
}

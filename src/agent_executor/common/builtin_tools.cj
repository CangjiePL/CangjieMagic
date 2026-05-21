/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.agent_executor.common

import magic.core.agent.Agent
import magic.core.tool.{Tool, ToolException, ToolManager}
import magic.tool.NativeFuncTool
import magic.jsonable.TypeSchema
import magic.log.LogUtils
import magic.skill.SkillManager
import magic.utils.{newProcess, canonicalize, exists, readFile}

import std.collection.{ArrayList, HashMap, HashSet}
import std.fs.{Path, Directory, File, OpenMode}
import std.io.{StringReader, InputStream}
import std.regex.Regex
@When[cjc_version < "1.0.0"]
import std.time.Duration
import stdx.encoding.json.{JsonObject, JsonValue, JsonKind}

/**
* This tool is used to provide the final answer after all steps are completed
* There is an internal **trick** that we can inject our answer tool with the same name
*/
protected class AnswerTool <: NativeFuncTool {
    protected static let NAME = "_answer_"

    protected static let DESC = """
    This is a special tool that can only be used after you complete all the steps and resolve the task.
    You use this tool to provide the user with the final answer.
    If you interact with them using this tool without finishing the task, the user will get upset.
    """

    init() {
        super(
            name: AnswerTool.NAME,
            description: AnswerTool.DESC,
            parameters: [
                ("result", "The final result", TypeSchema.Str, true)
            ],
            extra: HashMap([
                ("filterable", "false"),
                ("terminal", "true"),
                ("compactable", "false")
            ]),
            execFn: { args: HashMap<String, JsonValue> =>
                // The result is the final answer
                return args.get("result")
                    .getOrThrow({ => ToolException("Parameter `result` is required by the answer tool") })
                    .asString()
                    .getValue()
            }
        )
    }
}

protected class AnswerToolWithOutput <: NativeFuncTool {
    protected static let PARAM_DESC = """
    The argument is a JSON value representing the final answer.
    You MUST obey the the argument schema.
    """

    init (schema: TypeSchema) {
        super (
            name: AnswerTool.NAME,
            description: AnswerTool.DESC,
            parameters: [
                ("result", AnswerToolWithOutput.PARAM_DESC, schema, true)
            ],
            extra: HashMap([
                ("filterable", "false"),
                ("terminal", "true"),
                ("compactable", "false")
            ]),
            execFn: { args: HashMap<String, JsonValue> =>
                // The result is the final answer
                return args.get("result")
                    .getOrThrow({ => ToolException("Parameter `result` is required by the answer tool") })
                    .toJsonString()
            }
        )
    }
}

//--------------------------------------------------------------------------------

/**
* This tool is used to provide the final answer after all steps are completed
* There is an internal **trick** that we can inject our answer tool with the same name
*/
protected class ToolResultViewerTool <: NativeFuncTool  {
    protected static let NAME = "_tool_result_viewer_"

    protected static let PARAM = "tool_result_id"

    init(cache: ToolResultCache) {
        super(
            name: ToolResultViewerTool.NAME,
            description: "This tool is used to query \"detailed results of past tool invocations\". Note that only summarized tool invocation results can be queried. Each summarized tool invocation has a unique ID, so ensure the correct ID is provided.",
            parameters: [
                (ToolResultViewerTool.PARAM, "Unique id of the summarized tool invocation", TypeSchema.Int, true)
            ],
            extra: HashMap([
                ("filterable", "false"),
                ("terminal", "false"),
                ("compactable", "false")
            ]),
            execFn: { args: HashMap<String, JsonValue> =>
                // The result is the final answer
                let id = args.get(ToolResultViewerTool.PARAM)
                    .getOrThrow({ => ToolException("Argument `${ToolResultViewerTool.PARAM}` is missing") })
                    .asInt()
                    .getValue()
                if (let Some(result) <- cache.getOriginalResult(id)) {
                    return result
                } else {
                    let msg = "Tool result with id `${id}` not found in the cache"
                    LogUtils.error("ToolResultViewer", msg)
                    return msg
                }
            }
        )
    }
}

//--------------------------------------------------------------------------------

protected class RetrieverTool <: NativeFuncTool {
    protected static let NAME = "_retriever_tool_"

    // private let task: AgentTask
    init(task: AgentTask) {
        super(
            name: RetrieverTool.NAME,
            description: "Search related knowledge and context",
            parameters: [
                ("query", "The query to search", TypeSchema.Str, true)
            ],
            extra: HashMap([
                ("filterable", "true"),
                ("terminal", "false"),
                ("compactable", "true")
            ]),
            execFn: { args: HashMap<String, JsonValue> =>
                let query = args["query"].asString().getValue()
                let retrieval = task.agent.retriever.getOrThrow().search(query)
                task.execution.addRetrieval(query, retrieval)
                return retrieval.toPrompt()
            }
        )
    }
}

//--------------------------------------------------------------------------------

protected struct BuiltinToolUtils {
   protected static func buildAnswerTool(schema: Option<TypeSchema>): NativeFuncTool {
        if (let Some(schema) <- schema) {
            return AnswerToolWithOutput(schema)
        } else {
            return AnswerTool()
        }
    }

    static func buildToolResultViewerTool(cache: ToolResultCache): NativeFuncTool {
        ToolResultViewerTool(cache)
    }

    static func buildRetrieverTool(task: AgentTask): NativeFuncTool {
        RetrieverTool(task)
    }
}

//------------------------------------------------------------------------------------
private class SkillToolExecutor {
    private let skillManager: SkillManager
    
    public init(skillManager: SkillManager) {
        this.skillManager = skillManager
    }

    public func execRunSkill(args: HashMap<String, JsonValue>): String {
        // Extract skill name from arguments
        let name = args.get("name")
                        .getOrThrow { ToolException("Missing required parameter: name") }
                        .asString()
                        .getValue()
        
        // Find the skill
        let skillOpt = skillManager.getSkill(name)
        if (skillOpt.isNone()) {
            return "Error: No skill found with name `${name}`."
        }
        let skill = skillOpt.getOrThrow()

        // Return the skill content to be added to the context
        let skillPath = skill.skillRoot.join(name).toString()
        return "The `${name}` skill is now fully loaded.\nBase Path: ${skillPath}\n\n${skill.bodyContent}"
    }
}

/**
 * A tool that allows agents to load and use specialized skills.
 */
public class SkillTool <: NativeFuncTool {
    private let skillManager: SkillManager

    public init(skillManager: SkillManager) {
        super(
            name: "runSkill",
            description: "Loads the detailed description of the given skill and makes it available for use.",
            parameters: [
                ("name", "The name of the skill to load and run.", TypeSchema.Str, true)
            ],
            examples: [
                "runSkill(name: \"pdf\")",
                "runSkill(name: \"xlsx\")"
            ],
            execFn: Some(SkillToolExecutor(skillManager).execRunSkill)
        )
        this.skillManager = skillManager
    }
}

//====================================================================================
// Skill built-in tools: general-purpose file/shell tools auto-injected by @agent
// when `skillRoot` is set. Governed by `skillBuiltinTools: Bool` (default true).
// See .claude/skill-tools-design.md
//====================================================================================

private const MAX_GLOB_RESULTS: Int64 = 100
private const MAX_GREP_RESULTS: Int64 = 100
private const MAX_GREP_FILE_BYTES: Int64 = 5_000_000  // 5 MB cap per file to keep memory bounded
private const BINARY_SNIFF_BYTES: Int64 = 4096        // bytes of a file to scan for NUL before grepping
private const SHELL_OUTPUT_TRUNCATE: Int64 = 30_000
private const DEFAULT_SHELL_TIMEOUT_MS: Int64 = 180_000
private const MAX_SHELL_TIMEOUT_MS: Int64 = 600_000

@When[os == "Windows"]
private const SHELL_CMD = "powershell"
@When[os == "Windows"]
private let SHELL_ARGS_PREFIX: Array<String> = ["-NoProfile", "-Command"]

@When[os != "Windows"]
private const SHELL_CMD = "/bin/sh"
@When[os != "Windows"]
private let SHELL_ARGS_PREFIX: Array<String> = ["-c"]

private let SKIP_DIRS = HashSet<String>([".git", "node_modules", "target", "build", "dist", ".cache"])

//------------------------------------------------------------------------------------
// Path / argument helpers
//------------------------------------------------------------------------------------

private func validateAbsolutePath(rawPath: String): Option<String> {
    if (rawPath.isEmpty()) {
        return Some("Error: path must not be empty")
    }
    if (!Path(rawPath).isAbsolute()) {
        return Some("Error: path must be absolute, got '${rawPath}'")
    }
    return None
}

/**
 * Canonicalize a path; if the OS call throws (e.g., path doesn't exist),
 * return the raw path unchanged.
 */
private func canonicalizeOrSame(rawPath: String): Path {
    try {
        return canonicalize(Path(rawPath))
    } catch (_: Exception) {
        return Path(rawPath)
    }
}

private func getStringArg(args: HashMap<String, JsonValue>, key: String): Option<String> {
    if (let Some(jv) <- args.get(key)) {
        match (jv.kind()) {
            case JsonKind.JsString =>
                let s = jv.asString().getValue()
                if (s.isEmpty()) { return None }
                return Some(s)
            case _ => return None
        }
    }
    return None
}

private func getIntArg(args: HashMap<String, JsonValue>, key: String, default!: Int64): Int64 {
    if (let Some(jv) <- args.get(key)) {
        match (jv.kind()) {
            case JsonKind.JsInt =>
                try { return jv.asInt().getValue() } catch (_: Exception) { return default }
            case _ => return default
        }
    }
    return default
}

/**
 * Truncate a UTF-8 string to at most `limit` bytes without splitting a code point.
 * If the truncation point falls inside a multi-byte sequence, walk back to the
 * start of that code point so the result remains valid UTF-8.
 */
private func truncate(s: String, limit: Int64): String {
    if (Int64(s.size) <= limit) {
        return s
    }
    let bytes = s.toArray()
    // Walk back to the last byte that is not a UTF-8 continuation byte (10xxxxxx).
    var cut = limit
    while (cut > 0 && (bytes[cut] & 0xc0u8) == 0x80u8) {
        cut -= 1
    }
    return s[0..cut] + "\n[Truncated: ${Int64(s.size) - cut} more bytes omitted]"
}

/**
 * Convert a glob pattern to an anchored regex string.
 * `**` matches any chars including '/'; `*` matches any chars except path separators;
 * `?` matches one char except a path separator.
 */
private func globToRegex(pattern: String): String {
    let sb = StringBuilder()
    sb.append("^")
    let runes = pattern.toRuneArray()
    var i = 0
    while (i < runes.size) {
        let c = runes[i]
        if (c == r'*') {
            if (i + 1 < runes.size && runes[i + 1] == r'*') {
                sb.append(".*")
                i += 2
                continue
            }
            sb.append("[^/\\\\]*")
        } else if (c == r'?') {
            sb.append("[^/\\\\]")
        } else if (c == r'.' || c == r'(' || c == r')' || c == r'+' ||
                   c == r'^' || c == r'$' || c == r'[' || c == r']' ||
                   c == r'{' || c == r'}' || c == r'|') {
            sb.append("\\")
            sb.append(c.toString())
        } else if (c == r'\\') {
            sb.append("\\\\")
        } else {
            sb.append(c.toString())
        }
        i += 1
    }
    sb.append("$")
    return sb.toString()
}

//------------------------------------------------------------------------------------
// listDirectory
//------------------------------------------------------------------------------------

public class ListDirectoryTool <: NativeFuncTool {
    public static let NAME = "listDirectory"

    public init() {
        super(
            name: ListDirectoryTool.NAME,
            description: "List all entries (files and subdirectories) in a directory. Names of subdirectories have a trailing '/'.",
            parameters: [
                ("path", "Absolute path to the directory.", TypeSchema.Str, true)
            ],
            extra: HashMap([
                ("filterable", "false"),
                ("terminal", "false"),
                ("compactable", "true")
            ]),
            execFn: { args: HashMap<String, JsonValue> =>
                let rawPath = args.get("path")
                    .getOrThrow { ToolException("Missing required parameter: path") }
                    .asString().getValue()
                if (let Some(err) <- validateAbsolutePath(rawPath)) {
                    return err
                }
                let path = canonicalizeOrSame(rawPath)
                if (!exists(path)) {
                    return "Error: path does not exist: ${rawPath}"
                }
                try {
                    let names = ArrayList<String>()
                    for (item in Directory.readFrom(path)) {
                        if (item.isDirectory()) {
                            names.add("${item.name}/")
                        } else {
                            names.add(item.name)
                        }
                    }
                    if (names.isEmpty()) {
                        return "(empty directory: ${path})"
                    }
                    return String.join(names.toArray(), delimiter: "\n")
                } catch (e: Exception) {
                    return "Error: failed to list directory: ${e.message}"
                }
            }
        )
    }
}

//------------------------------------------------------------------------------------
// fileRead
//------------------------------------------------------------------------------------

public class FileReadTool <: NativeFuncTool {
    public static let NAME = "fileRead"

    public init() {
        super(
            name: FileReadTool.NAME,
            description: "Read a file. Optionally restrict to a line range (1-based, inclusive). Returns content wrapped in <file-content path=...> tags.",
            parameters: [
                ("filePath", "Absolute path to the file.", TypeSchema.Str, true),
                ("startLine", "Optional: starting line (1-based, inclusive). Defaults to 1.", TypeSchema.Int, false),
                ("endLine", "Optional: ending line (1-based, inclusive). Defaults to end-of-file.", TypeSchema.Int, false)
            ],
            extra: HashMap([
                ("filterable", "false"),
                ("terminal", "false"),
                ("compactable", "true")
            ]),
            execFn: { args: HashMap<String, JsonValue> =>
                let rawPath = args.get("filePath")
                    .getOrThrow { ToolException("Missing required parameter: filePath") }
                    .asString().getValue()
                if (let Some(err) <- validateAbsolutePath(rawPath)) {
                    return err
                }
                let path = canonicalizeOrSame(rawPath)
                if (!exists(path)) {
                    return "Error: file does not exist: ${rawPath}"
                }
                let startLine = getIntArg(args, "startLine", default: 1)
                let endLine = getIntArg(args, "endLine", default: Int64.Max)
                if (startLine < 1) {
                    return "Error: startLine must be >= 1, got ${startLine}"
                }
                if (endLine < startLine) {
                    return "Error: endLine (${endLine}) must be >= startLine (${startLine})"
                }
                try {
                    let content = readFile(path, withLineNumber: false, startLine: startLine, endLine: endLine)
                    let startInfo = " start=${startLine}"
                    let endInfo = if (endLine == Int64.Max) { "" } else { " end=${endLine}" }
                    return "<file-content path=${path}${startInfo}${endInfo}>\n${content}\n</file-content>"
                } catch (e: Exception) {
                    return "Error: failed to read file: ${e.message}"
                }
            }
        )
    }
}

//------------------------------------------------------------------------------------
// globSearch
//------------------------------------------------------------------------------------

public class GlobSearchTool <: NativeFuncTool {
    public static let NAME = "globSearch"

    public init() {
        super(
            name: GlobSearchTool.NAME,
            description: "Find files whose names match a glob pattern (e.g. '*.cj', '**/*.md'). Returns up to ${MAX_GLOB_RESULTS} absolute paths, one per line.",
            parameters: [
                ("pattern", "Glob pattern matched against file names.", TypeSchema.Str, true),
                ("path", "Optional: absolute directory to search in. Defaults to process cwd.", TypeSchema.Str, false)
            ],
            extra: HashMap([
                ("filterable", "false"),
                ("terminal", "false"),
                ("compactable", "true")
            ]),
            execFn: { args: HashMap<String, JsonValue> =>
                let pattern = args.get("pattern")
                    .getOrThrow { ToolException("Missing required parameter: pattern") }
                    .asString().getValue()
                if (pattern.isEmpty()) {
                    return "Error: pattern must not be empty"
                }
                let searchRoot: Path = match (getStringArg(args, "path")) {
                    case Some(rawPath) =>
                        if (let Some(err) <- validateAbsolutePath(rawPath)) {
                            return err
                        }
                        canonicalizeOrSame(rawPath)
                    case None => canonicalizeOrSame(".")
                }
                if (!exists(searchRoot)) {
                    return "Error: search path does not exist: ${searchRoot}"
                }
                let regex = try {
                    Regex(globToRegex(pattern))
                } catch (e: Exception) {
                    return "Error: invalid glob pattern '${pattern}': ${e.message}"
                }
                let results = ArrayList<String>()
                let rootStr = searchRoot.toString()
                globWalk(searchRoot, regex, results, MAX_GLOB_RESULTS, rootStr)
                if (results.isEmpty()) {
                    return "No files matching pattern '${pattern}'"
                }
                let body = String.join(results.toArray(), delimiter: "\n")
                if (Int64(results.size) >= MAX_GLOB_RESULTS) {
                    return "${body}\n[Truncated at ${MAX_GLOB_RESULTS} results. Use a more specific pattern to narrow.]"
                }
                return body
            }
        )
    }
}

private func globWalk(currentDir: Path,
                      regex: Regex,
                      results: ArrayList<String>,
                      limit: Int64,
                      globRoot: String): Unit {
    if (Int64(results.size) >= limit) {
        return
    }
    let items = try {
        Directory.readFrom(currentDir)
    } catch (_: Exception) {
        return
    }
    for (item in items) {
        if (Int64(results.size) >= limit) {
            return
        }
        if (item.isDirectory()) {
            if (SKIP_DIRS.contains(item.name)) {
                continue
            }
            globWalk(item.path, regex, results, limit, globRoot)
        } else {
            // Match against the basename (covers patterns like `*.cj`)
            // and against the path relative to globRoot (covers patterns like `**/*.md`).
            // Separators in relative path are normalized to '/' for portable patterns.
            let absStr = item.path.toString()
            let rel = if (absStr.startsWith(globRoot)) {
                let tail = absStr[globRoot.size..]
                tail.trimStart("/").trimStart("\\").replace("\\", "/")
            } else {
                item.name
            }
            if (regex.matches(item.name) || regex.matches(rel)) {
                results.add(absStr)
            }
        }
    }
}

//------------------------------------------------------------------------------------
// grepSearch
//------------------------------------------------------------------------------------

public class GrepSearchTool <: NativeFuncTool {
    public static let NAME = "grepSearch"

    public init() {
        super(
            name: GrepSearchTool.NAME,
            description: "Search for a regex pattern across file contents under a directory. Returns matching lines as 'path:lineno:content', up to ${MAX_GREP_RESULTS} hits. Optionally filter files by a glob pattern on file name.",
            parameters: [
                ("pattern", "Regular expression to find inside file contents.", TypeSchema.Str, true),
                ("path", "Optional: absolute directory to search in. Defaults to process cwd.", TypeSchema.Str, false),
                ("fileType", "Optional: glob pattern on file name to restrict which files are searched (e.g. '*.cj').", TypeSchema.Str, false)
            ],
            extra: HashMap([
                ("filterable", "false"),
                ("terminal", "false"),
                ("compactable", "true")
            ]),
            execFn: { args: HashMap<String, JsonValue> =>
                let pattern = args.get("pattern")
                    .getOrThrow { ToolException("Missing required parameter: pattern") }
                    .asString().getValue()
                if (pattern.isEmpty()) {
                    return "Error: pattern must not be empty"
                }
                let searchRoot: Path = match (getStringArg(args, "path")) {
                    case Some(rawPath) =>
                        if (let Some(err) <- validateAbsolutePath(rawPath)) {
                            return err
                        }
                        canonicalizeOrSame(rawPath)
                    case None => canonicalizeOrSame(".")
                }
                if (!exists(searchRoot)) {
                    return "Error: search path does not exist: ${searchRoot}"
                }
                let contentRegex = try {
                    Regex(pattern)
                } catch (e: Exception) {
                    return "Error: invalid regex pattern '${pattern}': ${e.message}"
                }
                let includeRegex: Option<Regex> = match (getStringArg(args, "fileType")) {
                    case Some(ft) =>
                        try {
                            Some(Regex(globToRegex(ft)))
                        } catch (e: Exception) {
                            return "Error: invalid fileType glob '${ft}': ${e.message}"
                        }
                    case None => None
                }
                let results = ArrayList<String>()
                grepWalk(searchRoot, contentRegex, includeRegex, results, MAX_GREP_RESULTS)
                if (results.isEmpty()) {
                    return "No matches for pattern '${pattern}'"
                }
                let body = String.join(results.toArray(), delimiter: "\n")
                if (Int64(results.size) >= MAX_GREP_RESULTS) {
                    return "${body}\n[Truncated at ${MAX_GREP_RESULTS} matches. Narrow the pattern or fileType.]"
                }
                return body
            }
        )
    }
}

private func grepWalk(root: Path,
                      contentRegex: Regex,
                      includeRegex: Option<Regex>,
                      results: ArrayList<String>,
                      limit: Int64): Unit {
    if (Int64(results.size) >= limit) {
        return
    }
    let items = try {
        Directory.readFrom(root)
    } catch (_: Exception) {
        return
    }
    for (item in items) {
        if (Int64(results.size) >= limit) {
            return
        }
        if (item.isDirectory()) {
            if (SKIP_DIRS.contains(item.name)) {
                continue
            }
            grepWalk(item.path, contentRegex, includeRegex, results, limit)
        } else {
            if (let Some(re) <- includeRegex) {
                if (!re.matches(item.name)) {
                    continue
                }
            }
            grepFile(item.path, contentRegex, results, limit)
        }
    }
}

/**
 * Stream a file line-by-line and append matching lines to `results`.
 * Skips:
 *   - files we can't open / decode as UTF-8 (binary or otherwise unreadable)
 *   - files whose first BINARY_SNIFF_BYTES contain a NUL byte (binary heuristic)
 *   - files larger than MAX_GREP_FILE_BYTES (cumulative byte count while reading)
 */
private func grepFile(filePath: Path, regex: Regex, results: ArrayList<String>, limit: Int64): Unit {
    try (file = File(filePath, OpenMode.Read)) {
        let reader = StringReader(file)
        var lineNo = 1
        var bytesSeen: Int64 = 0
        var binaryChecked = false
        while (let Some(line) <- reader.readln()) {
            if (Int64(results.size) >= limit) {
                return
            }
            bytesSeen += Int64(line.size) + 1
            if (bytesSeen > MAX_GREP_FILE_BYTES) {
                return  // file too large; bail
            }
            if (!binaryChecked) {
                let bytes = line.toArray()
                let scanEnd = if (Int64(bytes.size) > BINARY_SNIFF_BYTES) {
                    Int64(BINARY_SNIFF_BYTES)
                } else {
                    Int64(bytes.size)
                }
                for (i in 0..scanEnd) {
                    if (bytes[i] == 0u8) {
                        return  // looks binary; bail
                    }
                }
                if (bytesSeen >= BINARY_SNIFF_BYTES) {
                    binaryChecked = true
                }
            }
            if (regex.find(line, group: true).isSome()) {
                results.add("${filePath}:${lineNo}:${line}")
            }
            lineNo += 1
        }
    } catch (_: Exception) {
        return  // unreadable / undecodable file
    }
}

//------------------------------------------------------------------------------------
// shellExecute
//------------------------------------------------------------------------------------

@When[os == "Windows"]
private func wrapCommandWithCd(command: String, workDir: String): String {
    let escaped = workDir.replace("'", "''")
    return "Set-Location -LiteralPath '${escaped}'; ${command}"
}

@When[os != "Windows"]
private func wrapCommandWithCd(command: String, workDir: String): String {
    let escaped = workDir.replace("'", "'\\''")
    return "cd '${escaped}' && ${command}"
}

private let SHELL_TOOL_DESCRIPTION = """
Execute a shell command and return its exit code, stdout, and stderr.
- On Linux/macOS, runs through /bin/sh -c.
- On Windows, runs through powershell -NoProfile -Command.
- `command` is required; pass a single complete shell command line.
- `workDir`, if given, must be an absolute path; defaults to the process's cwd.
- `timeoutMs` defaults to 180000 (180s) and is capped at 600000 (600s).
- Stdout/stderr are captured and truncated near ~30 KB if longer.
"""

public class ShellExecuteTool <: NativeFuncTool {
    public static let NAME = "shellExecute"

    public init() {
        super(
            name: ShellExecuteTool.NAME,
            description: SHELL_TOOL_DESCRIPTION,
            parameters: [
                ("command", "The shell command to execute.", TypeSchema.Str, true),
                ("workDir", "Optional: absolute path of the working directory.", TypeSchema.Str, false),
                ("description", "Optional: short human-readable description of what the command does.", TypeSchema.Str, false),
                ("timeoutMs", "Optional: timeout in milliseconds. Default 180000, max 600000.", TypeSchema.Int, false)
            ],
            extra: HashMap([
                ("filterable", "false"),
                ("terminal", "false"),
                ("compactable", "true")
            ]),
            execFn: { args: HashMap<String, JsonValue> =>
                let command = args.get("command")
                    .getOrThrow { ToolException("Missing required parameter: command") }
                    .asString().getValue()
                if (command.isEmpty()) {
                    return "Error: command must not be empty"
                }
                let workDirOpt = getStringArg(args, "workDir")
                if (let Some(wd) <- workDirOpt) {
                    if (let Some(err) <- validateAbsolutePath(wd)) {
                        return err
                    }
                    if (!exists(Path(wd))) {
                        return "Error: workDir does not exist: ${wd}"
                    }
                }
                let requested = getIntArg(args, "timeoutMs", default: DEFAULT_SHELL_TIMEOUT_MS)
                let timeoutMs = if (requested <= 0) {
                    DEFAULT_SHELL_TIMEOUT_MS
                } else if (requested > MAX_SHELL_TIMEOUT_MS) {
                    MAX_SHELL_TIMEOUT_MS
                } else {
                    requested
                }
                return executeShell(command, workDirOpt, timeoutMs)
            }
        )
    }
}

private func executeShell(command: String, workDir: Option<String>, timeoutMs: Int64): String {
    let wrappedCommand = match (workDir) {
        case Some(wd) => wrapCommandWithCd(command, wd)
        case None => command
    }
    let cmdArgs = ArrayList<String>()
    cmdArgs.add(all: SHELL_ARGS_PREFIX)
    cmdArgs.add(wrappedCommand)

    let process = try {
        newProcess(SHELL_CMD, cmdArgs.toArray())
    } catch (e: Exception) {
        return "Error: failed to spawn shell '${SHELL_CMD}': ${e.message}"
    }

    // Drain stdout and stderr concurrently so a chatty child can't deadlock by filling
    // one pipe while the other side blocks waiting on the other reader.
    let stdoutFut: Future<String> = spawn {
        try {
            StringReader<InputStream>(process.stdOut).readToEnd()
        } catch (_: Exception) {
            ""
        }
    }
    let stderrFut: Future<String> = spawn {
        try {
            StringReader<InputStream>(process.stdErr).readToEnd()
        } catch (_: Exception) {
            ""
        }
    }

    var timedOut = false
    var exitCodeStr = "?"
    try {
        let code = process.wait(timeout: Duration.millisecond * timeoutMs)
        exitCodeStr = "${code}"
    } catch (_: Exception) {
        // Most likely a timeout — try to kill the child so the readers unblock.
        // If terminate isn't supported on this Cangjie version the catch below absorbs it.
        timedOut = true
        exitCodeStr = "timeout"
        try { process.terminate() } catch (_: Exception) {}
    }

    let stdoutStr = try { stdoutFut.get() } catch (_: Exception) { "" }
    let stderrStr = try { stderrFut.get() } catch (_: Exception) { "" }

    let header = if (timedOut) {
        "Error: shell timeout after ${timeoutMs}ms (process killed)\n"
    } else {
        ""
    }
    return "${header}Exit: ${exitCodeStr}\nStdout:\n${truncate(stdoutStr, SHELL_OUTPUT_TRUNCATE)}\nStderr:\n${truncate(stderrStr, SHELL_OUTPUT_TRUNCATE)}"
}

//------------------------------------------------------------------------------------
// Builder
//------------------------------------------------------------------------------------

/**
 * Build the set of skill built-in tools.
 * `runSkill` is always included. The five general-purpose tools
 * (listDirectory / fileRead / globSearch / grepSearch / shellExecute) are
 * included when `builtinEnabled` is true.
 */
public struct SkillToolsBuilder {
    public static func build(skillManager: SkillManager,
                             builtinEnabled!: Bool): Array<Tool> {
        let result = ArrayList<Tool>()
        result.add(SkillTool(skillManager))
        if (builtinEnabled) {
            result.add(ListDirectoryTool())
            result.add(FileReadTool())
            result.add(GlobSearchTool())
            result.add(GrepSearchTool())
            result.add(ShellExecuteTool())
        }
        return result.toArray()
    }

    /**
     * Compute one or more status messages describing the skill built-in
     * tool state. Separated from logging so callers (and tests) can inspect
     * the strings directly.
     *
     *   - When built-ins are disabled, names the switch responsible.
     *   - When built-ins are enabled, flags any that got overwritten by
     *     a user-supplied tool with the same name.
     */
    public static func computeSkillToolStatus(tm: ToolManager,
                                              builtinEnabled: Bool): Array<String> {
        let msgs = ArrayList<String>()
        if (!builtinEnabled) {
            msgs.add(
                "Skill built-in file/shell tools disabled (skillBuiltinTools: false); only runSkill is auto-injected"
            )
            return msgs.toArray()
        }
        msgs.add(
            "Skill built-in file/shell tools enabled (listDirectory, fileRead, globSearch, grepSearch, shellExecute)"
        )

        // Detect built-ins that were silently overwritten by user-supplied
        // tools with the same name. Compare by class identity, not by name.
        let overrides = ArrayList<String>()
        if (let Some(t) <- tm.findTool(ListDirectoryTool.NAME)) {
            if (!(t is ListDirectoryTool)) { overrides.add(ListDirectoryTool.NAME) }
        }
        if (let Some(t) <- tm.findTool(FileReadTool.NAME)) {
            if (!(t is FileReadTool)) { overrides.add(FileReadTool.NAME) }
        }
        if (let Some(t) <- tm.findTool(GlobSearchTool.NAME)) {
            if (!(t is GlobSearchTool)) { overrides.add(GlobSearchTool.NAME) }
        }
        if (let Some(t) <- tm.findTool(GrepSearchTool.NAME)) {
            if (!(t is GrepSearchTool)) { overrides.add(GrepSearchTool.NAME) }
        }
        if (let Some(t) <- tm.findTool(ShellExecuteTool.NAME)) {
            if (!(t is ShellExecuteTool)) { overrides.add(ShellExecuteTool.NAME) }
        }
        if (!overrides.isEmpty()) {
            msgs.add(
                "Skill built-in tool(s) overridden by user-supplied tools with the same name: ${overrides.toArray()}. " +
                "If this was intentional, ignore. Otherwise rename your tool or set skillBuiltinTools: false."
            )
        }
        return msgs.toArray()
    }

    /**
     * Log the status messages from computeSkillToolStatus at INFO level.
     * Call once, after both built-ins and user tools have been added to
     * the tool manager.
     */
    public static func logSkillToolStatus(agentName: String,
                                          tm: ToolManager,
                                          builtinEnabled: Bool): Unit {
        for (msg in computeSkillToolStatus(tm, builtinEnabled)) {
            LogUtils.info(agentName, msg)
        }
    }
}

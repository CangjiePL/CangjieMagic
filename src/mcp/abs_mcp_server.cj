/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.mcp

import magic.core.agent.Agent
import magic.core.tool.Tool
import magic.jsonable.*
import magic.log.LogUtils
import magic.ui.*

import std.fs.*
import std.io.*
import std.time.*
import std.process.*
import std.collection.{ArrayList, HashMap, map, collectArray}
import stdx.encoding.json.{JsonValue, JsonObject, JsonString}

private func convertTool2MCP(tool: Tool): MCPTool {
    let properties = JsonObject()
    let required = ArrayList<String>()
    for (param in tool.parameters) {
        let paramTypeSchema = param.typeSchema.toJsonValue().asObject()
        // description should be added to the type schema
        if (!param.description.isEmpty()) {
            paramTypeSchema.put("description", JsonString(param.description))
        }
        properties.put(param.name, paramTypeSchema)
        required.add(param.name)
    }
    let inputSchema= JsonUtils.buildJsonObject([
        ("type", JsonString("object")),
        ("properties", properties),
        ("required", JsonUtils.buildJsonArray(required.toArray()))
    ])
    return MCPTool(
        name: tool.name,
        kind: tool.kind,
        lang: tool.lang,
        category: tool.category,
        description: tool.description,
        inputSchema: inputSchema
    )
}

private func convertUI2MCP(tool: Tool): MCPUI {
    let properties = JsonObject()
    let required = ArrayList<String>()
    for (param in tool.parameters) {
        let paramTypeSchema = param.typeSchema.toJsonValue().asObject()
        // description should be added to the type schema
        if (!param.description.isEmpty()) {
            paramTypeSchema.put("description", JsonString(param.description))
        }
        properties.put(param.name, paramTypeSchema)
        required.add(param.name)
    }
    let inputSchema= JsonUtils.buildJsonObject([
        ("type", JsonString("object")),
        ("properties", properties),
        ("required", JsonUtils.buildJsonArray(required.toArray()))
    ])
    return MCPUI(
        name: tool.name,
        kind: tool.kind,
        lang: tool.lang,
        category: tool.category ?? "",
        description: tool.description,
        inputSchema: inputSchema
    )
}

private func getUIToolByKind(tools: Array<Tool>, kind: String, lang: String): Array<Tool> {
    let toolArr = ArrayList<Tool>()
    for (t in tools) {
        if (t.kind == kind && t.lang == lang) {
            toolArr.add(t)
        }
    }
    return toolArr.toArray()
}

/**
 * MCP server via the stdio & sse transport
 */
public abstract class AbsMCPServer {
    protected func send(msg: String): Unit

    protected func recv(): Option<String>

    private let tools: Array<Tool>

    protected init(tools: Array<Tool>) {
        this.tools = tools
    }

    protected func initialize(): Unit {
        var initialized = false
        while (!initialized) {
            try {
                let initReq = this.recvRequest<InitialRequest>()
                let initResp = this.buildInitResponse(initReq.id)
                this.send(initResp)

                let _ = this.recvRequest<InitializedNotification>()
                initialized = true
            } catch (e: Exception) {
                LogUtils.error("Initialization failed: ${e.message}, retrying...")
            }
        }
    }

    private func buildInitResponse(id: Int): InitialResponse {
        return InitialResponse(
            id: id,
            result: InitialResult(
                capabilities: ServerCapabilities(
                    prompts: PromptsCapability(),
                    resources: ResourcesCapability(),
                    tools: ToolsCapability()
                ),
                serverInfo: Implementation(
                    name: "Cangjie Magic Agent Server",
                    version: "0.1"
                )
            )
        )
    }

    /**
     * Currently, only tool list and call requests are supported.
     */
    public func handleRequestMessage(msg: String): Option<ToJsonValue> {
        let req = MCPRequest.fromJsonValue(JsonValue.fromStr(msg))
        let response: Option<ToJsonValue> = match (req.method) {
            case "initialize" => this.buildInitResponse(req.id)
            case "notifications/initialized" => Option<ToJsonValue>.None
            case "notifications/cancelled" => Option<ToJsonValue>.None
            case "tools/list" =>
                let mcpTools = this.tools |> map { tool => convertTool2MCP(tool) } |> collectArray
                ListToolsResponse(
                    id: req.id,
                    result: ListToolsResult(tools: mcpTools)
                )
            case "tools/call" => this.handleCallTool(CallToolRequest.fromJsonValue(JsonValue.fromStr(msg)))
            case "ui/list" =>
                let req = ListUIRequest.fromJsonValue(JsonValue.fromStr(msg))
                let kind = req.params.kind
                let lang = req.params.lang
                let toolArr = getUIToolByKind(this.tools, kind, lang)
                let mcpui = toolArr |> map { ui => convertUI2MCP(ui) } |> collectArray
                ListUIResponse(
                    id: req.id,
                    result: ListUIResult(ui: mcpui)
                )
            case "ui/call" => this.handleCallUI(CallUIRequest.fromJsonValue(JsonValue.fromStr(msg)))
            case "ping" => PingResponse(
                id: req.id,
                result: PingResult()
            )
            case _ => MCPError(
                id: req.id,
                error: ErrorContent(
                    code: INVALID_REQUEST,
                    message: "Server does not support ${req.method}"
                )
            )
        }
        return response
    }

    // 读取.so文件并返回二进制数据（字节数组）
    public func readSoFileToBinary(filePath: String): Array<UInt8> {
        try {
            // 检查文件是否存在
            let path = Path(filePath)
            if (!exists(path)) {
                println("Error: File does not exist: ${filePath}")
                return Array<UInt8>()
            }

            // 读取文件内容为字节数组
            let fileContent = File.readFrom(filePath)

            if (fileContent.isEmpty()) {
                println("Warning: File is empty: ${filePath}")
            } else {
                println("Successfully read ${fileContent.size} bytes from ${filePath}")
            }

            return fileContent

        } catch (e: FSException) {
            println("Error reading .so file: ${e}")
            return Array<UInt8>()
        }
    }

    // 将二进制数据转换为十六进制字符串格式
    public func binaryToHex(binaryData: Array<UInt8>): String {
        if (binaryData.isEmpty()) {
            return ""
        }

        // 使用StringBuilder来构建结果
        var result = StringBuilder()

        for (i in 0..binaryData.size) {
            let byte = binaryData[i]

            // 直接计算十六进制字符，避免字符串操作
            let highNibble = (byte >> 4) & 0x0F
            let lowNibble = byte & 0x0F

            // 高4位转换为十六进制字符
            let highChar: Rune
            if (highNibble < 10) {
                highChar = Rune(48 + highNibble)  // '0' = 48
            } else {
                highChar = Rune(65 + highNibble - 10)  // 'A' = 65
            }

            // 低4位转换为十六进制字符
            let lowChar: Rune
            if (lowNibble < 10) {
                lowChar = Rune(48 + lowNibble)  // '0' = 48
            } else {
                lowChar = Rune(65 + lowNibble - 10)  // 'A' = 65
            }

            // 添加到结果中
            result.append(highChar)
            result.append(lowChar)
            result.append(r' ')  // 空格分隔符

            // 每16个字节添加换行符
            if ((i + 1) % 16 == 0) {
                result.append(r'\n')
            }
        }

        return result.toString()
    }

    private func compileSoFromCode(code: String, output_path: String): String {
        println("--------------------------------compileSoFromCode-------------------------------")
        try {
            // 创建临时构建目录
            let buildDir = Path("./build_temp")
            if (!exists(buildDir)) {
                Directory.create(buildDir)
            }

            let sourceDir = buildDir.join("src")
            if (!exists(sourceDir)) {
                Directory.create(sourceDir)
            }

            // 创建CMakeLists.txt
            let cmakeFile = buildDir.join("CMakeLists.txt")
            let libName = output_path[3..output_path.size-3]
            let cmakeContent = #"
    CMAKE_MINIMUM_REQUIRED(VERSION 3.16)
    project(MyLib)
    # Compile source code
    add_library("# + libName + #" SHARED src/temp_source.cpp)

    TARGET_INCLUDE_DIRECTORIES("# + libName + #" PUBLIC
        ../include
        "D:/Program Files/Huawei/DevEco Studio/sdk/default/openharmony/native/sysroot/usr/include"
        "D:/Program Files/Huawei/DevEco Studio/sdk/default/openharmony/native/sysroot/usr/include/x86_64-linux-ohos"
    )

    target_link_libraries("# + libName + #" PUBLIC
                      # [Start ndk_graphics_draw_cmake_EGL]
                      EGL
                      # [End ndk_graphics_draw_cmake_EGL]
                      GLESv3
                      # [Start ndk_graphics_draw_cmake_hilog]
                      libhilog_ndk.z.so
                      # [End ndk_graphics_draw_cmake_hilog]
                      libace_napi.z.so
                      # [Start ndk_graphics_draw_cmake_drawing]
                      libnative_drawing.so
                      # [End ndk_graphics_draw_cmake_drawing]
                      libnative_window.so
                      libace_ndk.z.so
                      libnative_display_soloist.so
                      # [Start ndk_graphics_draw_cmake_pixelmap]
                      libpixelmap.so
                      # [End ndk_graphics_draw_cmake_pixelmap]
                      libnative_display_manager.so
                      libace_ndk.z.so
                      libpixelmap_ndk.z.so
                      libimage_source_ndk.z.so
                      librawfile.z.so
                      )
    "#
            try {
                var cmakeFileHandle = File.create(cmakeFile)
                cmakeFileHandle.write(cmakeContent.toArray())
                cmakeFileHandle.close()
            } catch (ex: Exception) {
                println("cmakeFileHandle error: ${ex.message}")
            }

            // 创建源文件
            let sourceFile = sourceDir.join("temp_source.cpp")
            var sourceFileHandle = File.create(sourceFile)
            println("--------------------------code----------------------------")
            println(code)
            sourceFileHandle.write(code.toArray())
            sourceFileHandle.close()

            // CMake配置命令
            let cmakeCmd = "D:\\Program Files\\Huawei\\DevEco Studio\\sdk\\default\\openharmony\\native\\build-tools\\cmake\\bin\\cmake.exe"
            let cmakeArgs: Array<String> = [
                "-G", "Ninja",
                "-D", "OHOS_STL=c++_shared",
                "-D", "OHOS_ARCH=arm64-v8a",
                "-D", "OHOS_PLATFORM=OHOS",
                "-D", "CMAKE_TOOLCHAIN_FILE=D:\\Program Files\\Huawei\\DevEco Studio\\sdk\\default\\openharmony\\native\\build\\cmake\\ohos.toolchain.cmake",
                "-D", "CMAKE_MAKE_PROGRAM=D:\\Program Files\\Huawei\\DevEco Studio\\sdk\\default\\openharmony\\native\\build-tools\\cmake\\bin\\ninja.exe",
                "."
            ]

            eprintln("Executing cmake configuration: ${cmakeCmd} ${cmakeArgs}")
            let (cmakeExitCode, cmakeStdOut, cmakeStdErr) = executeWithOutput(cmakeCmd, cmakeArgs, workingDirectory: buildDir)

            if (cmakeExitCode != 0) {
                let errorString = String.fromUtf8(cmakeStdErr)
                remove(buildDir, recursive: true)
                println("CMake configuration error: " + errorString)
                return "CMake configuration error: " + errorString
            }

            // Ninja构建命令
            let ninjaCmd = "D:\\Program Files\\Huawei\\DevEco Studio\\sdk\\default\\openharmony\\native\\build-tools\\cmake\\bin\\ninja.exe"
            let ninjaArgs: Array<String> = ["-f", "build.ninja"]

            eprintln("Executing ninja build: ${ninjaCmd} ${ninjaArgs}")
            let (ninjaExitCode, ninjaStdOut, ninjaStdErr) = executeWithOutput(ninjaCmd, ninjaArgs, workingDirectory: buildDir)

            if (ninjaExitCode == 0) {
                let outputString = String.fromUtf8(ninjaStdOut)

                // 复制输出文件到指定位置
                let builtLib = buildDir.join(output_path)
                eprintln(builtLib)
                if (exists(builtLib)) {
                    copy(builtLib, to: Path("./"+ output_path), overwrite: true)
                }

                // 清理临时目录
                remove(buildDir, recursive: true)

                if (outputString.trimAscii().size == 0) {
                    println("Shared library compiled successfully: ${output_path}")
                    return "Shared library compiled successfully: ${output_path}"
                } else {
                    println("Build error: " + outputString)
                    return outputString
                }
            } else {
                let errorString = String.fromUtf8(ninjaStdErr)
                // remove(buildDir, recursive: true)
                println("Build error: " + errorString)
                return "Build error: " + errorString
            }
        } catch (e: ProcessException) {
            return "Process execution error: ${e}"
        } catch (e: Exception) {
            return "Unknown error occurred: ${e}"
        }
    }

    func hdc_list_devices(): String {
        try {
            let cmd = "hdc"
            let args: Array<String> = ["list targets"]

            eprintln("Executing command: ${cmd} ${args}")
            let (exitCode, stdOutData, stdErrData) = executeWithOutput(cmd, args)

            if (exitCode == 0) {
                let outputString = String.fromUtf8(stdOutData)
                if (outputString.trimAscii().size == 0) {
                    return "Task executed successfully"
                } else {
                    return outputString
                }
            } else {
                let errorString = String.fromUtf8(stdErrData)
                return "Error: " + errorString
            }
        } catch (e: ProcessException) {
            return "Process execution error: ${e}"
        } catch (e: Exception) {
            return "Unknown error occurred: ${e}"
        }
    }

    func hdc_file_send(device_sn: String, local_file_path: String, remote_device_path: String): String {
        try {
            let cmd = "hdc"
            let args: Array<String> = ["-t", device_sn, "file", "send", local_file_path, remote_device_path]

            eprintln("Executing command: ${cmd} ${args}")
            let (exitCode, stdOutData, stdErrData) = executeWithOutput(cmd, args)

            if (exitCode == 0) {
                let outputString = String.fromUtf8(stdOutData)
                if (outputString.trimAscii().size == 0) {
                    return "Task executed successfully"
                } else {
                    return outputString
                }
            } else {
                let errorString = String.fromUtf8(stdErrData)
                return "Error: " + errorString
            }
        } catch (e: ProcessException) {
            return "Process execution error: ${e}"
        } catch (e: Exception) {
            return "Unknown error occurred: ${e}"
        }
    }

    private func handleCallUI(callUIRequest: CallUIRequest): ToJsonValue {
        println("------------------------handleCallUI------------------------")
        let lang = callUIRequest.params.lang
        if (lang == "arkui") {
            return handleCallArkUI(callUIRequest)
        } else {
            return handleCallHTMLUI(callUIRequest)
        }
    }

    private func handleCallHTMLUI(callUIRequest: CallUIRequest): ToJsonValue {
        let components = callUIRequest.params.components
        let title = callUIRequest.params.title
        let layout = callUIRequest.params.layout
        let comps = ArrayList<HTMLComponent>()
        // var kind = ""
        for(i in 0..components.size) {
            let name = components[i].name
            let args = components[i].arguments.getOrThrow().getFields()
            if (let Some(ui) <- this.findTool(name)) {
                comps.add(HTMLComponent(ui.invoke(args).content, i + 1))
                // if (kind == "") {
                //     kind = ui.kind
                // }
            } else {
                return MCPError(
                    id: callUIRequest.id,
                    error: ErrorContent(
                        code: METHOD_NOT_FOUND,
                        message: "Server does not has tool ${name}"
                    )
                )
            }
        }
        let htmlLayout = match (layout) {
            case "waterfall" => Waterfall
            case "grid" => Grid
            case _ => Linear
        }
        let code = mergeHTML(title, comps, layout: htmlLayout)
        println("---------------------------------html code--------------------------------")
        println(code)
        return CallUIResponse(
            id: callUIRequest.id,
            kind: kind,
            result: CallUIResult(
                content: [UICallContent.Text(TextContent(text: code))],
                isError: false
            )
        )
    }

    private func handleCallArkUI(callUIRequest: CallUIRequest): ToJsonValue {
        let components = callUIRequest.params.components
        // let args = (callUIRequest.params.arguments ?? JsonObject()).getFields()
        let comps = ArrayList<ArkUIComponent>()
        var kind = ""
        println("------------------------handleCallArkUI------------------------")
        for(i in 0..components.size) {
            let name = components[i].name
            let args = components[i].arguments.getOrThrow().getFields()
            if (let Some(ui) <- this.findTool(name)) {
                comps.add(ArkUIComponent(ui.invoke(args).content, i + 1))
                if (kind == "") {
                    kind = ui.kind
                }
            } else {
                return MCPError(
                    id: callUIRequest.id,
                    error: ErrorContent(
                        code: METHOD_NOT_FOUND,
                        message: "Server does not has tool ${name}"
                    )
                )
            }
        }
        println("------------------------mergeArkUIComponents------------------------")
        let code = mergeArkUIComponents(callUIRequest.params.title, comps, callUIRequest.params.layout)
        let now = DateTime.now()
        let timeStamp = now.toUnixTimeStamp().toNanoseconds() / 1_000_000
        let name = "libmylib_" + kind + "_" + timeStamp.toString() + ".so"
        let arkUISO = compileSoFromCode(code, name)
        // let binary = readSoFileToBinary(name)
        // let hexStr = binaryToHex(binary)
        // println(hexStr[..300])
        hdc_file_send(hdc_list_devices(), name, "/data/app/el1/bundle/public/com.example.magicagenthybrid/libs/arm64")
        remove(name)
        return CallUIResponse(
            id: callUIRequest.id,
            kind: kind,
            result: CallUIResult(
                content: [UICallContent.Binary(BinaryContent(data: name))], // 'Successfully compiled the .so file'
                isError: false
            )
        )
    }

    private func handleCallTool(callToolRequest: CallToolRequest): ToJsonValue {
        let name = callToolRequest.params.name
        if (let Some(tool) <- this.findTool(name)) {
            let args = (callToolRequest.params.arguments ?? JsonObject()).getFields()
            let result = tool.invoke(args).content
            return CallToolResponse(
                id: callToolRequest.id,
                result: CallToolResult(
                    content: [ToolCallContent.Text(TextContent(text: result))],
                    isError: false
                )
            )
        } else {
            return MCPError(
                id: callToolRequest.id,
                error: ErrorContent(
                    code: METHOD_NOT_FOUND,
                    message: "Server does not has tool ${name}"
                )
            )
        }
    }

    private func findTool(name: String): Option<Tool> {
        for (tool in this.tools) {
            if (tool.name == name) {
                return tool
            }
        }
        return None
    }

    protected func send<T>(response: T): Unit where T <: ToJsonValue {
        this.send(response.toJsonValue().toString())
    }

    private func recvRequest<T>(): T where T <: Jsonable<T> {
        let msg = this.recv().getOrThrow({=> MCPException("Fail to get MCP response")})
        return T.fromJsonValue(JsonValue.fromStr(msg))
    }
}

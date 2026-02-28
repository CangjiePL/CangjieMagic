/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.mcp

import magic.dsl.jsonable
import magic.core.tool.Tool
import magic.core.ToolResponse
import magic.jsonable.*
import magic.log.LogUtils
import magic.config.Config
import magic.utils.http.{HttpUtils, SSEvent}
import magic.utils.http.SSEventStream
import magic.utils.newProcess

import std.io.{StringReader, StringWriter, OutputStream, InputStream}
import std.collection.{ArrayList, HashMap, map, collectArray}
import std.time.DateTime
import stdx.encoding.url.URL
import stdx.encoding.json.*

/**
 * MCP client via the stdio transport
 */
public class UIMCPClient <: AbsMCPClient {
    private let userURL: String // The input URL specified by the user
    private var baseURL: String

    private var _sseStream: Option<SSEventStream> = None
    private var endpoint: String = ""
    private var lastInitTime: DateTime

    public init(url: String) {
        this.userURL = url
        let items = url.split("/sse") // Split the URl to get the domain base URL
        this.baseURL = items[0]
        this.lastInitTime = DateTime.now()
        this.doInit()
    }

    override public prop initParams: JsonObject {
        get() {
            let jo = JsonObject()
            jo.put("url", JsonString(this.userURL))
            return jo
        }
    }

    private prop sseStream: SSEventStream {
        get() { this._sseStream.getOrThrow() }
    }

    private func doInit(): Unit {
        this.lastInitTime = DateTime.now()
        this._sseStream = HttpUtils.sseConnect("${this.userURL}")
        if (let Some(event) <- this.sseStream.next()) {
            if (event.event != "endpoint") {
                throw MCPException("Invalid endpoint event: ${event}")
            }
            this.endpoint = event.data
            LogUtils.info("Found endpoint: ${this.endpoint}")
        } else {
            throw MCPException("Fail to make SSE connection: ${this.userURL}")
        }
        // Now, initialize
        this.initialize()
    }

    override protected func doBeforeRequest(): Unit {
        // Before sending the request, initialize the MCP
        let dur = DateTime.now() - this.lastInitTime
        if (dur.toMilliseconds() > (Config.httpReadWriteTimeout - 10000)) {
            LogUtils.info("Reinitialize the sse session. Close ${this.endpoint}")
            this.sseStream.close()
            this.doInit()
        }
    }

    override protected func doSend(req: JsonObject): Bool {
        let header = HashMap<String, String>([
            ("Content-Type", "application/json")
        ])
        let url = URL.parse(this.baseURL).resolveURL(URL.parse(this.endpoint))
        let resp = HttpUtils.post("${url}", header, req, verify: false)
        return !resp.isNone()
    }

    override protected func doRecv(): Option<String> {
        if (let Some(event) <- this.sseStream.next()) {
            LogUtils.debug("Recv: ${event}")
            if (event.event != "message") {
                throw MCPException("Invalid message event: ${event}")
            }
            return event.data
        } else {
            throw MCPException("Fail to receive sse event")
        }
    }

    override public func callUI(names: Array<String>, args: Array<Array<(String, ToJsonValue)>>, layout: String, title: String, lang: String): ToolResponse {
        let argsArr = ArrayList<Array<(String, JsonValue)>>()
        for (argArr in args) {
            let arguments = ArrayList<(String, JsonValue)>()
            for (arg in argArr) {
                arguments.add((arg[0], arg[1].toJsonValue()))
            }
            argsArr.add(arguments.toArray())
        }
        let components = ArrayList<CallUIItem>()
        for (i in 0..components.size) {
            components.add(CallUIItem(name: components[i].name, arguments: components[i].arguments))
        }
        return this.callUI(components.toArray(), layout, title, lang)
    }

    override public func callUI(components: Array<CallUIItem>, layout: String, title: String, lang: String): ToolResponse {
        println("----------------------callUI doBeforeRequest start--------------------")
        this.doBeforeRequest()
        let req = CallUIRequest(
            params: CallUIParams(
                components: components,
                title: title,
                layout: layout,
                lang: lang,
            )
        )
        // Send the request and receive its response
        println("----------------------callUI send start--------------------")
        this.send(req)
        println("----------------------callUI send end-----------------")
        let resp = this.recvResponse<CallUIResponse>()
        if (req.id != resp.id) {
            LogUtils.error("Received invalid response with mismatched id: ${resp.toJsonValue().toJsonString()}")
        }
        // Merge all result content
        let result = resp.result
        let strBuilder = StringBuilder()
        for (content in result.content) {
            strBuilder.append(content.getValue())
            strBuilder.append("\n")
        }
        if ((result.isError ?? false)) {
            return ToolResponse(strBuilder.toString(), isError: true)
        } else {
            return ToolResponse(strBuilder.toString(), isError: false)
        }
    }
}

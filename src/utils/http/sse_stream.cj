/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.utils.http

import magic.log.LogUtils

import std.collection.ArrayList
import stdx.encoding.json.{JsonValue, JsonException}

/**
 * SSEItem is a simple structure to represent an SSE item with a tag and content, like:
 * data: xxx
 * event: xxx
 */
protected struct SSEItem <: ToString {
    SSEItem(protected let tag: String,
            protected let content: String) { }

    override public func toString(): String {
        return "tag: ${content}"
    }
}

protected class SSEStream <: Iterator<SSEItem> {
    private static let TAGS = [ "data", "event" /* "retry" */ ]

    protected SSEStream(private let httpStream: HttpStream) { }

    private func read(): Option<SSEItem> {
        while (let Some(line) <- this.httpStream.next()) {
            if (line.trimAscii().isEmpty() ||
                line.startsWith(": ping") ||
                line.startsWith(": keep-alive")) {
                continue
            }

            for (tag in SSEStream.TAGS) {
                if (line.startsWith("${tag}:")) {
                    let content = line.removePrefix("${tag}:").trimAscii()
                    if (content.isEmpty()) {
                        throw HttpException("Invalid sse ${tag} with empty content")
                    }
                    return Some(SSEItem(tag, content))
                }
            }
            throw HttpException("Invalid sse line: `${line}`")
        }
        LogUtils.trace("SSE stream finished")
        return None
    }

    override public func next(): Option<SSEItem> {
        return this.read()
    }

    public func close(): Unit {
        this.httpStream.close()
    }
}

protected struct SSEvent <: ToString {
    SSEvent(protected let event: String,
            protected let data: String) { }

    override public func toString(): String {
        return "event: ${event}\ndata: ${data}"
    }
}

protected class SSEventStream <: Iterator<SSEvent> {
    private let sseStream: SSEStream

    protected init(httpStream: HttpStream) {
        this.sseStream = SSEStream(httpStream)
    }

    override public func next(): Option<SSEvent> {
        var event = "message"
        let data = StringBuilder()
        var hasData = false
        while (let Some(sseItem) <- this.sseStream.next()) {
            match (sseItem.tag) {
                case "event" =>
                    event = sseItem.content
                case "data" =>
                    if (hasData) {
                        data.append("\n")
                    }
                    data.append(sseItem.content)
                    hasData = true
                    LogUtils.trace("SSE stream read data: ${sseItem.content}")
                    return SSEvent(event, data.toString())
                case _ =>
                    throw HttpException("Invalid SSE item: `${sseItem}`")
            }
            LogUtils.trace("SSE stream read event: ${event}")
        }
        LogUtils.trace("SSE stream finished")
        return None
    }

    public func close(): Unit {
        this.sseStream.close()
    }
}

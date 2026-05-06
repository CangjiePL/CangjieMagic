/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.tests

import magic.config.Config
import magic.core.agent.AgentRequest
import magic.core.message.Message
import magic.core.model.{ChatModel, ChatRequest, ChatResponse, AsyncChatResponse}
import magic.core.tool.ToolRequest
import magic.dsl.*
import magic.prelude.*
import std.collection.ArrayList
import magic.jsonable.JsonUtils
import stdx.encoding.json.{JsonValue, JsonObject, JsonString}

@agent
private class SchemaProbeAgent {
    @tool[description: "Inspect optional parameter schema"]
    func inspect(requiredName: String, note: Option<String>): String {
        return requiredName + (note.getOrDefault({ => "" }))
    }
}

@jsonable
private class RepairPayload {
    @constraint[score > 0]
    @constraint[score <= maxScore]
    let score: Int64

    let maxScore: Int64
}

private class RecordingToolCallModel <: ChatModel {
    private let outputs: Array<Array<ToolRequest>>
    private var idx = 0
    private var _maxTokens: Option<Int64> = None
    public let requests = ArrayList<ChatRequest>()

    init(outputs: Array<Array<ToolRequest>>) {
        this.outputs = outputs
    }

    public prop provider: String {
        get() { "fake" }
    }

    public prop name: String {
        get() { "fake-tool-call" }
    }

    public prop contextLength: Int64 {
        get() { 8192 }
    }

    public mut prop maxTokens: Option<Int64> {
        get() { _maxTokens }
        set(v) { _maxTokens = v }
    }

    public func create(request: ChatRequest): ChatResponse {
        requests.add(request)
        let pos = if (idx < outputs.size) { idx } else { outputs.size - 1 }
        idx += 1
        return ChatResponse("fake", Message.assistant(""), toolRequests: outputs[pos])
    }

    public func asyncCreate(request: ChatRequest): AsyncChatResponse {
        throw UnsupportedException()
    }
}

@agent[executor: "tool-loop"]
private class ToolRepairAgent {
    @tool[description: "Submit a score payload", terminal: true]
    func submitScore(payload: RepairPayload): String {
        return "score=${payload.score}/${payload.maxScore}"
    }
}

private func buildToolRepairAgent(model: ChatModel): ToolRepairAgent {
    let agent = ToolRepairAgent()
    agent.model = model
    agent.temperature = 0.0
    return agent
}

@Test
class TestToolArgumentRepair {
    @TestCase
    func testToolSchemaMarksOptionalParameterAsNotRequired() {
        let agent = SchemaProbeAgent()
        let schema = agent.inspect.toJsonValue().toJsonString()
        let schemaJson = agent.inspect.toJsonValue().asObject()
        let parameters = schemaJson.get("parameters").getOrThrow().asObject()
        let properties = parameters.get("properties").getOrThrow().asObject().getFields()
        let required = parameters.get("required").getOrThrow().asArray().getItems()

        @Assert(schema.contains("\"requiredName\""), true)
        @Assert(schema.contains("\"note\""), true)
        @Assert(properties.contains("requiredName"), true)
        @Assert(properties.contains("note"), true)
        @Assert(required.size, 1)
        @Assert(required[0].asString().getValue(), "requiredName")
    }

    @TestCase
    func testToolArgumentConstraintFailureRepairsAndExecutesTool() {
        let model = RecordingToolCallModel([
            [ToolRequest(
                name: "submitScore",
                args: JsonUtils.buildJsonObject([
                    ("payload", JsonValue.fromStr("{\"score\": 0, \"maxScore\": 10}"))
                ])
            )],
            [ToolRequest(
                name: "submitScore",
                args: JsonUtils.buildJsonObject([
                    ("payload", JsonValue.fromStr("{\"score\": 7, \"maxScore\": 10}"))
                ])
            )]
        ])
        let agent = buildToolRepairAgent(model)
        let resp = agent.chat(AgentRequest("submit a valid score"))
        @Assert(resp.content.contains("score=7/10"), true)
        @Assert(model.requests.size, 2)
    }

    @TestCase
    func testToolArgumentMissingTopLevelArgumentRepairsAndExecutesTool() {
        let model = RecordingToolCallModel([
            [ToolRequest(name: "submitScore", args: JsonObject())],
            [ToolRequest(
                name: "submitScore",
                args: JsonUtils.buildJsonObject([
                    ("payload", JsonValue.fromStr("{\"score\": 4, \"maxScore\": 10}"))
                ])
            )]
        ])
        let agent = buildToolRepairAgent(model)
        let resp = agent.chat(AgentRequest("submit a valid score"))
        @Assert(resp.content.contains("score=4/10"), true)
        @Assert(model.requests.size, 2)
    }
}

/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.tests

import magic.core.agent.AgentExecutionException
import magic.core.model.ModelException
import magic.config.Config
import magic.dsl.*
import magic.prelude.*

@jsonable
private class ScoreCard {
    @constraint[score > 0]
    @constraint[score <= maxScore]
    let score: Int64

    let maxScore: Int64
}

@agent[executor: "naive"]
private class JsonConstraintRepairAgent {
    @prompt(
        "Return JSON only."
    )
}

private class RecordingFakeChatModel <: ChatModel {
    private let outputs: Array<String>
    private var idx = 0
    private var _maxTokens: Option<Int64> = None
    public let requests = ArrayList<ChatRequest>()

    init(outputs: Array<String>) {
        this.outputs = outputs
    }

    public prop provider: String {
        get() { "fake" }
    }

    public prop name: String {
        get() { "fake-chat" }
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
        let pos = if (idx < outputs.size) {
            idx
        } else {
            outputs.size - 1
        }
        idx += 1
        return ChatResponse("fake", Message.assistant(outputs[pos]))
    }

    public func asyncCreate(request: ChatRequest): AsyncChatResponse {
        throw UnsupportedException()
    }
}

private class FailingChatModel <: ChatModel {
    private var _maxTokens: Option<Int64> = None

    public prop provider: String {
        get() { "fake" }
    }

    public prop name: String {
        get() { "failing-chat" }
    }

    public prop contextLength: Int64 {
        get() { 8192 }
    }

    public mut prop maxTokens: Option<Int64> {
        get() { _maxTokens }
        set(v) { _maxTokens = v }
    }

    public func create(request: ChatRequest): ChatResponse {
        throw ModelException("upstream model failure")
    }

    public func asyncCreate(request: ChatRequest): AsyncChatResponse {
        throw UnsupportedException()
    }
}

private func buildTestAgent(model: ChatModel): JsonConstraintRepairAgent {
    let agent = JsonConstraintRepairAgent()
    agent.model = model
    agent.temperature = 0.0
    agent.systemPrompt = "Return JSON only."
    return agent
}

@Test
class TestJsonConstraintChatRepair {
    @TestCase
    func testChatGetRepairsConstraintFailure() {
        let model = RecordingFakeChatModel([
            "{\"score\": 0, \"maxScore\": 10}",
            "{\"score\": 7, \"maxScore\": 10}"
        ])
        let agent = buildTestAgent(model)
        let scoreCard = agent.chatGet<ScoreCard>("generate a score card").getOrThrow()
        @Assert(scoreCard.score, 7)
        @Assert(scoreCard.maxScore, 10)
        @Assert(model.requests.size, 2)
    }

    @TestCase
    func testChatGetReturnsNoneAfterConstraintRetryExhausted() {
        let oldRetryNumber = Config.outputRepairRetryNumber
        Config.outputRepairRetryNumber = 2
        try {
            let model = RecordingFakeChatModel([
                "{\"score\": 0, \"maxScore\": 10}",
                "{\"score\": 0, \"maxScore\": 10}",
                "{\"score\": 0, \"maxScore\": 10}"
            ])
            let agent = buildTestAgent(model)
            @Assert(agent.chatGet<ScoreCard>("generate a score card").isNone(), true)
            @Assert(model.requests.size, 3)
        } finally {
            Config.outputRepairRetryNumber = oldRetryNumber
        }
    }

    @TestCase
    func testChatGetRepairsWhenFirstReplyHasNoJson() {
        let model = RecordingFakeChatModel([
            "This is not JSON.",
            "{\"score\": 6, \"maxScore\": 10}"
        ])
        let agent = buildTestAgent(model)
        let scoreCard = agent.chatGet<ScoreCard>("generate a score card").getOrThrow()
        @Assert(scoreCard.score, 6)
        @Assert(scoreCard.maxScore, 10)
        @Assert(model.requests.size, 2)
    }

    @TestCase
    func testConstraintRepairPromptContainsValidationError() {
        let model = RecordingFakeChatModel([
            "{\"score\": 0, \"maxScore\": 10}",
            "{\"score\": 8, \"maxScore\": 10}"
        ])
        let agent = buildTestAgent(model)
        let _ = agent.chatGet<ScoreCard>("generate a score card").getOrThrow()
        @Assert(model.requests.size, 2)
        let repairPrompt = model.requests[1].messageList.toString()
        @Assert(repairPrompt.contains("Validation error"), true)
        @Assert(repairPrompt.contains("score > 0"), true)
    }

    @TestCase
    func testSchemaRepairPromptContainsOutputSchema() {
        let model = RecordingFakeChatModel([
            "not json",
            "{\"score\": 9, \"maxScore\": 10}"
        ])
        let agent = buildTestAgent(model)
        let _ = agent.chatGet<ScoreCard>("generate a score card").getOrThrow()
        @Assert(model.requests.size, 2)
        let repairPrompt = model.requests[1].messageList.toString()
        @Assert(repairPrompt.contains("Output does not follow the type schema"), true)
        @Assert(repairPrompt.contains("\"constraints\""), true)
        @Assert(repairPrompt.contains("score <= maxScore"), true)
    }

    @TestCase
    func testChatGetRepairsAcrossSchemaThenConstraintFailures() {
        let model = RecordingFakeChatModel([
            "not json",
            "{\"score\": 0, \"maxScore\": 10}",
            "{\"score\": 5, \"maxScore\": 10}"
        ])
        let agent = buildTestAgent(model)
        let scoreCard = agent.chatGet<ScoreCard>("generate a score card").getOrThrow()
        @Assert(scoreCard.score, 5)
        @Assert(scoreCard.maxScore, 10)
        @Assert(model.requests.size, 3)
    }

    @TestCase
    func testMissingRequiredFieldRepairPromptContainsFieldName() {
        let model = RecordingFakeChatModel([
            "{\"maxScore\": 10}",
            "{\"score\": 4, \"maxScore\": 10}"
        ])
        let agent = buildTestAgent(model)
        let scoreCard = agent.chatGet<ScoreCard>("generate a score card").getOrThrow()
        @Assert(scoreCard.score, 4)
        @Assert(scoreCard.maxScore, 10)
        @Assert(model.requests.size, 2)
        let repairPrompt = model.requests[1].messageList.toString()
        @Assert(repairPrompt.contains("Get JSON object field `score` error"), true)
    }

    @TestCase
    func testChatGetPropagatesInitialAgentFailure() {
        let agent = buildTestAgent(FailingChatModel())
        var threw = false
        try {
            let _ = agent.chatGet<ScoreCard>("generate a score card")
        } catch (ex: AgentExecutionException) {
            threw = true
            @Assert(ex.message, "upstream model failure")
        }
        @Assert(threw, true)
    }
}

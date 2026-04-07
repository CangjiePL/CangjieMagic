/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.tests

import magic.dsl.*
import magic.prelude.*

@jsonable
private class ScoreCard {
    @constraint[score > 0]
    @constraint[score <= maxScore]
    let score: Int64

    let maxScore: Int64
}

private class FakeChatModel <: ChatModel {
    private let outputs: Array<String>
    private var idx = 0
    private var _maxTokens: Option<Int64> = None

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

@Test
class TestJsonConstraintChatRepair {
    @TestCase
    func testChatGetRepairsConstraintFailure() {
        let agent = BaseAgent(model: FakeChatModel([
            "{\"score\": 0, \"maxScore\": 10}",
            "{\"score\": 7, \"maxScore\": 10}"
        ]))
        agent.executor = AgentExecutorManager.create("naive")
        let scoreCard = agent.chatGet<ScoreCard>("generate a score card").getOrThrow()
        @Assert(scoreCard.score, 7)
        @Assert(scoreCard.maxScore, 10)
    }

    @TestCase
    func testChatGetReturnsNoneAfterConstraintRetryExhausted() {
        let agent = BaseAgent(model: FakeChatModel([
            "{\"score\": 0, \"maxScore\": 10}",
            "{\"score\": 0, \"maxScore\": 10}",
            "{\"score\": 0, \"maxScore\": 10}"
        ]))
        agent.executor = AgentExecutorManager.create("naive")
        @Assert(agent.chatGet<ScoreCard>("generate a score card").isNone(), true)
    }
}

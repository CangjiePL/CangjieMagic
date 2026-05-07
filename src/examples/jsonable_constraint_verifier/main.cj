/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.examples.jsonable_constraint_verifier

import magic.core.agent.{AgentExecutionException, AgentResponseStatus}
import magic.core.model.ModelException
import magic.dsl.*
import magic.prelude.*
import magic.config.Config
import magic.model.{ModelConfig, ModelManager}
import magic.parser.ParserUtils

@jsonable
private class ScoreCard {
    @constraint[score > 0]
    @constraint[score <= maxScore]
    let score: Int64

    let maxScore: Int64
}

@jsonable
private class MissingRequiredData {
    let count: Int64
    let title: String
    let enabled: Bool
}

@jsonable
private class AliasAndDefaultData {
    @alias["user_name"]
    let name: String

    let note: Option<String>
}

@jsonable
private class AliasedRequiredScore {
    @alias["user_score"]
    let score: Int64
}

@agent[executor: "naive"]
private class JsonableConstraintVerifierAgent {
    @prompt(
        "Answer user questions"
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

private func ensure(cond: Bool, msg: String): Unit {
    if (!cond) {
        throw Exception(msg)
    }
}

private func runCase(name: String, check: () -> Unit, passed: ArrayList<String>, failed: ArrayList<String>): Unit {
    try {
        check()
        println("[PASS] ${name}")
        passed.add(name)
    } catch (ex: Exception) {
        println("[FAIL] ${name}: ${ex}")
        failed.add("${name}: ${ex}")
    }
}

private func normalizeBaseURL(baseURL: String): String {
    let trimmed = baseURL.trimEnd("/")
    if (trimmed.endsWith("/chat/completions")) {
        return trimmed.removeSuffix("/chat/completions")
    }
    return trimmed
}

private func buildRealModel(): ChatModel {
    let apiKey = Config.env["LLM_API_KEY"].getOrThrow({ => Exception("Missing env LLM_API_KEY") })
    let model = Config.env["LLM_MODEL"].getOrThrow({ => Exception("Missing env LLM_MODEL") })
    let baseURL = Config.env["LLM_BASE_URL"].getOrThrow({ => Exception("Missing env LLM_BASE_URL") })
    let config = ModelConfig(
        provider: "openai",
        kind: "chat",
        name: model,
        apiKey: apiKey,
        baseURL: normalizeBaseURL(baseURL)
    )
    return ModelManager.createChatModel(config)
}

private func buildAgent(model: ChatModel, systemPrompt: String): JsonableConstraintVerifierAgent {
    let agent = JsonableConstraintVerifierAgent()
    agent.model = model
    agent.temperature = 0.0
    agent.systemPrompt = systemPrompt
    return agent
}

private func getStructuredRawReply<T>(systemPrompt: String, question: String): String where T <: Jsonable<T> {
    let agent = buildAgent(buildRealModel(), systemPrompt)
    let request = AgentRequest(question)
    request.outputSchema = T.getTypeSchema()
    let resp = agent.chat(request)
    ensure(resp.status == AgentResponseStatus.Success, "structured chat should succeed, got ${resp.status}: ${resp.content}")
    return resp.content
}

private func runLocalChecks(passed: ArrayList<String>, failed: ArrayList<String>): Unit {
    runCase("required fields reject missing values", { =>
        var threw = false
        try {
            let _ = MissingRequiredData.fromJsonValue(JsonValue.fromStr("{}"))
        } catch (ex: JsonableException) {
            threw = true
            ensure(ex.message.contains("count"), "missing-field error should mention `count`, got: ${ex.message}")
        }
        ensure(threw, "Missing required fields should throw JsonableException")
    }, passed, failed)

    runCase("alias and option omission round-trip", { =>
        let value = AliasAndDefaultData(name: "alice", note: None)
        let json = value.toJsonValue().toJsonString()
        ensure(json.contains("user_name"), "serialized JSON should use alias")
        ensure(!json.contains("\"name\""), "serialized JSON should not use the original field name")
        ensure(!json.contains("\"note\""), "None option fields should be omitted from JSON")

        let parsed = AliasAndDefaultData.fromJsonValue(JsonValue.fromStr("{\"user_name\": \"bob\"}"))
        ensure(parsed.name == "bob", "alias should be used for parsing")
        ensure(parsed.note.isNone(), "missing optional fields should parse as None")
    }, passed, failed)

    runCase("constraint failure triggers repair and records validation prompt", { =>
        let model = RecordingFakeChatModel([
            "{\"score\": 0, \"maxScore\": 10}",
            "{\"score\": 7, \"maxScore\": 10}"
        ])
        let agent = buildAgent(model, "Return JSON only.")
        let scoreCard = agent.chatGet<ScoreCard>("generate a score card").getOrThrow()
        ensure(scoreCard.score == 7, "repaired score should be returned")
        ensure(model.requests.size == 2, "constraint repair should call the model twice")
        let repairPrompt = model.requests[1].messageList.toString()
        ensure(repairPrompt.contains("Validation error"), "repair prompt should mention validation error")
        ensure(repairPrompt.contains("score > 0"), "repair prompt should include the failed constraint")
    }, passed, failed)

    runCase("non-json output triggers schema repair", { =>
        let model = RecordingFakeChatModel([
            "plain text only",
            "{\"score\": 6, \"maxScore\": 10}"
        ])
        let agent = buildAgent(model, "Return JSON only.")
        let scoreCard = agent.chatGet<ScoreCard>("generate a score card").getOrThrow()
        ensure(scoreCard.score == 6, "schema repair should recover with the second answer")
        ensure(model.requests.size == 2, "schema repair should call the model twice")
        let repairPrompt = model.requests[1].messageList.toString()
        ensure(repairPrompt.contains("Output does not follow the type schema"), "repair prompt should mention schema mismatch")
        ensure(repairPrompt.contains("\"constraints\""), "schema prompt should include field constraints")
    }, passed, failed)

    runCase("mixed schema and constraint repairs succeed", { =>
        let model = RecordingFakeChatModel([
            "plain text only",
            "{\"score\": 0, \"maxScore\": 10}",
            "{\"score\": 5, \"maxScore\": 10}"
        ])
        let agent = buildAgent(model, "Return JSON only.")
        let scoreCard = agent.chatGet<ScoreCard>("generate a score card").getOrThrow()
        ensure(scoreCard.score == 5, "final repaired score should be returned")
        ensure(scoreCard.maxScore == 10, "final repaired maxScore should be returned")
        ensure(model.requests.size == 3, "mixed failures should trigger three model calls")
    }, passed, failed)

    runCase("missing required field triggers repair with field name", { =>
        let model = RecordingFakeChatModel([
            "{\"maxScore\": 10}",
            "{\"score\": 4, \"maxScore\": 10}"
        ])
        let agent = buildAgent(model, "Return JSON only.")
        let scoreCard = agent.chatGet<ScoreCard>("generate a score card").getOrThrow()
        ensure(scoreCard.score == 4, "repaired missing field should succeed")
        ensure(scoreCard.maxScore == 10, "repaired missing field should keep maxScore")
        ensure(model.requests.size == 2, "missing field repair should call the model twice")
        let repairPrompt = model.requests[1].messageList.toString()
        ensure(repairPrompt.contains("Get JSON object field `score` error"), "repair prompt should include the missing field name")
    }, passed, failed)

    runCase("constraint retry exhaustion returns none", { =>
        let oldRetryNumber = Config.outputRepairRetryNumber
        Config.outputRepairRetryNumber = 2
        try {
            let model = RecordingFakeChatModel([
                "{\"score\": 0, \"maxScore\": 10}",
                "{\"score\": 0, \"maxScore\": 10}",
                "{\"score\": 0, \"maxScore\": 10}"
            ])
            let agent = buildAgent(model, "Return JSON only.")
            let scoreCard = agent.chatGet<ScoreCard>("generate a score card")
            ensure(scoreCard.isNone(), "chatGet should return None after exhausting retries")
            ensure(model.requests.size == 3, "retry exhaustion should use all retry attempts")
        } finally {
            Config.outputRepairRetryNumber = oldRetryNumber
        }
    }, passed, failed)

    runCase("initial agent failure keeps upstream error", { =>
        let agent = buildAgent(FailingChatModel(), "Return JSON only.")
        var threw = false
        try {
            let _ = agent.chatGet<ScoreCard>("generate a score card")
        } catch (ex: AgentExecutionException) {
            threw = true
            ensure(ex.message == "upstream model failure", "unexpected error message: ${ex.message}")
        }
        ensure(threw, "chatGet should throw AgentExecutionException when the first model call fails")
    }, passed, failed)
}

private func runRemoteChecks(passed: ArrayList<String>, failed: ArrayList<String>): Unit {
    runCase("real model returns valid constrained JSON on first pass", { =>
        let systemPrompt = "Output JSON only. Return exactly one score card with score 4 and maxScore 10."
        let agent = buildAgent(
            buildRealModel(),
            systemPrompt
        )
        let scoreCardOpt = agent.chatGet<ScoreCard>("Generate the score card now.")
        ensure(scoreCardOpt.isSome(), "chatGet returned None")
        let scoreCard = scoreCardOpt.getOrThrow()
        ensure(scoreCard.score == 4, "expected score 4, got ${scoreCard.score}")
        ensure(scoreCard.maxScore == 10, "expected maxScore 10, got ${scoreCard.maxScore}")
    }, passed, failed)

    runCase("real model repairs semantic constraint violations", { =>
        let systemPrompt = """
            Output JSON only.
            If the conversation contains "Validation error", output exactly {"score": 7, "maxScore": 10}.
            Otherwise output exactly {"score": 11, "maxScore": 10}.
            """
        let agent = buildAgent(
            buildRealModel(),
            systemPrompt
        )
        let scoreCardOpt = agent.chatGet<ScoreCard>("Generate the score card now.")
        ensure(scoreCardOpt.isSome(), "chatGet returned None")
        let scoreCard = scoreCardOpt.getOrThrow()
        ensure(scoreCard.score == 7, "expected repaired score 7, got ${scoreCard.score}")
        ensure(scoreCard.maxScore == 10, "expected repaired maxScore 10, got ${scoreCard.maxScore}")
    }, passed, failed)

    runCase("real model repairs schema violations", { =>
        let systemPrompt = """
            If the conversation contains "Output does not follow the type schema", output exactly {"score": 6, "maxScore": 10}.
            Otherwise output exactly the plain text sentence not json.
            """
        let agent = buildAgent(
            buildRealModel(),
            systemPrompt
        )
        let scoreCardOpt = agent.chatGet<ScoreCard>("Generate the score card now.")
        ensure(scoreCardOpt.isSome(), "chatGet returned None")
        let scoreCard = scoreCardOpt.getOrThrow()
        ensure(scoreCard.score == 6, "expected repaired score 6, got ${scoreCard.score}")
        ensure(scoreCard.maxScore == 10, "expected repaired maxScore 10, got ${scoreCard.maxScore}")
    }, passed, failed)

    runCase("real model repairs missing required fields", { =>
        let systemPrompt = """
            Output JSON only.
            If the conversation contains "Get JSON object field `score` error", output exactly {"score": 4, "maxScore": 10}.
            Otherwise output exactly {"maxScore": 10}.
            """
        let agent = buildAgent(
            buildRealModel(),
            systemPrompt
        )
        let scoreCardOpt = agent.chatGet<ScoreCard>("Generate the score card now.")
        ensure(scoreCardOpt.isSome(), "chatGet returned None")
        let scoreCard = scoreCardOpt.getOrThrow()
        ensure(scoreCard.score == 4, "expected repaired score 4, got ${scoreCard.score}")
        ensure(scoreCard.maxScore == 10, "expected repaired maxScore 10, got ${scoreCard.maxScore}")
    }, passed, failed)

    runCase("real model handles mixed schema then constraint repairs", { =>
        let systemPrompt = """
            Output JSON only.
            If the conversation contains "Validation error", output exactly {"score": 5, "maxScore": 10}.
            Otherwise if the conversation contains "Output does not follow the type schema", output exactly {"score": 0, "maxScore": 10}.
            Otherwise output exactly the plain text sentence not json.
            """
        let agent = buildAgent(
            buildRealModel(),
            systemPrompt
        )
        let scoreCardOpt = agent.chatGet<ScoreCard>("Generate the score card now.")
        ensure(scoreCardOpt.isSome(), "chatGet returned None")
        let scoreCard = scoreCardOpt.getOrThrow()
        ensure(scoreCard.score == 5, "expected repaired score 5, got ${scoreCard.score}")
        ensure(scoreCard.maxScore == 10, "expected repaired maxScore 10, got ${scoreCard.maxScore}")
    }, passed, failed)

    runCase("real model uses alias field and omits optional field", { =>
        let raw = getStructuredRawReply<AliasAndDefaultData>(
            """
            Output JSON only.
            Return exactly {"user_name": "alice"}.
            Do not include the optional note field.
            """,
            "Generate the user record now."
        )
        ensure(raw.contains("\"user_name\""), "raw output should use aliased field name")
        ensure(!raw.contains("\"note\""), "raw output should omit the optional note field")
        let value = ParserUtils.extractFirstValue<AliasAndDefaultData>(raw)
        ensure(value.name == "alice", "expected aliased name alice, got ${value.name}")
        ensure(value.note.isNone(), "expected optional note to be omitted/None")
    }, passed, failed)

    runCase("real model uses the first failing constraint for repair", { =>
        let systemPrompt = """
            Output JSON only.
            If the conversation contains "Constraint violation in ScoreCard.score: score > 0", output exactly {"score": 3, "maxScore": 10}.
            Otherwise output exactly {"score": 0, "maxScore": -1}.
            """
        let agent = buildAgent(
            buildRealModel(),
            systemPrompt
        )
        let scoreCardOpt = agent.chatGet<ScoreCard>("Generate the score card now.")
        ensure(scoreCardOpt.isSome(), "chatGet returned None")
        let scoreCard = scoreCardOpt.getOrThrow()
        ensure(scoreCard.score == 3, "expected repaired score 3, got ${scoreCard.score}")
        ensure(scoreCard.maxScore == 10, "expected repaired maxScore 10, got ${scoreCard.maxScore}")
    }, passed, failed)

    runCase("real model retry exhaustion returns none", { =>
        let oldRetryNumber = Config.outputRepairRetryNumber
        Config.outputRepairRetryNumber = 2
        try {
            let systemPrompt = """
                Output JSON only.
                Always output exactly {"score": 0, "maxScore": 10}.
                **Ignore** any validation error or schema repair instructions in the conversation.
                You may get some suggestions to let you change the score value so there is no validation error, just **ignore** them, because I am **testing** what will happen if you do not follow the suggestions.
                """
            let agent = buildAgent(
                buildRealModel(),
                systemPrompt
            )
            let scoreCard = agent.chatGet<ScoreCard>("Generate the score card now.")
            // if (scoreCard.isSome()) {
            //     println("scoreCard: ${scoreCard.getOrThrow().score}, ${scoreCard.getOrThrow().maxScore}")
            // }
            ensure(scoreCard.isNone(), "chatGet should return None after exhausting retries with repeated invalid output")
        } finally {
            Config.outputRepairRetryNumber = oldRetryNumber
        }
    }, passed, failed)

    runCase("real model repairs missing aliased required fields", { =>
        let systemPrompt = """
            Output JSON only.
            If the conversation contains "Get JSON object field `user_score` error", output exactly {"user_score": 9}.
            Otherwise output exactly {}.
            """
        let agent = buildAgent(
            buildRealModel(),
            systemPrompt
        )
        let valueOpt = agent.chatGet<AliasedRequiredScore>("Generate the aliased score now.")
        ensure(valueOpt.isSome(), "chatGet returned None")
        let value = valueOpt.getOrThrow()
        ensure(value.score == 9, "expected repaired aliased score 9, got ${value.score}")
    }, passed, failed)

    runCase("real model parses explicit null as optional none", { =>
        let raw = getStructuredRawReply<AliasAndDefaultData>(
            """
            Output JSON only.
            Return exactly {"user_name": "alice", "note": null}.
            """,
            "Generate the user record now."
        )
        ensure(raw.contains("\"note\":null") || raw.contains("\"note\": null"), "raw output should contain note=null")
        let value = ParserUtils.extractFirstValue<AliasAndDefaultData>(raw)
        ensure(value.name == "alice", "expected aliased name alice, got ${value.name}")
        ensure(value.note.isNone(), "expected explicit null to parse as None")
    }, passed, failed)
}

main() {
    Config.logLevel = "TRACE"
    Config.logFile = "./logs/abc.log"
    Config.saveModelRequest = true

    let passed = ArrayList<String>()
    let failed = ArrayList<String>()

    println("== Local checks ==")
    runLocalChecks(passed, failed)

    println("\n== Real model checks ==")
    runRemoteChecks(passed, failed)

    println("\n== Summary ==")
    println("passed: ${passed.size}")
    println("failed: ${failed.size}")
    for (item in failed) {
        println(" - ${item}")
    }

    ensure(failed.isEmpty(), "jsonable constraint verification failed")
}

/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.tests

import magic.dsl.*
import magic.prelude.*
import std.collection.{ArrayList, HashMap}
import std.unittest.testmacro.PowerAssert
import std.unittest.testmacro.BeforeAll

@jsonable
private class NestedData {
    let f1: String
    let f2: Int64
    let f3: Float64
}

@jsonable
private class Data {
    let f4: Option<String>
    let f5: Array<NestedData>
    let f6: ArrayList<String>
    let f7: HashMap<String, NestedData>
}

@jsonable
private class ConstrainedData {
    @constraint[number > 0]
    @constraint[number < limit]
    let number: Int64

    let limit: Int64

    @constraint[name.size < 10]
    @constraint[this.alias.size < this.name.size]
    let name: String

    let alias: String
}

@Test
class TestJsonable {
    @TestCase
    func testJsonable() {
        let nest = NestedData(f1: "f1", f2: 2, f3: 0.0)
        let data = Data(
            f4: "f4",
            f5: [nest],
            f6: ArrayList<String>(["f6"]),
            f7: HashMap<String, NestedData>([("f7", nest)])
        )
        let js = data.toJsonValue().toJsonString()
        let jv = JsonValue.fromStr(js)
        let data2 = Data.fromJsonValue(jv)
        @Assert(data2.f4.getOrThrow(), data.f4.getOrThrow())
        @Assert(data2.f5.size, data.f5.size)
        @Assert(data2.f5[0].f1, data.f5[0].f1)
        @Assert(data2.f5[0].f2, data.f5[0].f2)
        @Assert(data2.f5[0].f3, data.f5[0].f3)
        @Assert(data2.f6.size, data.f6.size)
        @Assert(data2.f6[0], data.f6[0])
        @Assert(data2.f7["f7"].f1, data.f7["f7"].f1)
        @Assert(data2.f7["f7"].f2, data.f7["f7"].f2)
        @Assert(data2.f7["f7"].f3, data.f7["f7"].f3)
    }

    @TestCase
    func testConstraintValidate() {
        let valid = ConstrainedData(number: 3, limit: 10, name: "cangjie", alias: "cj")
        match (valid.validate()) {
            case ConstraintValidation.Pass => @Assert(true, true)
            case _ => @Assert(false, true)
        }

        let invalid = ConstrainedData(number: 0, limit: 10, name: "cangjie", alias: "cj")
        match (invalid.validate()) {
            case ConstraintValidation.Fail(msg) =>
                @Assert(msg, "Constraint violation in ConstrainedData.number: number > 0")
            case _ => @Assert(false, true)
        }
    }

    @TestCase
    func testConstraintFromJsonValue() {
        let value = ConstrainedData.fromJsonValue(
            JsonValue.fromStr("{\"number\": 3, \"limit\": 10, \"name\": \"cangjie\", \"alias\": \"cj\"}")
        )
        match (value.validate()) {
            case ConstraintValidation.Pass => @Assert(true, true)
            case _ => @Assert(false, true)
        }

        var failed = false
        try {
            let _ = ConstrainedData.fromJsonValue(
                JsonValue.fromStr("{\"number\": 11, \"limit\": 10, \"name\": \"cangjie\", \"alias\": \"cj\"}")
            )
        } catch (ex: JsonableException) {
            failed = true
            @Assert(ex.message, "Constraint violation in ConstrainedData.number: number < limit")
        }
        @Assert(failed, true)
    }

    @TestCase
    func testConstraintSchema() {
        let schema = ConstrainedData.getTypeSchema().toJsonValue().toJsonString()
        @Assert(schema.contains("\"constraints\""), true)
        @Assert(schema.contains("number > 0"), true)
        @Assert(schema.contains("this.alias.size < this.name.size"), true)
    }

    @TestCase
    func testBuiltinsValidatePass() {
        let value: Int64 = 1
        match ("hello".validate()) {
            case ConstraintValidation.Pass => @Assert(true, true)
            case _ => @Assert(false, true)
        }
        match (value.validate()) {
            case ConstraintValidation.Pass => @Assert(true, true)
            case _ => @Assert(false, true)
        }
        match (ArrayList<String>(["a"]).validate()) {
            case ConstraintValidation.Pass => @Assert(true, true)
            case _ => @Assert(false, true)
        }
    }
}

/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.log

import magic.core.message.Message
import magic.core.message.MessageList
@When[ohos == "true"]
import kit.PerformanceAnalysisKit.*
import std.collection.ArrayList

@When[ohos == "true"]
struct LogUtilsImpl {
    private static let LOG_DOMAIN: UInt32 = 0xFF00
    private static let LOG_TAG = "Magic"

    /**
     * HiLog truncates messages over 4096 bytes, so split long messages.
     * 1000 runes keeps us under the limit even for 4-byte UTF-8 codepoints.
     */
    private static func splitMessages(msg: String): Array<String> {
        let result = ArrayList<String>()
        let runes = msg.toRuneArray()
        var start = 0
        let SIZE = 1000
        while (true) {
            if (start + SIZE <= runes.size) {
                result.add(String(runes[start..(start + SIZE)]))
                start += SIZE
            } else {
                result.add(String(runes[start..]))
                break
            }
        }
        return result.toArray()
    }

    public static func info(msg: String): Unit {
        for (line in splitMessages(msg)) {
            Hilog.info(LOG_DOMAIN, LOG_TAG, line)
        }
    }

    public static func agentInfo(name: String, msg: String): Unit {
    }

    //------------------------------------------------------------

    public static func trace(msg: String): Unit {
        for (line in splitMessages(msg)) {
            Hilog.debug(LOG_DOMAIN, LOG_TAG, line)
        }
    }

    public static func agentTrace(name: String, msg: String): Unit {
    }

    //------------------------------------------------------------

    public static func debug(msg: String): Unit {
        for (line in splitMessages(msg)) {
            Hilog.debug(LOG_DOMAIN, LOG_TAG, line)
        }
    }

    public static func agentDebug(name: String, msg: String): Unit {
    }

    //------------------------------------------------------------

    public static func error(msg: String): Unit {
        for (line in splitMessages(msg)) {
            Hilog.error(LOG_DOMAIN, LOG_TAG, line)
        }
    }

    public static func agentError(name: String, msg: String): Unit {
    }
}

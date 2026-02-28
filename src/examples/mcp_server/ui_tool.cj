/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.examples.mcp_server

import magic.dsl.*
import magic.prelude.*
import magic.config.Config
import magic.mcp.UIMCPServer
import magic.ui.arkui.*
import magic.ui.html.*
import magic.ui.*

/*@tool[
    description: "饼图，展示数据占比",
    terminal: true,
    kind: "display",
    parameters: {
        info: "展示信息"
    }
]
public func pieChartUI(info: PieChartInfo): String {
    template_pie_chart(info)
}

@tool[
    description: "折线图，展示数据趋势",
    terminal: true,
    kind: "display",
]
public func lineChartUI(info: LineChartInfo): String {
    template_line_chart(info)
}

@tool[
    description: "以纯文本为核心内容的列表，每个列表项是一段文字，比如步骤说明列表",
    terminal: true,
    kind: "display",
    parameters: {
        info: "列表展示信息"
    }
]
public func textListUI(info: ListInfo): String {
    template_text_list(info)
}

@tool[
    description: "单选列表，用户只能从预设选项中选择唯一一项，适用于需要用户在互斥选项中做出唯一选择的场景（如性别、支付方式、学历等）",
    parameters: {
        info: "选项列表"
    },
    kind: "input",
    terminal: true
]
public func radioListUI(info: SelectInfo): String {
    // if (info.arr.size <= 5) {
        return template_radio_list(info)
    // } else {
    //     return template_drop_list(info)
    // }
}

@tool[
    description: "多选列表",
    parameters: {
        info: "选项列表"
    },
    kind: "input",
    terminal: true
]
public func checkboxListUI(info: SelectInfo): String {
    // if (info.arr.size <= 5) {
        return template_checkbox_list(info)
    // } else {
    //     return template_drop_list(info)
    // }
}

@tool[
    description: "单选列表，用户只能从预设选项中选择唯一一项，适用于需要用户在互斥选项中做出唯一选择的场景（如性别、支付方式、学历等）",
    parameters: {
        info: "选项列表"
    },
    kind: "input",
    terminal: true
]
public func confirmBtnUI(): String {
    return template_confirm_btn()
}

@tool[
    description: "文本输入框",
    parameters: {
        info: "描述需要输入文本内容的标题"
    },
    kind: "input",
    terminal: true
]
public func textAreaUI(info: TextAreaInfo): String {
    return template_textarea(info)
}

@tool[
    description: "日期选择器",
    kind: "input",
    terminal: true
]
public func datePickerUI(info: DatePickerInfo): String {
    return template_date_picker(info)
}

@tool[
    description: "时间选择器，用于选择时间点",
    kind: "input",
    terminal: true
]
public func timePickerUI(info: TimePickerInfo): String {
    return template_time_picker(info)
}

@tool[
    description: "日历选择器",
    kind: "input",
    terminal: true
]
public func calendarPickerUI(info: CalendarPickerInfo): String {
    return template_calendar_picker(info)
}

@ui[
    description: '''
    ... ...
    ''',
    lang: "html",
    dump: true
]
public func testUI1(info: TextInfo, list: Array<TimeLineItem>) {
    textListUI(info)
    timeLineUI(list)
    confirmBtnUI()
}

@ui[
    description: '''
    ... ...
    ''',
    lang: "arkui",
    dump: true
]
public func testUI2(info1: CalendarPickerInfo, info2: TimePickerInfo) {
    template_time_picker(info2)
    template_calendar_picker(info1)
}*/


main() {
    Config.logLevel = "TRACE"
    Config.logFile = "./logs/mcp-server.log"
    println("--------------UIMCPServer----------------")
    UIMCPServer.startWith([
        textAreaUI, radioListUI, multiListUI,selectNumberUI, selectRangeUI, singleDateUI, startEndDateUI, confirmBtnUI,
        compareUI, creativeResume, commonResume, technicalResume, businessResume, clockUI, imgListUI, textListUI, textURLListUI, ticketListUI, timeLineUI, pieChartUI, lineChartUI, mapUI, meetingUI, productCards, recipeUI, recommendScenices,
        template_radio_list, template_checkbox_list, template_textarea, template_slider, template_calendar_picker,
        template_time_line, template_pie_chart, template_line_chart, template_text_list, template_image_text_list, template_date_picker,template_time_picker], "0.0.0.0", 8000)
}
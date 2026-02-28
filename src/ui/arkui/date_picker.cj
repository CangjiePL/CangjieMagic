package magic.ui.arkui

import magic.dsl.*
import magic.prelude.*
import magic.jsonable.*
import std.collection.*
import stdx.encoding.json.{JsonValue, JsonObject, JsonException, JsonKind, JsonInt, JsonString, JsonBool, JsonFloat, JsonArray, JsonNull}


@jsonable
public class DatePickerInfo {
    @field["Title of the date picker, displayed at the top as explanatory text"]
    let title: String
    @field["Start optional date of the date picker, format: YYYY-M-D, restricts the earliest date selectable by the user"]
    let start_date: String
    @field["End optional date of the date picker, format: YYYY-M-D, restricts the latest date selectable by the user"]
    let end_date: String
}

@ui[
    description: "日期选择器：日期维度选择组件，用于选择具体年/月/日的日期信息",
    lang: "arkui",
    kind: "input"
]
public func template_date_picker(info: DatePickerInfo) {
    '''
        namespace NativeModule {
            class ArkUIDatePickerNode : public ArkUINode {
            public:
                // 构造函数：创建日期选择器节点，复用父类初始化逻辑
                ArkUIDatePickerNode()
                    : ArkUINode((NativeModuleInstance::GetInstance()->GetNativeNodeAPI())->createNode(ARKUI_NODE_DATE_PICKER)) {}

                // ===================== 基础字符串属性 =====================
                /**
                * @brief 设置日期选择器的起始日期
                * @param startDate 起始日期字符串（格式："YYYY-M-D"，默认"1970-1-1"）
                */
                void SetStartDate(const char* startDate) {
                    assert(handle_);
                    ArkUI_AttributeItem item = {};
                    item.string = const_cast<char*>(startDate);
                    nativeModule_->setAttribute(handle_, NODE_DATE_PICKER_START, &item);
                }

                /**
                * @brief 设置日期选择器的结束日期
                * @param endDate 结束日期字符串（格式："YYYY-M-D"，默认"2100-12-31"）
                */
                void SetEndDate(const char* endDate) {
                    assert(handle_);
                    ArkUI_AttributeItem item = {};
                    item.string = const_cast<char*>(endDate);
                    nativeModule_->setAttribute(handle_, NODE_DATE_PICKER_END, &item);
                }

                /**
                * @brief 设置日期选择器的选中日期
                * @param selectedDate 选中日期字符串（格式："YYYY-M-D"，默认"2024-01-22"）
                */
                void SetSelectedDate(const char* selectedDate) {
                    assert(handle_);
                    ArkUI_AttributeItem item = {};
                    item.string = const_cast<char*>(selectedDate);
                    nativeModule_->setAttribute(handle_, NODE_DATE_PICKER_SELECTED, &item);
                }

                const char* GetSelectedDate() {
                    assert(handle_);
                    const ArkUI_AttributeItem* attrItem = nativeModule_->getAttribute(handle_, NODE_DATE_PICKER_SELECTED);

                    if (!attrItem) {
                        printf("GetText error: getAttribute return null!");
                        return nullptr;
                    }

                    return attrItem->string;
                }

                /**
                * @brief 设置日期选择器上下边缘项的文本样式
                * @param style 样式字符串（格式："#ARGB;字号;字重;字体列表;字体样式"）
                * @example "#ff182431;14;normal;Arial,HarmonyOS Sans;normal"
                */
                void SetDisappearTextStyle(const char* style) {
                    assert(handle_);
                    ArkUI_AttributeItem item = {};
                    item.string = const_cast<char*>(style);
                    nativeModule_->setAttribute(handle_, NODE_DATE_PICKER_DISAPPEAR_TEXT_STYLE, &item);
                }

                /**
                * @brief 设置日期选择器非边缘、非选中项的文本样式
                * @param style 样式字符串（格式同DisappearTextStyle）
                */
                void SetTextStyle(const char* style) {
                    assert(handle_);
                    ArkUI_AttributeItem item = {};
                    item.string = const_cast<char*>(style);
                    nativeModule_->setAttribute(handle_, NODE_DATE_PICKER_TEXT_STYLE, &item);
                }

                /**
                * @brief 设置日期选择器选中项的文本样式
                * @param style 样式字符串（格式同DisappearTextStyle）
                */
                void SetSelectedTextStyle(const char* style) {
                    assert(handle_);
                    ArkUI_AttributeItem item = {};
                    item.string = const_cast<char*>(style);
                    nativeModule_->setAttribute(handle_, NODE_DATE_PICKER_SELECTED_TEXT_STYLE, &item);
                }

                // ===================== 基础数值属性（i32/u32/f32） =====================
                /**
                * @brief 设置是否显示农历
                * @param isShowLunar 1显示，0不显示（默认0）
                */
                void SetShowLunar(int32_t isShowLunar) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.i32 = isShowLunar}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_DATE_PICKER_LUNAR, &item);
                }

                /**
                * @brief 设置日期选择器的显示模式
                * @param mode 日期选择器模式（ArkUI_DatePickerMode枚举值，@since 18）
                */
                void SetMode(ArkUI_DatePickerMode mode) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.i32 = static_cast<int32_t>(mode)}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_DATE_PICKER_MODE, &item);
                }

                /**
                * @brief 设置是否开启触觉反馈
                * @param enable 1开启，0关闭（@since 18）
                */
                void SetEnableHapticFeedback(int32_t enable) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.i32 = enable}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_DATE_PICKER_ENABLE_HAPTIC_FEEDBACK, &item);
                }
            };
        }  // namespace NativeModule

        // 外部C接口，供外部调用
        extern "C" {
            using namespace NativeModule;

            std::shared_ptr<ArkUIBaseNode> CreateDatePicker() {
                auto column = std::make_shared<ArkUIColumnNode>();
                column->SetBorderWidth(1);
                column->SetPercentWidth(1);
                column->SetCornerRadius(20);
                column->SetBorderColor(0xFFefefef);
                column->SetShadowStyle(ARKUI_SHADOW_STYLE_OUTER_DEFAULT_MD);

                auto title = std::make_shared<ArkUITextNode>();
                title->SetTextContent(\"{% info.title %}\");  // 替换为日期选择器标题
                title->SetFontSize(22);
                title->SetPercentWidth(1);
                title->SetPadding(15, 0.0, 10, 15);
                title->SetFontWeight(ARKUI_FONT_WEIGHT_W600);
                column->AddChild(title);

                auto datePickerNode = std::make_shared<ArkUIDatePickerNode>();
                // 基础日期范围设置
                datePickerNode->SetStartDate(\"{% info.start_date %}\");          // 起始日期
                datePickerNode->SetEndDate(\"{% info.end_date %}\");          // 结束日期

                // 显示相关设置
                datePickerNode->SetMode(ArkUI_DatePickerMode::ARKUI_DATEPICKER_MODE_DATE); // 仅日期模式
                datePickerNode->SetEnableHapticFeedback(1);        // 启用触觉反馈

                // 文本样式设置（选中项、普通项、边缘项）
                // 选中项样式：蓝色、16号字、加粗、HarmonyOS Sans字体、正常样式
                datePickerNode->SetSelectedTextStyle("#ff0088FF;16;bold;HarmonyOS Sans;normal");
                // 普通项样式：深灰色、14号字、常规、HarmonyOS Sans字体、正常样式
                datePickerNode->SetTextStyle("#ff182431;14;normal;HarmonyOS Sans;normal");
                // 边缘项样式：浅灰色、12号字、常规、HarmonyOS Sans字体、正常样式
                datePickerNode->SetDisappearTextStyle("#ff999999;12;normal;HarmonyOS Sans;normal");

                datePickerNode->SetPercentWidth(0.9);
                auto onClick = [datePickerNode](ArkUI_NodeEvent *event) {
                        // 从组件事件获取事件类型
                        auto eventType = OH_ArkUI_NodeEvent_GetEventType(event);
                        switch (eventType) {
                            case NODE_DATE_PICKER_EVENT_ON_DATE_CHANGE: {
                                auto compEvent = OH_ArkUI_NodeEvent_GetNodeComponentEvent(event);
                                if (compEvent) {
                                    // 解析参数：年、月（0-11 → +1）、日
                                    int32_t year = compEvent->data[0].i32;
                                    int32_t month = compEvent->data[1].i32 + 1;
                                    int32_t day = compEvent->data[2].i32;
                                    char selectedDate[32] = {0};
                                    snprintf(selectedDate, sizeof(selectedDate), "%d-%d-%d", year, month, day);
                                    g_click_callback(\"{% info.title %}\", selectedDate);
                                }
                            }
                            default: {
                                break;
                            }
                        }
                    };
                datePickerNode->RegisterOnDatePickerChange(onClick);

                // 7. 将行容器添加到列容器
                column->AddChild(datePickerNode);
                column->SetMargin(0, 0, 20, 0);

                return column;
            }
        }  // extern "C"
    '''
}
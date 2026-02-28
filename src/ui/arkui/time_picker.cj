package magic.ui.arkui

import magic.dsl.*
import magic.prelude.*
import magic.jsonable.*
import std.collection.*
import stdx.encoding.json.{JsonValue, JsonObject, JsonException, JsonKind, JsonInt, JsonString, JsonBool, JsonFloat, JsonArray, JsonNull}


@jsonable
public class TimePickerInfo {
    @field["Title of the time picker, displayed at the top as explanatory text"]
    let title: String
}

@ui[
    description: "时间选择器：时间点选择组件，用于选择具体时/分/秒的时间信息",
    lang: "arkui",
    kind: "input"
]
public func template_time_picker(info: TimePickerInfo) {
    '''
        namespace NativeModule {
            class ArkUITimePickerNode : public ArkUINode {
            public:
                // 构造函数：创建时间选择器节点，复用父类初始化逻辑
                ArkUITimePickerNode()
                    : ArkUINode((NativeModuleInstance::GetInstance()->GetNativeNodeAPI())->createNode(ARKUI_NODE_TIME_PICKER)) {}

                // ===================== 基础字符串属性 =====================
                /**
                * @brief 设置时间选择器的起始时间
                * @param startTime 起始时间字符串（格式："HH-MM"）
                */
                void SetStartTime(const char* startTime) {
                    assert(handle_);
                    ArkUI_AttributeItem item = {};
                    item.string = const_cast<char*>(startTime);
                    nativeModule_->setAttribute(handle_, NODE_TIME_PICKER_START, &item);
                }

                /**
                * @brief 设置时间选择器的结束时间
                * @param endTime 结束时间字符串（格式："HH-MM"）
                */
                void SetEndTime(const char* endTime) {
                    assert(handle_);
                    ArkUI_AttributeItem item = {};
                    item.string = const_cast<char*>(endTime);
                    nativeModule_->setAttribute(handle_, NODE_TIME_PICKER_END, &item);
                }

                /**
                * @brief 设置时间选择器上下边缘项的文本样式
                * @param style 样式字符串（格式："#ARGB;字号;字重;字体列表;字体样式"）
                * @example "#ff182431;14;normal;Arial,HarmonyOS Sans;normal"
                */
                void SetDisappearTextStyle(const char* style) {
                    assert(handle_);
                    ArkUI_AttributeItem item = {};
                    item.string = const_cast<char*>(style);
                    nativeModule_->setAttribute(handle_, NODE_TIME_PICKER_DISAPPEAR_TEXT_STYLE, &item);
                }

                /**
                * @brief 设置时间选择器非边缘、非选中项的文本样式
                * @param style 样式字符串（格式同DisappearTextStyle）
                */
                void SetTextStyle(const char* style) {
                    assert(handle_);
                    ArkUI_AttributeItem item = {};
                    item.string = const_cast<char*>(style);
                    nativeModule_->setAttribute(handle_, NODE_TIME_PICKER_TEXT_STYLE, &item);
                }

                /**
                * @brief 设置时间选择器选中项的文本样式
                * @param style 样式字符串（格式同DisappearTextStyle）
                */
                void SetSelectedTextStyle(const char* style) {
                    assert(handle_);
                    ArkUI_AttributeItem item = {};
                    item.string = const_cast<char*>(style);
                    nativeModule_->setAttribute(handle_, NODE_TIME_PICKER_SELECTED_TEXT_STYLE, &item);
                }

                /**
                * @brief 设置时间选择器的选中时间
                * @param selectedTime 选中时间字符串（格式："HH-MM"）
                */
                void SetSelectedTime(const char* selectedTime) {
                    assert(handle_);
                    ArkUI_AttributeItem item = {};
                    item.string = const_cast<char*>(selectedTime);
                    nativeModule_->setAttribute(handle_, NODE_TIME_PICKER_SELECTED, &item);
                }
                // ===================== 基础数值属性（i32/u32/f32） =====================
                /**
                * @brief 设置是否使用24小时制（军事时间）
                * @param isUseMilitaryTime 1使用，0不使用（默认0）
                */
                void SetUseMilitaryTime(int32_t isUseMilitaryTime) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.i32 = isUseMilitaryTime}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_TIME_PICKER_USE_MILITARY_TIME, &item);
                }

                /**
                * @brief 设置12小时制下AM/PM选项是否与时间级联
                * @param enableCascade 1开启，0关闭（默认0）
                */
                void SetEnableCascade(int32_t enableCascade) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.i32 = enableCascade}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_TIME_PICKER_ENABLE_CASCADE, &item);
                }
            };
        }  // namespace NativeModule

        // 外部C接口，供外部调用
        extern "C" {
            using namespace NativeModule;

            std::shared_ptr<ArkUIBaseNode> CreateTimePickerExample() {
                auto column = std::make_shared<ArkUIColumnNode>();
                column->SetBorderWidth(1);
                column->SetPercentWidth(1);
                column->SetCornerRadius(20);
                column->SetBorderColor(0xFFefefef);
                column->SetShadowStyle(ARKUI_SHADOW_STYLE_OUTER_DEFAULT_MD);

                auto title = std::make_shared<ArkUITextNode>();
                title->SetTextContent(\"{% info.title %}\");
                title->SetFontSize(22);
                title->SetPercentWidth(1);
                title->SetPadding(15, 0.0, 10, 15);
                title->SetFontWeight(ARKUI_FONT_WEIGHT_W600);
                column->AddChild(title);

                auto timePickerNode = std::make_shared<ArkUITimePickerNode>();

                // 显示相关设置
                timePickerNode->SetUseMilitaryTime(1);             // 启用24小时制（默认0，改为1）
                timePickerNode->SetEnableCascade(1);               // 12小时制下AM/PM级联（此处24小时制也可设置，兼容）

                // 文本样式设置（选中项、普通项、边缘项，格式与DatePicker完全一致）
                // 选中项样式：蓝色、20号字、加粗、HarmonyOS Sans字体、正常样式
                timePickerNode->SetSelectedTextStyle("#ff0088FF;20;bold;HarmonyOS Sans;normal");
                // 普通项样式：深灰色、18号字、常规、HarmonyOS Sans字体、正常样式
                timePickerNode->SetTextStyle("#ff182431;18;normal;HarmonyOS Sans;normal");
                // 边缘项样式：浅灰色、16号字、常规、HarmonyOS Sans字体、正常样式
                timePickerNode->SetDisappearTextStyle("#ff999999;16;normal;HarmonyOS Sans;normal");
                timePickerNode->SetPercentWidth(0.6);
                auto onClick = [timePickerNode](ArkUI_NodeEvent *event) {
                        // 从组件事件获取事件类型
                        auto eventType = OH_ArkUI_NodeEvent_GetEventType(event);
                        switch (eventType) {
                            case NODE_TIME_PICKER_EVENT_ON_CHANGE: {
                                auto componentEvent = OH_ArkUI_NodeEvent_GetNodeComponentEvent(event);
                                std::string hourStr = std::to_string(componentEvent->data[0].i32);
                                std::string minStr = std::to_string(componentEvent->data[1].i32);
                                g_click_callback(\"{% info.title %}\", hourStr + ":" + minStr);
                            }
                            default: {
                                break;
                            }
                        }
                    };
                timePickerNode->RegisterOnTimePickerChange(onClick);
                column->AddChild(timePickerNode);
                column->SetMargin(0, 0, 20, 0);
                return column;
            }
        }  // extern "C"
    '''
}
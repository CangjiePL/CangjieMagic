package magic.ui.arkui

import magic.dsl.*
import magic.prelude.*
import magic.jsonable.*
import std.collection.*
import stdx.encoding.json.{JsonValue, JsonObject, JsonException, JsonKind, JsonInt, JsonString, JsonBool, JsonFloat, JsonArray, JsonNull}

@ui[
    description: "多选复选框列表",
    lang: "arkui",
    kind: "input"
]
public func template_checkbox_list(info: SelectInfo) {
    '''
        namespace NativeModule {
            class ArkUICheckboxNode : public ArkUINode {
            public:
                // 构造函数：创建复选框节点，复用父类ArkUINode的初始化逻辑
                ArkUICheckboxNode()
                    : ArkUINode((NativeModuleInstance::GetInstance()->GetNativeNodeAPI())->createNode(ARKUI_NODE_CHECKBOX)) {}

                /**
                * @brief 设置复选框是否选中
                * @param isSelected 1表示选中，0表示未选中
                */
                void SetSelected(int32_t isSelected) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.i32 = isSelected}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_CHECKBOX_SELECT, &item);
                }

                /**
                * @brief 设置复选框选中时的颜色（0xARGB格式）
                * @param color ARGB格式的颜色值，如0xFF1122FF
                */
                void SetSelectColor(uint32_t color) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.u32 = color}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_CHECKBOX_SELECT_COLOR, &item);
                }

                /**
                * @brief 设置复选框未选中时的边框颜色（0xARGB格式）
                * @param color ARGB格式的颜色值，如0xFF1122FF
                */
                void SetUnselectColor(uint32_t color) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.u32 = color}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_CHECKBOX_UNSELECT_COLOR, &item);
                }

                /**
                * @brief 设置复选框内部勾选标记的样式
                * @param markColor 标记颜色（0xARGB格式）
                * @param markSize 标记大小（vp，可选，传-1则不设置）
                * @param strokeWidth 标记描边宽度（vp，可选，传-1则使用默认值2）
                */
                void SetMarkStyle(uint32_t markColor, float markSize = -1.0f, float strokeWidth = -1.0f) {
                    assert(handle_);
                    // 计算需要的数值个数（至少1个：颜色；可选添加大小、描边宽度）
                    int valueCount = 1;
                    if (markSize >= 0) valueCount++;
                    if (strokeWidth >= 0) valueCount++;

                    // 初始化数值数组
                    ArkUI_NumberValue* value = new ArkUI_NumberValue[valueCount];
                    value[0].u32 = markColor;  // 第一个值：标记颜色

                    int index = 1;
                    if (markSize >= 0) {
                        value[index++].f32 = markSize;  // 第二个值：标记大小（可选）
                    }
                    if (strokeWidth >= 0) {
                        value[index].f32 = strokeWidth;  // 第三个值：描边宽度（可选）
                    }

                    // 设置属性
                    ArkUI_AttributeItem item = {value, valueCount};
                    nativeModule_->setAttribute(handle_, NODE_CHECKBOX_MARK, &item);

                    // 释放内存
                    delete[] value;
                }

                /**
                * @brief 设置复选框的形状
                * @param shape 复选框形状（ArkUI_CheckboxShape枚举值）
                */
                void SetShape(ArkUI_CheckboxShape shape) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.i32 = shape}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_CHECKBOX_SHAPE, &item);
                }

                /**
                * @brief 设置复选框的名称（API 15+）
                * @param name 复选框名称字符串
                */
                void SetName(const char* name) {
                    assert(handle_);
                    ArkUI_AttributeItem item = {};
                    item.string = const_cast<char*>(name);
                    nativeModule_->setAttribute(handle_, NODE_CHECKBOX_NAME, &item);
                }

                /**
                * @brief 设置复选框所属的分组名称（API 15+）
                * @param groupName 分组名称字符串
                */
                void SetGroup(const char* groupName) {
                    assert(handle_);
                    ArkUI_AttributeItem item = {};
                    item.string = const_cast<char*>(groupName);
                    nativeModule_->setAttribute(handle_, NODE_CHECKBOX_GROUP, &item);
                }
            };
        }  // namespace NativeModule

        // 外部C接口，供外部调用
        extern "C" {
            using namespace NativeModule;
            std::string msg = " ";
            std::shared_ptr<ArkUIRowNode> CreateCheckboxRow(const std::string& groupName,
                                             const std::string& value) {
                auto row = std::make_shared<ArkUIRowNode>();

                // 创建Radio组件
                auto checkboxItem = std::make_shared<ArkUICheckboxNode>();
                checkboxItem->SetGroup(groupName.c_str());
                checkboxItem->SetName(value.c_str());
                checkboxItem->SetShape(ArkUI_CHECKBOX_SHAPE_ROUNDED_SQUARE);
                checkboxItem->SetSelectColor(0xFF0088FF);
                checkboxItem->SetUnselectColor(0xFF999999);
                auto onClick = [groupName, value](ArkUI_NodeEvent *event) {
                    // 从组件事件获取事件类型
                    auto eventType = OH_ArkUI_NodeEvent_GetEventType(event);
                    switch (eventType) {
                        case NODE_CHECKBOX_EVENT_ON_CHANGE: {
                            auto componentEvent = OH_ArkUI_NodeEvent_GetNodeComponentEvent(event);
                            if (componentEvent) {
                                bool checked = (componentEvent->data[0].i32 == 1);
                                std::string str = " " + value + " ";
                                size_t pos = msg.find(str);
                                bool isContains = (pos != std::string::npos);
                                if (checked && !isContains) {
                                    msg += value + " ";
                                }
                                if (!checked && isContains) {
                                    msg = msg.replace(pos, str.length(), " ");
                                }
                                g_click_callback(groupName, msg);
                            } else {
                                OH_LOG_Print(LOG_APP, LOG_ERROR, 0xFF00, "[CreateCheckboxRow_ChangeEvent]", "==>OH_ArkUI_NodeEvent_GetNumberValue error");
                            }
                        }
                        default: {
                            break;
                        }
                    }
                };
                checkboxItem->RegisterOnCheckboxChange(onClick);

                // 创建文本组件
                auto textInfo = std::make_shared<ArkUITextNode>();
                textInfo->SetTextContent(value);
                textInfo->SetFontSize(18);

                // 设置Row样式
                row->AddChild(checkboxItem);
                row->AddChild(textInfo);
                row->SetMargin(0, 0, 10, 0);
                row->SetBorderColor(0xFFefefef);
                row->SetBorderWidth(1);
                row->SetPercentWidth(0.9);
                row->SetCornerRadius(15);
                row->SetPadding(15, 10, 20, 10);

                return row;
            }

            std::shared_ptr<ArkUIBaseNode> CreateCheckboxList() {
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
                column->SetMargin(0, 0, 20, 0);

                {% for item in info.data %}
                    column->AddChild(CreateCheckboxRow(\"{% info.title %}\", \"{% item %}\"));
                {% /for %}
                return column;
            }
        }  // extern "C"
    '''
}
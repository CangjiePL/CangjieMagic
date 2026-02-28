package magic.ui.arkui

import magic.dsl.*
import magic.prelude.*
import magic.jsonable.*
import std.collection.*
import stdx.encoding.json.{JsonValue, JsonObject, JsonException, JsonKind, JsonInt, JsonString, JsonBool, JsonFloat, JsonArray, JsonNull}

@jsonable
public class TextAreaInfo {
    @field["The title text of the text area input box"]
    let title: String
}

@ui[
    description: "文本输入框：多行文本输入组件，用于接收用户自定义的文本内容输入",
    lang: "arkui",
    kind: "input"
]
public func template_textarea(info: TextAreaInfo) {
    '''
        namespace NativeModule {
        class ArkUITextAreaNode : public ArkUINode {
            public:
                // 构造函数：创建多行文本框节点，复用父类初始化逻辑
                ArkUITextAreaNode()
                    : ArkUINode((NativeModuleInstance::GetInstance()->GetNativeNodeAPI())->createNode(ARKUI_NODE_TEXT_AREA)) {}

                // ===================== 基础字符串属性 =====================
                /**
                * @brief 设置占位符文本
                * @param placeholder 占位符字符串（如"请输入内容..."）
                */
                void SetPlaceholder(const char* placeholder) {
                    assert(handle_);
                    ArkUI_AttributeItem item = {};
                    item.string = const_cast<char*>(placeholder);
                    nativeModule_->setAttribute(handle_, NODE_TEXT_AREA_PLACEHOLDER, &item);
                }

                /**
                * @brief 设置文本框默认内容
                * @param text 文本内容字符串
                */
                void SetText(const char* text) {
                    assert(handle_);
                    ArkUI_AttributeItem item = {};
                    item.string = const_cast<char*>(text);
                    nativeModule_->setAttribute(handle_, NODE_TEXT_AREA_TEXT, &item);
                }

                /**
                * @brief 获取已设置的文本内容
                * @return 返回获取到的文本字符串（内部缓冲，无需手动释放，使用前需判空）
                */
                const char* GetText() {
                    assert(handle_);
                    const ArkUI_AttributeItem* attrItem = nativeModule_->getAttribute(handle_, NODE_TEXT_AREA_TEXT);

                    if (!attrItem) {
                        printf("GetText error: getAttribute return null!");
                        return nullptr;
                    }

                    return attrItem->string;
                }

                /**
                * @brief 设置输入过滤正则表达式（仅匹配单个字符）
                * @param regex 正则表达式字符串
                */
                void SetInputFilter(const char* regex) {
                    assert(handle_);
                    ArkUI_AttributeItem item = {};
                    item.string = const_cast<char*>(regex);
                    nativeModule_->setAttribute(handle_, NODE_TEXT_AREA_INPUT_FILTER, &item);
                }

                // ===================== 基础数值属性（i32/u32/f32） =====================
                /**
                * @brief 设置最大输入字符数
                * @param maxLength 最大字符数（如100表示最多输入100个字符）
                */
                void SetMaxLength(int32_t maxLength) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.i32 = maxLength}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_TEXT_AREA_MAX_LENGTH, &item);
                }

                /**
                * @brief 设置占位符文本颜色（0xARGB格式）
                * @param color ARGB颜色值（如0xFF999999表示灰色）
                */
                void SetPlaceholderColor(uint32_t color) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.u32 = color}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_TEXT_AREA_PLACEHOLDER_COLOR, &item);
                }

                /**
                * @brief 设置光标颜色（0xARGB格式）
                * @param color ARGB颜色值
                */
                void SetCaretColor(uint32_t color) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.u32 = color}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_TEXT_AREA_CARET_COLOR, &item);
                }

                /**
                * @brief 设置文本选中背景色（0xARGB格式）
                * @param color ARGB颜色值
                */
                void SetSelectedBackgroundColor(uint32_t color) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.u32 = color}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_TEXT_AREA_SELECTED_BACKGROUND_COLOR, &item);
                }

                /**
                * @brief 设置文本框是否可编辑
                * @param isEditing true(1)可编辑，false(0)不可编辑
                */
                void SetEditing(int32_t isEditing) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.i32 = isEditing}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_TEXT_AREA_EDITING, &item);
                }

                /**
                * @brief 设置文本框类型
                * @param type 文本框类型（ArkUI_TextAreaType枚举值）
                */
                void SetType(ArkUI_TextAreaType type) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.i32 = type}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_TEXT_AREA_TYPE, &item);
                }

                /**
                * @brief 设置是否隐藏文本选择菜单
                * @param isHidden true(1)隐藏，false(0)显示
                */
                void SetSelectionMenuHidden(int32_t isHidden) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.i32 = isHidden}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_TEXT_AREA_SELECTION_MENU_HIDDEN, &item);
                }

                /**
                * @brief 设置回车提交后是否失去焦点
                * @param blurOnSubmit true(1)失去焦点，false(0)不失去
                */
                void SetBlurOnSubmit(int32_t blurOnSubmit) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.i32 = blurOnSubmit}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_TEXT_AREA_BLUR_ON_SUBMIT, &item);
                }

                /**
                * @brief 设置回车键类型
                * @param type 回车键类型（ArkUI_EnterKeyType枚举值）
                */
                void SetEnterKeyType(ArkUI_EnterKeyType type) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.i32 = type}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_TEXT_AREA_ENTER_KEY_TYPE, &item);
                }

                /**
                * @brief 设置获焦时是否启用输入法
                * @param enable true(1)启用，false(0)禁用
                */
                void SetEnableKeyboardOnFocus(int32_t enable) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.i32 = enable}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_TEXT_AREA_ENABLE_KEYBOARD_ON_FOCUS, &item);
                }

                /**
                * @brief 设置光标偏移量
                * @param offset 偏移量数值
                */
                void SetCaretOffset(int32_t offset) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.i32 = offset}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_TEXT_AREA_CARET_OFFSET, &item);
                }

                /**
                * @brief 设置文本选中区域（起始/结束位置）
                * @param start 选中起始位置
                * @param end 选中结束位置
                */
                void SetTextSelection(int32_t start, int32_t end) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.i32 = start}, {.i32 = end}};
                    ArkUI_AttributeItem item = {value, 2};
                    nativeModule_->setAttribute(handle_, NODE_TEXT_AREA_TEXT_SELECTION, &item);
                }

                /**
                * @brief 设置是否启用自动填充
                * @param enable true(1)启用，false(0)禁用
                */
                void SetEnableAutoFill(int32_t enable) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.i32 = enable}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_TEXT_AREA_ENABLE_AUTO_FILL, &item);
                }

                /**
                * @brief 设置自动填充类型
                * @param type 填充类型（ArkUI_TextInputContentType枚举值）
                */
                void SetContentType(ArkUI_TextInputContentType type) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.i32 = type}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_TEXT_AREA_CONTENT_TYPE, &item);
                }

                /**
                * @brief 设置获焦时是否弹出键盘
                * @param show true(1)弹出，false(0)不弹出
                */
                void SetShowKeyboardOnFocus(int32_t show) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.i32 = show}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_TEXT_AREA_SHOW_KEYBOARD_ON_FOCUS, &item);
                }

                /**
                * @brief 设置文本框行数（用于计算高度）
                * @param lines 行数（如3表示高度适配3行文本）
                */
                void SetNumberOfLines(int32_t lines) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.i32 = lines}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_TEXT_AREA_NUMBER_OF_LINES, &item);
                }

                /**
                * @brief 设置字符间距（API 15+，单位fp）
                * @param spacing 字符间距（如1.5表示间距1.5fp）
                */
                void SetLetterSpacing(float spacing) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.f32 = spacing}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_TEXT_AREA_LETTER_SPACING, &item);
                }

                /**
                * @brief 设置是否启用文本预览（API 15+）
                * @param enable true(1)启用，false(0)禁用
                */
                void SetEnablePreviewText(int32_t enable) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.i32 = enable}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_TEXT_AREA_ENABLE_PREVIEW_TEXT, &item);
                }

                /**
                * @brief 设置文本是否垂直居中（API 18+）
                * @param center true(1)居中，false(0)不居中
                */
                void SetHalfLeading(int32_t center) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.i32 = center}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_TEXT_AREA_HALF_LEADING, &item);
                }

                /**
                * @brief 设置键盘样式（API 15+）
                * @param style 键盘样式（ArkUI_KeyboardAppearanceType枚举值）
                */
                void SetKeyboardAppearance(ArkUI_KeyboardAppearance style) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.i32 = style}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_TEXT_AREA_KEYBOARD_APPEARANCE, &item);
                }

                // ===================== 复杂多参数属性 =====================
                /**
                * @brief 设置占位符文本字体样式
                * @param fontSize 字体大小（fp，可选，-1则用默认16.0）
                * @param fontStyle 字体样式（ArkUI_FontStyle，可选，-1则用默认NORMAL）
                * @param fontWeight 字体粗细（ArkUI_FontWeight，可选，-1则用默认NORMAL）
                * @param fontFamily 字体家族（可选，如"SimHei, Microsoft YaHei"）
                */
                void SetPlaceholderFont(float fontSize = -1.0f, int32_t fontStyle = -1,
                                        int32_t fontWeight = -1, const char* fontFamily = nullptr) {
                    assert(handle_);
                    std::vector<ArkUI_NumberValue> values;

                    // 添加可选数值参数
                    if (fontSize >= 0) values.push_back({.f32 = fontSize});
                    if (fontStyle >= 0) values.push_back({.i32 = fontStyle});
                    if (fontWeight >= 0) values.push_back({.i32 = fontWeight});

                    // 构建属性项
                    ArkUI_AttributeItem item = {};
                    if (!values.empty()) {
                        item.value = values.data();
                        item.size = values.size();
                    }
                    if (fontFamily != nullptr) {
                        item.string = const_cast<char*>(fontFamily);
                    }

                    nativeModule_->setAttribute(handle_, NODE_TEXT_AREA_PLACEHOLDER_FONT, &item);
                }

                /**
                * @brief 设置字符计数器显示规则
                * @param showCounter true(1)显示计数器，false(0)不显示
                * @param threshold 阈值百分比（1-100，可选，-1则不设置）
                * @param highlightBorder true(1)达到最大字符时高亮边框，false(0)不高亮（可选，-1则用默认true）
                */
                void SetShowCounter(int32_t showCounter, float threshold = -1.0f, int32_t highlightBorder = -1) {
                    assert(handle_);
                    std::vector<ArkUI_NumberValue> values;
                    values.push_back({.i32 = showCounter});  // 必选参数：是否显示计数器

                    // 添加可选参数
                    if (threshold >= 1.0f && threshold <= 100.0f) {
                        values.push_back({.f32 = threshold});
                    }
                    if (highlightBorder >= 0) {
                        values.push_back({.i32 = highlightBorder});
                    }

                    // 设置属性
                    ArkUI_AttributeItem item = {values.data(), static_cast<int32_t>(values.size())};
                    nativeModule_->setAttribute(handle_, NODE_TEXT_AREA_SHOW_COUNTER, &item);
                }
            };
        }  // namespace NativeModule

        // 外部C接口，供外部调用
        extern "C" {
            using namespace NativeModule;

            std::shared_ptr<ArkUIBaseNode> CreateTextArea() {
                auto column = std::make_shared<ArkUIColumnNode>();
                column->SetBorderWidth(1);
                column->SetPercentWidth(1);
                column->SetCornerRadius(20);
                column->SetBorderColor(0xFFefefef);
                column->SetShadowStyle(ARKUI_SHADOW_STYLE_OUTER_DEFAULT_MD);
                auto title = std::make_shared<ArkUITextNode>();
                title->SetTextContent(\"{% info.title %}\");
                title->SetFontSize(18);
                title->SetPercentWidth(1);
                title->SetPadding(15, 0.0, 10, 15);
                title->SetFontWeight(ARKUI_FONT_WEIGHT_W600);
                column->AddChild(title);

                auto textAreaNode = std::make_shared<ArkUITextAreaNode>();
                textAreaNode->SetPlaceholder("请输入详细描述...");  // 占位符
                textAreaNode->SetPercentWidth(0.9);
                textAreaNode->SetHeight(120);
                textAreaNode->SetMargin(10, 10, 10, 10);
                textAreaNode->SetMaxLength(200);                    // 最大字符数200
                textAreaNode->SetPlaceholderColor(0xFF999999);      // 占位符灰色
                textAreaNode->SetCaretColor(0xFF0088FF);            // 光标蓝色

                textAreaNode->SetEditing(1);                        // 可编辑
                textAreaNode->SetEnterKeyType(ARKUI_ENTER_KEY_TYPE_SEND);  // 回车为“发送”
                textAreaNode->SetLetterSpacing(0.5f);
                auto onTextAreaChange = [textAreaNode](ArkUI_NodeEvent *event) {
                    // 从组件事件中获取基础事件对象
                    auto *inputEvent = OH_ArkUI_NodeEvent_GetInputEvent(event);
                    // 从组件事件获取事件类型
                    auto eventType = OH_ArkUI_NodeEvent_GetEventType(event);
                    switch (eventType) {
                        case NODE_TEXT_AREA_ON_CHANGE: {
                            g_click_callback(\"{% info.title %}\", textAreaNode->GetText());
                        }
                        default: {
                            break;
                        }
                    }
                };
                textAreaNode->RegisterOnTextAreaChange(onTextAreaChange);
                column->AddChild(textAreaNode);
                column->SetMargin(0, 0, 20, 0);
                return column;
            }
        }  // extern "C"
    '''
}
package magic.ui.arkui

import magic.dsl.*
import magic.prelude.*
import magic.jsonable.*
import std.collection.*
import stdx.encoding.json.{JsonValue, JsonObject, JsonException, JsonKind, JsonInt, JsonString, JsonBool, JsonFloat, JsonArray, JsonNull}

@jsonable
public class ListInfo {
    @field["The theme to be presented"]
    let title: String
    @field["The data information to be displayed, double quotation marks are prohibited"]
    let data: Array<String>
}

@ui[
    description: "纯文本列表：以纯文字为核心的结构化列表，适配步骤、说明等纯文本展示场景",
    lang: "arkui",
    kind: "display"
]
public func template_text_list(info: ListInfo) {
    '''
        namespace NativeModule {
            // 列表项节点类
            class ArkUIListItemNode : public ArkUINode {
            public:
                ArkUIListItemNode()
                    : ArkUINode((NativeModuleInstance::GetInstance()->GetNativeNodeAPI())->createNode(ARKUI_NODE_LIST_ITEM)) {}
            };

            // 列表节点类
            class ArkUIListNode : public ArkUINode {
            public:
                ArkUIListNode()
                    : ArkUINode((NativeModuleInstance::GetInstance()->GetNativeNodeAPI())->createNode(ARKUI_NODE_LIST)) {} // 创建ArkUI的列表组件。

                ~ArkUIListNode() override {}
                // List组件的属性NDK接口封装。
                void SetScrollBarState(bool isShow) {
                    assert(handle_);
                    ArkUI_ScrollBarDisplayMode displayMode =
                        isShow ? ARKUI_SCROLL_BAR_DISPLAY_MODE_ON : ARKUI_SCROLL_BAR_DISPLAY_MODE_OFF;
                    ArkUI_NumberValue value[] = {{.i32 = displayMode}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_SCROLL_BAR_DISPLAY_MODE, &item);
                }

                void SetListItemAlignment(ArkUI_ListItemAlignment alignment) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.i32 = static_cast<int32_t>(alignment)}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_LIST_ALIGN_LIST_ITEM, &item);
                }
            };
        }  // namespace NativeModule

        // 外部C接口，供外部调用
        extern "C" {
            using namespace NativeModule;

            std::shared_ptr<ArkUIColumnNode> createColumnNode(std::string text) {
                auto content = std::make_shared<ArkUITextNode>();
                auto column = std::make_shared<ArkUIColumnNode>();
                content->SetTextContent(text);
                content->SetFontSize(16);
                content->SetPercentWidth(1);
                content->SetPadding(10, 10, 10, 10);
                column->AddChild(content);
                return column;
            }

            std::shared_ptr<ArkUIListItemNode> createListItem(int32_t index, std::string content) {
                auto listItem = std::make_shared<ArkUIListItemNode>();
                auto textNode = createColumnNode(content);
                listItem->InsertChild(textNode, index);
                listItem->SetCornerRadius(13);
                listItem->SetBorderColor(0xFFEFEFEF);
                listItem->SetBorderWidth(1.0);
                listItem->SetMargin(0.0, 0.0, 15.0, 0.0);
                listItem->SetBackgroundColor(0x25E8E8E8);
                return listItem;
            }

            std::shared_ptr<ArkUIBaseNode> CreateTextListExample() {
                auto column = std::make_shared<ArkUIColumnNode>();
                auto title = std::make_shared<ArkUITextNode>();
                title->SetTextContent(\"{% info.title %}\");
                title->SetFontSize(20);
                title->SetPercentWidth(1);
                title->SetPadding(15, 0, 10, 05);
                title->SetFontWeight(ARKUI_FONT_WEIGHT_W600);

                auto list = std::make_shared<ArkUIListNode>();
                list->SetPercentWidth(1);
                list->SetScrollBarState(true);

                {% for (index, item) in enumerate(info.data) %}
                {
                    auto listItem = createListItem({% index %}, \"{% item %}\");
                    list->AddChild(listItem);
                }
                {% /for %}

                column->AddChild(title);
                column->AddChild(list);
                column->SetMargin(0, 0, 15, 0);
                return column;
            }
        }  // extern "C"
    '''
}
package magic.ui

import std.regex.*
import std.collection.*

public class ArkUIComponent {
    var code: String = ""
    var head: String = ""
    var nativeModule: String = ""
    var UINode: String = ""
    var mainFunc: String = ""

    public ArkUIComponent(let template: String, let index: Int64) {
        this.nativeModule = ""
        this.UINode = ""
        this.code = template
        // 提取 #include 语句
        extractIncludes(code)

        // 提取 NativeModule 命名空间中的类
        extractNativeModuleClass(code, index)

        // 提取 extern "C" 中的函数
        extractExternCFunctions(code, index)
    }

    // 提取#include语句
    func extractIncludes(content: String) {
        let includePattern = Regex("#include\\s*[<\"](.*?)[>\"]")
        let matches = includePattern.findAll(content)

        for (m in matches) {
            if (head.isEmpty()) {
                head = m.matchString(0)
            } else {
                head = "${head}\n${m.matchString(0)}"
            }
        }
    }

    // 提取namespace NativeModule中的类并添加索引后缀
    func extractNativeModuleClass(content: String, index: Int64) {
        let nativeModulePattern = Regex("namespace\\s+NativeModule\\s*\\{((?:[^{}]++|\\{(?1)\\})*)\\}")
        // let nativeModulePattern = Regex("namespace\\s+NativeModule\\s*\\{\\s*([\\s\\S]*?)\\s*\\}\\s*//\\s*namespace NativeModule")
        let nativeModuleMatch = nativeModulePattern.find(content)
        match (nativeModuleMatch) {
            case Some(r) =>
                var classContent = r.matchString(0)
                // 查找类名并添加索引后缀
                let classPattern = Regex("class\\s+(\\w+)")
                let classMatches = classPattern.findAll(classContent)
                if (index !=0) {
                    for (classMatch in classMatches) {
                        let originalClassName = classMatch.matchString(0).split(" ")[1]
                        let newClassName = "${originalClassName}_${index}"
                        // 替换类名
                        classContent = classContent.replace(originalClassName, newClassName)
                        this.code = this.code.replace(originalClassName, newClassName)
                    }
                }
                this.nativeModule = "${classContent}"
            case None =>
                // 没有找到匹配内容，保持为空
                this.nativeModule = ""
        }
    }

    func removeLastParen(s: String): String {
        if (s.size == 0) {
            return s
        }
        let runes = s.toRuneArray()
        let last = runes[runes.size - 1]
        if (last == r'(') {
            var result = ""
            for (i in 0..runes.size - 1) {
                result = result + String(runes[i])
            }
            return result
        } else {
            return s
        }
    }

    // 提取extern "C"中的函数并处理类名和函数名
    func extractExternCFunctions(content: String, index: Int64) {
        let externPattern = Regex("extern\\s+\\\"C\\\"\\s*\\{((?:[^{}]++|\\{(?1)\\})*)\\}")
        let externMatch = externPattern.find(content)
        match (externMatch) {
            case Some(r) =>
                var externContent = r.matchString(0)
                // 提取函数定义
                // let functionPattern = Regex("(?m)^[\\s\\w:*&<>]+\\s+(\\w+)\\s*\\([^)]*\\)\\s*\\{(?:[^{}]*|\\{[^{}]*\\})*\\}")
                let functionPattern = Regex("(?ms)^[\\s\\w:<>,*&]+?\\s+(\\w+)\\s*\\([^()]*\\)\\s*\\{(?:[^{}]|(\\{(?:[^{}]|(?2))*\\}))*\\}")
                let functionMatches = functionPattern.findAll(externContent)
                var modifiedFunctions = ""
                if (index !=0) {
                    for (funcMatch in functionMatches) {
                        var funcContent = funcMatch.matchString(0)
                        // 提取函数名
                        let funcNamePattern = Regex("[\\s\\w:*&<>]+?\\s+(\\w+)\\s*\\(")
                        let funcNameMatch = funcNamePattern.find(funcContent)
                        match (funcNameMatch) {
                            case Some(nameMatch) =>
                                var originalFuncName = removeLastParen(nameMatch.matchString(0))
                                // 添加到调用列表
                                let originalFuncNameArr = originalFuncName.split(" ")
                                originalFuncName = originalFuncNameArr[originalFuncNameArr.size - 1]
                                if (externContent.count(originalFuncName) == 1) {
                                    mainFunc = "${originalFuncName}_${index}"
                                }
                                externContent = externContent.replace(originalFuncName, "${originalFuncName}_${index}")
                            case _ => ()
                                // 没有找到函数名，跳过处理
                        }
                    }
                }
                let subStr = 'g_click_callback('
                let pos = externContent.indexOf(subStr)
                if (pos.isSome()) {
                    let endPos = pos.getOrThrow() + subStr.size
                    externContent = externContent[0..endPos] + "${index}, " + externContent[endPos..]
                }
                UINode = externContent
            case None =>
                // 没有找到extern "C"块，保持为空
                UINode = ""
        }
    }

    public func getHead(): String {
        return head
    }

    public func getNativeModule(): String {
        return nativeModule
    }

    public func getUINode(): String {
        return UINode
    }

    public func getMainFunc(): String {
        return mainFunc
    }
}

public func mergeArkUIComponents(title: String, components: ArrayList<ArkUIComponent>, mode: String): String {
    var common = '''
        #include "napi/native_api.h"
        #include <arkui/native_node.h>
        #include <arkui/native_interface.h>
        #include <arkui/native_type.h>
        #include <hilog/log.h>
        #include <cassert>
        #include <list>
        #include <memory>
        #include <string>

        // 命名空间封装所有实现
        namespace NativeModule {
            // NativeModule单例类，提供NDK接口访问
            class NativeModuleInstance {
            public:
                static NativeModuleInstance* GetInstance() {
                    static NativeModuleInstance instance;
                    return &instance;
                }

                NativeModuleInstance() {
                    OH_ArkUI_GetModuleInterface(ARKUI_NATIVE_NODE, ArkUI_NativeNodeAPI_1, arkUINativeNodeApi_);
                    assert(arkUINativeNodeApi_);
                }

                ArkUI_NativeNodeAPI_1* GetNativeNodeAPI() { return arkUINativeNodeApi_; }

            private:
                ArkUI_NativeNodeAPI_1* arkUINativeNodeApi_ = nullptr;
            };

            // 基础节点类
            class ArkUIBaseNode {
            public:
                explicit ArkUIBaseNode(ArkUI_NodeHandle handle)
                    : handle_(handle), nativeModule_(NativeModuleInstance::GetInstance()->GetNativeNodeAPI()) {}

                virtual ~ArkUIBaseNode() {
                    if (!children_.empty()) {
                        for (const auto& child : children_) {
                            nativeModule_->removeChild(handle_, child->GetHandle());
                        }
                        children_.clear();
                    }
                    nativeModule_->disposeNode(handle_);
                }

                void AddChild(const std::shared_ptr<ArkUIBaseNode>& child) {
                    children_.emplace_back(child);
                    OnAddChild(child);
                }

                void RemoveChild(const std::shared_ptr<ArkUIBaseNode>& child) {
                    children_.remove(child);
                    OnRemoveChild(child);
                }

                void InsertChild(const std::shared_ptr<ArkUIBaseNode>& child, int32_t index) {
                    if (index >= children_.size()) {
                        AddChild(child);
                    } else {
                        auto iter = children_.begin();
                        std::advance(iter, index);
                        children_.insert(iter, child);
                        OnInsertChild(child, index);
                    }
                }

                ArkUI_NodeHandle GetHandle() const { return handle_; }

            protected:
                virtual void OnAddChild(const std::shared_ptr<ArkUIBaseNode>& child) {}
                virtual void OnRemoveChild(const std::shared_ptr<ArkUIBaseNode>& child) {}
                virtual void OnInsertChild(const std::shared_ptr<ArkUIBaseNode>& child, int32_t index) {}

                ArkUI_NodeHandle handle_;
                ArkUI_NativeNodeAPI_1* nativeModule_ = nullptr;

            private:
                std::list<std::shared_ptr<ArkUIBaseNode>> children_;
            };

            class ArkUINode : public ArkUIBaseNode {
            public:
                explicit ArkUINode(ArkUI_NodeHandle handle) : ArkUIBaseNode(handle) {
                    nativeModule_ = NativeModuleInstance::GetInstance()->GetNativeNodeAPI();
                    // 事件触发时需要通过函数获取对应的事件对象，这边通过设置节点自定义数据将封装类指针保持在组件上，方便后续事件分发。
                    nativeModule_->setUserData(handle_, this);
                    // 注册节点监听事件接受器。
                    nativeModule_->addNodeEventReceiver(handle_, ArkUINode::NodeEventReceiver);
                }

                ~ArkUINode() override {
                    if (onClick_) {
                        nativeModule_->unregisterNodeEvent(handle_, NODE_ON_CLICK_EVENT);
                    }
                    if (&onTextAreaChange_) {
                        nativeModule_->unregisterNodeEvent(handle_, NODE_TEXT_AREA_ON_CHANGE);
                    }
                    if (&onCheckboxChange_) {
                        nativeModule_->unregisterNodeEvent(handle_, NODE_CHECKBOX_EVENT_ON_CHANGE);
                    }
                    if (&onDatePickChange_) {
                        nativeModule_->unregisterNodeEvent(handle_, NODE_DATE_PICKER_EVENT_ON_DATE_CHANGE);
                    }
                    if (&onTimePickChange_) {
                        nativeModule_->unregisterNodeEvent(handle_, NODE_TIME_PICKER_EVENT_ON_CHANGE);
                    }
                    if (&onCalendarPickChange_) {
                        nativeModule_->unregisterNodeEvent(handle_, NODE_CALENDAR_PICKER_EVENT_ON_CHANGE);
                    }
                    nativeModule_->removeNodeEventReceiver(handle_, ArkUINode::NodeEventReceiver);
                }

                void SetWidth(float width) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.f32 = width}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_WIDTH, &item);
                }
                void SetPercentWidth(float percent) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.f32 = percent}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_WIDTH_PERCENT, &item);
                }
                void SetHeight(float height) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.f32 = height}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_HEIGHT, &item);
                }
                void SetPercentHeight(float percent) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.f32 = percent}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_HEIGHT_PERCENT, &item);
                }
                void SetBackgroundColor(uint32_t color) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.u32 = color}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_BACKGROUND_COLOR, &item);
                }
                void SetPadding(float top, float right, float bottom, float left) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {
                        {.f32 = top},
                        {.f32 = right},
                        {.f32 = bottom},
                        {.f32 = left}
                    };
                    ArkUI_AttributeItem item = {value, 4};
                    nativeModule_->setAttribute(handle_, NODE_PADDING, &item);
                }
                void SetMargin(float top, float right, float bottom, float left) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {
                        {.f32 = top},
                        {.f32 = right},
                        {.f32 = bottom},
                        {.f32 = left}
                    };
                    ArkUI_AttributeItem item = {value, 4};
                    nativeModule_->setAttribute(handle_, NODE_MARGIN, &item);
                }
                void SetCornerRadius(float radius) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.f32 = radius}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_BORDER_RADIUS, &item);
                }
                void SetBorderWidth(float width) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.f32 = width}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_BORDER_WIDTH, &item);
                }
                void SetBorderColor(uint32_t color) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.u32 = color}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_BORDER_COLOR, &item);
                }
                void SetAlignment(ArkUI_Alignment alignment) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.i32 = static_cast<int32_t>(alignment)}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_ALIGNMENT, &item);
                }
                void SetShadowStyle(ArkUI_ShadowStyle style) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.i32 = static_cast<int32_t>(style)}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_SHADOW, &item);
                }
                // 处理通用事件。
                void RegisterOnClick(const std::function<void(ArkUI_NodeEvent *event)> &onClick)
                {
                    if (!handle_) {
                        return;
                    }
                    onClick_ = onClick;
                    nativeModule_->registerNodeEvent(handle_, NODE_ON_CLICK_EVENT, 0, nullptr);
                }

                void RegisterOnCheckboxChange(const std::function<void(ArkUI_NodeEvent *event)> &onCheckboxChange)
                {
                    if (!handle_) {
                        return;
                    }
                    onCheckboxChange_ = onCheckboxChange;
                    nativeModule_->registerNodeEvent(handle_, NODE_CHECKBOX_EVENT_ON_CHANGE, 0, nullptr);
                }

                void RegisterOnTextAreaChange(const std::function<void(ArkUI_NodeEvent *event)> &onTextAreaChange)
                {
                    if (!handle_) {
                        return;
                    }
                    onTextAreaChange_ = onTextAreaChange;
                    nativeModule_->registerNodeEvent(handle_, NODE_TEXT_AREA_ON_CHANGE, 0, nullptr);
                }

                void RegisterOnDatePickerChange(const std::function<void(ArkUI_NodeEvent *event)> &onDatePickChange)
                {
                    if (!handle_) {
                        return;
                    }
                    onDatePickChange_ = onDatePickChange;
                    nativeModule_->registerNodeEvent(handle_, NODE_DATE_PICKER_EVENT_ON_DATE_CHANGE, 0, nullptr);
                }

                void RegisterOnSliderChange(const std::function<void(ArkUI_NodeEvent *event)> &onSliderChange)
                {
                    if (!handle_) {
                        return;
                    }
                    onSliderChange_ = onSliderChange;
                    nativeModule_->registerNodeEvent(handle_, NODE_SLIDER_EVENT_ON_CHANGE, 0, nullptr);
                }

                void RegisterOnTimePickerChange(const std::function<void(ArkUI_NodeEvent *event)> &onTimePickChange)
                {
                    if (!handle_) {
                        return;
                    }
                    onTimePickChange_ = onTimePickChange;
                    nativeModule_->registerNodeEvent(handle_, NODE_TIME_PICKER_EVENT_ON_CHANGE, 0, nullptr);
                }

                void RegisterOnCalendarPickerChange(const std::function<void(ArkUI_NodeEvent *event)> &onCalendarPickChange)
                {
                    if (!handle_) {
                        return;
                    }
                    onCalendarPickChange_ = onCalendarPickChange;
                    nativeModule_->registerNodeEvent(handle_, NODE_CALENDAR_PICKER_EVENT_ON_CHANGE, 0, nullptr);
                }

            protected:
                // 事件监听器函数指针。
                static void NodeEventReceiver(ArkUI_NodeEvent *event)
                {
                    // 获取事件发生的UI组件对象。
                    auto nodeHandle = OH_ArkUI_NodeEvent_GetNodeHandle(event);
                    // 获取保持在UI组件对象中的自定义数据，返回封装类指针。
                    auto *node = reinterpret_cast<ArkUINode *>(
                        NativeModuleInstance::GetInstance()->GetNativeNodeAPI()->getUserData(nodeHandle));
                    // 基于封装类实例对象处理事件。
                    node->ProcessNodeEvent(event);
                }
                void ProcessNodeEvent(ArkUI_NodeEvent *event)
                {
                    auto eventType = OH_ArkUI_NodeEvent_GetEventType(event);
                    switch (eventType) {
                        case NODE_ON_CLICK_EVENT: {
                            if (onClick_) {
                                onClick_(event);
                            }
                            break;
                        }
                        case NODE_CHECKBOX_EVENT_ON_CHANGE: {
                            if (onCheckboxChange_) {
                                onCheckboxChange_(event);
                            }
                            break;
                        }
                        case NODE_TEXT_AREA_ON_CHANGE: {
                            if (onTextAreaChange_) {
                                onTextAreaChange_(event);
                            }
                            break;
                        }
                        case NODE_DATE_PICKER_EVENT_ON_DATE_CHANGE: {
                            if (onDatePickChange_) {
                                onDatePickChange_(event);
                            }
                            break;
                        }
                        case NODE_SLIDER_EVENT_ON_CHANGE: {
                            if (onSliderChange_) {
                                onSliderChange_(event);
                            }
                            break;
                        }
                        case NODE_TIME_PICKER_EVENT_ON_CHANGE: {
                            if (onTimePickChange_) {
                                onTimePickChange_(event);
                            }
                            break;
                        }
                        case NODE_CALENDAR_PICKER_EVENT_ON_CHANGE: {
                            if (onCalendarPickChange_) {
                                onCalendarPickChange_(event);
                            }
                            break;
                        }

                        default: {
                            // 组件特有事件交给子类处理
                            OnNodeEvent(event);
                        }
                    }
                }

                virtual void OnNodeEvent(ArkUI_NodeEvent *event) {}
                // 组件树操作的实现类对接。
                void OnAddChild(const std::shared_ptr<ArkUIBaseNode> &child) override {
                    nativeModule_->addChild(handle_, child->GetHandle());
                }
                void OnRemoveChild(const std::shared_ptr<ArkUIBaseNode> &child) override {
                    nativeModule_->removeChild(handle_, child->GetHandle());
                }
                void OnInsertChild(const std::shared_ptr<ArkUIBaseNode> &child, int32_t index) override {
                    nativeModule_->insertChildAt(handle_, child->GetHandle(), index);
                }
            private:
                std::function<void(ArkUI_NodeEvent *event)> onClick_;
                std::function<void(ArkUI_NodeEvent *event)> onSliderChange_;
                std::function<void(ArkUI_NodeEvent *event)> onTextAreaChange_;
                std::function<void(ArkUI_NodeEvent *event)> onCheckboxChange_;
                std::function<void(ArkUI_NodeEvent *event)> onDatePickChange_;
                std::function<void(ArkUI_NodeEvent *event)> onTimePickChange_;
                std::function<void(ArkUI_NodeEvent *event)> onCalendarPickChange_;
            };

            class ArkUITextNode : public ArkUINode {
            public:
                ArkUITextNode()
                    : ArkUINode((NativeModuleInstance::GetInstance()->GetNativeNodeAPI())->createNode(ARKUI_NODE_TEXT)) {}
                void SetFontSize(float fontSize) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.f32 = fontSize}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_FONT_SIZE, &item);
                }
                void SetFontWeight(ArkUI_FontWeight weight) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.i32 = static_cast<int32_t>(weight)}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_FONT_WEIGHT, &item);
                }
                void SetFontColor(uint32_t color) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.u32 = color}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_FONT_COLOR, &item);
                }
                void SetTextContent(const std::string &content) {
                    assert(handle_);
                    ArkUI_AttributeItem item = {nullptr, 0, content.c_str()};
                    nativeModule_->setAttribute(handle_, NODE_TEXT_CONTENT, &item);
                }
                void SetTextAlign(ArkUI_TextAlignment align) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.i32 = align}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_TEXT_ALIGN, &item);
                }
            };

            class ArkUIRowNode : public ArkUINode {
            public:
                ArkUIRowNode()
                    : ArkUINode((NativeModuleInstance::GetInstance()->GetNativeNodeAPI())->createNode(ARKUI_NODE_ROW)) {}

                void SetJustifyContent(ArkUI_FlexAlignment align) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.i32 = align}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_ROW_JUSTIFY_CONTENT, &item);
                }
                void SetAlignItems(ArkUI_ItemAlignment align) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.i32 = align}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_ROW_ALIGN_ITEMS, &item);
                }
            };

            class ArkUIColumnNode : public ArkUINode {
            public:
                ArkUIColumnNode()
                    : ArkUINode((NativeModuleInstance::GetInstance()->GetNativeNodeAPI())->createNode(ARKUI_NODE_COLUMN)) {}

                void SetJustifyContent(ArkUI_FlexAlignment align) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.i32 = align}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_COLUMN_JUSTIFY_CONTENT, &item);
                }
                void SetAlignItems(ArkUI_ItemAlignment align) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.i32 = align}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_COLUMN_ALIGN_ITEMS, &item);
                }
            };

            class ArkUIGridNode : public ArkUINode {
            public:
                ArkUIGridNode()
                    : ArkUINode((NativeModuleInstance::GetInstance()->GetNativeNodeAPI())->createNode(ARKUI_NODE_GRID)) {}

                void SetColumnTemplate(const std::string& templateStr) {
                    assert(handle_);
                    ArkUI_AttributeItem item = {};
                    item.string = const_cast<char*>(templateStr.c_str()); // 注意字符串生命周期
                    nativeModule_->setAttribute(handle_, NODE_GRID_COLUMN_TEMPLATE, &item);
                }
                void SetRowTemplate(const std::string& templateStr) {
                    assert(handle_);
                    ArkUI_AttributeItem item = {};
                    item.string = const_cast<char*>(templateStr.c_str()); // 注意字符串生命周期
                    nativeModule_->setAttribute(handle_, NODE_GRID_ROW_TEMPLATE, &item);
                }
                void SetColumnGap(float gap) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.f32 = gap}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_GRID_COLUMN_GAP, &item);
                }
                void SetRowGap(float gap) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.f32 = gap}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_GRID_ROW_GAP, &item);
                }
                void SetNodeAdapter(const ArkUI_NodeAdapter& adapter) {
                    assert(handle_);
                    ArkUI_AttributeItem item = {};
                    item.object = const_cast<ArkUI_NodeAdapter*>(&adapter); // 注意适配器对象生命周期
                    nativeModule_->setAttribute(handle_, NODE_GRID_NODE_ADAPTER, &item);
                }
                void SetCachedCount(int32_t count) {
                    assert(handle_);
                    ArkUI_NumberValue value[] = {{.i32 = count}};
                    ArkUI_AttributeItem item = {value, 1};
                    nativeModule_->setAttribute(handle_, NODE_GRID_CACHED_COUNT, &item);
                }
                void SetColumns(int32_t columns) {
                    assert(handle_);
                    std::string templateStr = "repeat(" + std::to_string(columns) + ", 1fr)";
                    SetColumnTemplate(templateStr);
                }
                void SetRowSpacing(float spacing) {
                    SetRowGap(spacing);
                }
                void SetColumnSpacing(float spacing) {
                    SetColumnGap(spacing);
                }
            };

            class ArkUIGridItemNode : public ArkUINode {
            public:
                ArkUIGridItemNode()
                    : ArkUINode((NativeModuleInstance::GetInstance()->GetNativeNodeAPI())->createNode(ARKUI_NODE_GRID_ITEM)) {}
            };

            class ArkUIFlexNode : public ArkUINode {
            public:
                // 构造函数：与 ArkUIRowNode 完全一致的格式
                ArkUIFlexNode()
                    : ArkUINode((NativeModuleInstance::GetInstance()->GetNativeNodeAPI())->createNode(ARKUI_NODE_FLEX)) {}

                /**
                * @brief 设置Flex布局属性（唯一入口，匹配 NODE_FLEX_OPTION 规范）
                * @param direction 主轴方向（默认：ROW）
                * @param wrap 换行方式（默认：NO_WRAP）
                * @param justifyContent 主轴对齐（默认：START）
                * @param alignItems 交叉轴对齐（默认：START）
                * @param alignContent 多行文交叉轴对齐（默认：START）
                */
                void SetFlexOption(
                    ArkUI_FlexDirection direction = ArkUI_FlexDirection::ARKUI_FLEX_DIRECTION_ROW,
                    ArkUI_FlexWrap wrap = ArkUI_FlexWrap::ARKUI_FLEX_WRAP_NO_WRAP,
                    ArkUI_FlexAlignment justifyContent = ArkUI_FlexAlignment::ARKUI_FLEX_ALIGNMENT_START,
                    ArkUI_ItemAlignment alignItems = ArkUI_ItemAlignment::ARKUI_ITEM_ALIGNMENT_START,
                    ArkUI_FlexAlignment alignContent = ArkUI_FlexAlignment::ARKUI_FLEX_ALIGNMENT_START
                ) {
                    assert(handle_); // 与 ArkUIRowNode 保持一致的句柄校验

                    // 严格按官方顺序填充 value 数组（5个参数一一对应）
                    ArkUI_NumberValue value[] = {
                        {.i32 = static_cast<int32_t>(direction)},    // value[0]：主轴方向
                        {.i32 = static_cast<int32_t>(wrap)},         // value[1]：换行方式
                        {.i32 = static_cast<int32_t>(justifyContent)}, // value[2]：主轴对齐
                        {.i32 = static_cast<int32_t>(alignItems)},   // value[3]：交叉轴对齐
                        {.i32 = static_cast<int32_t>(alignContent)}  // value[4]：多行文交叉轴对齐
                    };

                    // 构造 AttributeItem（size=5，与 value 数组长度一致）
                    ArkUI_AttributeItem item = {value, 5};

                    // 调用 setAttribute：仅使用 NODE_FLEX_OPTION 一个属性
                    nativeModule_->setAttribute(handle_, NODE_FLEX_OPTION, &item);
                }

                /**
                * @brief 快捷方法：仅设置「方向+换行」（解决 filterList 换行核心需求）
                *        其他属性沿用官方默认值，减少调用复杂度
                */
                void SetFlexDirectionAndWrap(ArkUI_FlexDirection direction, ArkUI_FlexWrap wrap) {
                    // 仅覆盖方向和换行，其余用默认值
                    SetFlexOption(direction, wrap);
                }

                /**
                * @brief 快捷方法：仅设置换行（最常用场景）
                */
                void SetFlexWrap(ArkUI_FlexWrap wrap) {
                    // 方向用默认ROW，仅修改换行方式
                    SetFlexOption(ArkUI_FlexDirection::ARKUI_FLEX_DIRECTION_ROW, wrap);
                }

                /**
                * @brief 快捷方法：仅设置主轴对齐（仿照 ArkUIRowNode 的 SetJustifyContent）
                */
                void SetJustifyContent(ArkUI_FlexAlignment align) {
                    // 仅覆盖主轴对齐，其余用默认值
                    SetFlexOption(
                        ArkUI_FlexDirection::ARKUI_FLEX_DIRECTION_ROW,
                        ArkUI_FlexWrap::ARKUI_FLEX_WRAP_NO_WRAP,
                        align // 仅修改主轴对齐
                    );
                }

                /**
                * @brief 快捷方法：仅设置交叉轴对齐（仿照 ArkUIRowNode 的 SetAlignItems）
                */
                void SetAlignItems(ArkUI_ItemAlignment align) {
                    // 仅覆盖交叉轴对齐，其余用默认值
                    SetFlexOption(
                        ArkUI_FlexDirection::ARKUI_FLEX_DIRECTION_ROW,
                        ArkUI_FlexWrap::ARKUI_FLEX_WRAP_NO_WRAP,
                        ArkUI_FlexAlignment::ARKUI_FLEX_ALIGNMENT_START,
                        align // 仅修改交叉轴对齐
                    );
                }
            };
        }  // namespace NativeModule
    '''

    let commonComponent = ArkUIComponent(common, 0)
    var head = commonComponent.getHead()
    var nativeModule = commonComponent.getNativeModule()
    var UINode = commonComponent.getUINode()
    var returnValue = ''
    var mainCode = match (mode) {
        case "Flex" =>
            returnValue = 'flex'
            '''
                auto flex = std::make_shared<ArkUIFlexNode>();
            '''
        case "Grid" =>
            returnValue = 'grid'
            '''
                auto grid = std::make_shared<ArkUIGridNode>();
                // grid->SetColumnTemplate("1fr 1fr 2fr");  // 3列，宽度占比1:1:2
                // grid->SetRowTemplate("1fr 1fr 2fr");     // 3行，高度占比1:1:2
            '''
        case _ =>
            returnValue = 'column'
            '''
                auto column = std::make_shared<ArkUIColumnNode>();
            '''
    }

    let titleComp = '''
        auto title = std::make_shared<ArkUITextNode>();
        title->SetTextContent("${title}");
        title->SetFontSize(22);
        title->SetPercentWidth(1);
        title->SetPadding(15, 15, 10, 15);
        title->SetFontWeight(ARKUI_FONT_WEIGHT_W600);
        title->SetTextAlign(ARKUI_TEXT_ALIGNMENT_CENTER);
    '''
    mainCode = mainCode + '\n' + titleComp + '\n' + '${returnValue}->AddChild(title);'

    for ((i, comp) in enumerate(components)) {
        head = head + '\n' + comp.getHead()
        nativeModule = nativeModule + '\n' + comp.getNativeModule()
        UINode = UINode + '\n' + comp.getUINode()
        mainCode = mainCode + '\n' + 'auto component_${i} = ${comp.getMainFunc()}();'  + '\n' + '${returnValue}->AddChild(component_${i});'
    }
    var resValue = 'typedef void (*ClickCallback)(int, std::string, std::string); \n static ClickCallback g_click_callback = nullptr;'
    var template = head + '\n' + resValue + '\n' + nativeModule + '\n'+ UINode
    template = template + '''
        extern "C" {
        using namespace NativeModule;

        void register_click_callback(ClickCallback callback) {
            g_click_callback = callback;
        }

        std::shared_ptr<ArkUIBaseNode> CreateArkUI() {
            ${mainCode}
            return ${returnValue};
        }
        }  // extern "C"
    '''
    return template
}

package magic.ui.arkui

import magic.dsl.*
import magic.prelude.*
import magic.jsonable.*
import std.collection.*
import stdx.encoding.json.{JsonValue, JsonObject, JsonException, JsonKind, JsonInt, JsonString, JsonBool, JsonFloat, JsonArray, JsonNull}

@jsonable
public class SliderInfo {
    @field["The title of the radio selection list"]
    let title: String
    @field["Maximum value"]
    public let maxValue: Int64
    @field["Minimum value"]
    public let minValue: Int64
}

@ui[
    description: "数值选择器：选择特定单个数值",
    lang: "arkui",
    kind: "input"
]
public func template_slider(info: SliderInfo) {
    '''
        namespace NativeModule {
            class ArkUISliderNode : public ArkUINode {
            public:
                // 构造函数：创建滑块节点，复用父类ArkUINode的初始化逻辑
                ArkUISliderNode()
                    : ArkUINode((NativeModuleInstance::GetInstance()->GetNativeNodeAPI())->createNode(ARKUI_NODE_SLIDER)) {}

                // ===================== 基础颜色属性 =====================
                /**
                * @brief 设置滑块（拖动按钮）的颜色
                * @param color 颜色值（0xARGB格式，如0xFF0088FF表示蓝色）
                */
                void SetBlockColor(uint32_t color) {
                    assert(handle_);
                    ArkUI_NumberValue valueArr[] = {{.u32 = color}};
                    ArkUI_AttributeItem item = {valueArr, 1};
                    nativeModule_->setAttribute(handle_, NODE_SLIDER_BLOCK_COLOR, &item);
                }

                /**
                * @brief 设置滑块轨道的背景颜色（未选中部分）
                * @param color 颜色值（0xARGB格式，如0xFFE0E0E0表示浅灰色）
                */
                void SetTrackColor(uint32_t color) {
                    assert(handle_);
                    ArkUI_NumberValue valueArr[] = {{.u32 = color}};
                    ArkUI_AttributeItem item = {valueArr, 1};
                    nativeModule_->setAttribute(handle_, NODE_SLIDER_TRACK_COLOR, &item);
                }

                /**
                * @brief 设置滑块轨道选中部分的颜色
                * @param color 颜色值（0xARGB格式，如0xFF0088FF表示蓝色）
                */
                void SetSelectedColor(uint32_t color) {
                    assert(handle_);
                    ArkUI_NumberValue valueArr[] = {{.u32 = color}};
                    ArkUI_AttributeItem item = {valueArr, 1};
                    nativeModule_->setAttribute(handle_, NODE_SLIDER_SELECTED_COLOR, &item);
                }

                // ===================== 数值相关属性 =====================
                /**
                * @brief 设置滑块当前值
                * @param value 当前值（需在min和max之间）
                */
                void SetValue(float value) {
                    assert(handle_);
                    ArkUI_NumberValue valueArr[] = {{.f32 = value}};
                    ArkUI_AttributeItem item = {valueArr, 1};
                    nativeModule_->setAttribute(handle_, NODE_SLIDER_VALUE, &item);
                }

                /**
                * @brief 获取滑块当前值
                * @return 滑块当前的浮点值
                */
                float GetValue() {
                    assert(handle_);
                    const ArkUI_AttributeItem* attrItem = nativeModule_->getAttribute(handle_, NODE_SLIDER_VALUE);
                    return attrItem->value[0].f32;
                }

                /**
                * @brief 设置滑块最小值
                * @param minValue 最小值（默认建议0.0）
                */
                void SetMinValue(float minValue) {
                    assert(handle_);
                    ArkUI_NumberValue valueArr[] = {{.f32 = minValue}};
                    ArkUI_AttributeItem item = {valueArr, 1};
                    nativeModule_->setAttribute(handle_, NODE_SLIDER_MIN_VALUE, &item);
                }

                /**
                * @brief 设置滑块最大值
                * @param maxValue 最大值（默认建议100.0）
                */
                void SetMaxValue(float maxValue) {
                    assert(handle_);
                    ArkUI_NumberValue valueArr[] = {{.f32 = maxValue}};
                    ArkUI_AttributeItem item = {valueArr, 1};
                    nativeModule_->setAttribute(handle_, NODE_SLIDER_MAX_VALUE, &item);
                }

                /**
                * @brief 设置滑块步长
                * @param step 步长（范围[0.01, 100]，默认1.0）
                */
                void SetStep(float step) {
                    assert(handle_);
                    assert(step >= 0.01f && step <= 100.0f && "Step must be in [0.01, 100]");
                    ArkUI_NumberValue valueArr[] = {{.f32 = step}};
                    ArkUI_AttributeItem item = {valueArr, 1};
                    nativeModule_->setAttribute(handle_, NODE_SLIDER_STEP, &item);
                }

                // ===================== 显示/交互属性 =====================
                /**
                * @brief 设置是否显示步长值
                * @param show true(1)显示，false(0)不显示（默认）
                */
                void SetShowSteps(int32_t show) {
                    assert(handle_);
                    ArkUI_NumberValue valueArr[] = {{.i32 = show}};
                    ArkUI_AttributeItem item = {valueArr, 1};
                    nativeModule_->setAttribute(handle_, NODE_SLIDER_SHOW_STEPS, &item);
                }

                /**
                * @brief 设置滑块滑动方向（水平/垂直）
                * @param direction 方向（ArkUI_SliderDirection枚举值）
                */
                void SetDirection(ArkUI_SliderDirection direction) {
                    assert(handle_);
                    ArkUI_NumberValue valueArr[] = {{.i32 = static_cast<int32_t>(direction)}};
                    ArkUI_AttributeItem item = {valueArr, 1};
                    nativeModule_->setAttribute(handle_, NODE_SLIDER_DIRECTION, &item);
                }

                /**
                * @brief 设置是否反转滑块值（如从右到左/从下到上）
                * @param reverse true(1)反转，false(0)不反转（默认）
                */
                void SetReverse(int32_t reverse) {
                    assert(handle_);
                    ArkUI_NumberValue valueArr[] = {{.i32 = reverse}};
                    ArkUI_AttributeItem item = {valueArr, 1};
                    nativeModule_->setAttribute(handle_, NODE_SLIDER_REVERSE, &item);
                }

                /**
                * @brief 设置滑块整体样式（轨道和按钮的布局风格）
                * @param style 样式（ArkUI_SliderStyle枚举值）
                */
                void SetStyle(ArkUI_SliderStyle style) {
                    assert(handle_);
                    ArkUI_NumberValue valueArr[] = {{.i32 = static_cast<int32_t>(style)}};
                    ArkUI_AttributeItem item = {valueArr, 1};
                    nativeModule_->setAttribute(handle_, NODE_SLIDER_STYLE, &item);
                }

                /**
                * @brief 设置滑块轨道厚度（vp单位）
                * @param thickness 厚度（默认：OUT_SET=4vp，IN_SET=20vp）
                */
                void SetTrackThickness(float thickness) {
                    assert(handle_);
                    ArkUI_NumberValue valueArr[] = {{.f32 = thickness}};
                    ArkUI_AttributeItem item = {valueArr, 1};
                    nativeModule_->setAttribute(handle_, NODE_SLIDER_TRACK_THICKNESS, &item);
                }

                /**
                * @brief 设置是否启用触觉反馈（震动）
                * @param enable true(1)启用，false(0)禁用（需添加VIBRATE权限）
                */
                void SetEnableHapticFeedback(int32_t enable) {
                    assert(handle_);
                    ArkUI_NumberValue valueArr[] = {{.i32 = enable}};
                    ArkUI_AttributeItem item = {valueArr, 1};
                    nativeModule_->setAttribute(handle_, NODE_SLIDER_ENABLE_HAPTIC_FEEDBACK, &item);
                }

                // ===================== 复杂样式：滑块形状/图片 =====================
                /**
                * @brief 设置滑块为图片样式
                * @param blockStyle 滑块样式类型（需传ARKUI_SLIDER_BLOCK_STYLE_IMAGE）
                * @param imagePath 图片资源路径（如"/pages/common/slider_icon.png"）
                */
                void SetBlockStyleImage(ArkUI_SliderBlockStyle blockStyle, const char* imagePath) {
                    assert(handle_);
                    assert(imagePath != nullptr && "Image path cannot be null");

                    std::vector<ArkUI_NumberValue> values;
                    values.push_back({.i32 = static_cast<int32_t>(blockStyle)});

                    ArkUI_AttributeItem item = {};
                    item.value = values.data();
                    item.size = values.size();
                    item.string = const_cast<char*>(imagePath);  // 设置图片路径

                    nativeModule_->setAttribute(handle_, NODE_SLIDER_BLOCK_STYLE, &item);
                }

                /**
                * @brief 设置滑块为矩形形状
                * @param blockStyle 滑块样式类型（需传ARKUI_SLIDER_BLOCK_STYLE_SHAPE）
                * @param width 矩形宽度（vp）
                * @param height 矩形高度（vp）
                * @param radiusX 圆角宽度（vp）
                * @param radiusY 圆角高度（vp）
                */
                void SetBlockStyleRectangle(ArkUI_SliderBlockStyle blockStyle, float width, float height, float radiusX, float radiusY) {
                    assert(handle_);

                    std::vector<ArkUI_NumberValue> values;
                    values.push_back({.i32 = static_cast<int32_t>(blockStyle)});          // 0: 样式类型
                    values.push_back({.i32 = static_cast<int32_t>(ArkUI_ShapeType::ARKUI_SHAPE_TYPE_RECTANGLE)});  // 1: 形状类型
                    values.push_back({.f32 = width});                                     // 2: 宽度
                    values.push_back({.f32 = height});                                    // 3: 高度
                    values.push_back({.f32 = radiusX});                                   // 4: 圆角宽度
                    values.push_back({.f32 = radiusY});                                   // 5: 圆角高度

                    ArkUI_AttributeItem item = {};
                    item.value = values.data();
                    item.size = values.size();

                    nativeModule_->setAttribute(handle_, NODE_SLIDER_BLOCK_STYLE, &item);
                }

                /**
                * @brief 设置滑块为圆形/椭圆形
                * @param blockStyle 滑块样式类型（需传ARKUI_SLIDER_BLOCK_STYLE_SHAPE）
                * @param shapeType 形状类型（圆形/椭圆形，ArkUI_ShapeType）
                * @param width 宽度（vp）
                * @param height 高度（vp）
                */
                void SetBlockStyleCircleEllipse(ArkUI_SliderBlockStyle blockStyle, ArkUI_ShapeType shapeType, float width, float height) {
                    assert(handle_);

                    std::vector<ArkUI_NumberValue> values;
                    values.push_back({.i32 = static_cast<int32_t>(blockStyle)});  // 0: 样式类型
                    values.push_back({.i32 = static_cast<int32_t>(shapeType)});   // 1: 形状类型
                    values.push_back({.f32 = width});                             // 2: 宽度
                    values.push_back({.f32 = height});                            // 3: 高度

                    ArkUI_AttributeItem item = {};
                    item.value = values.data();
                    item.size = values.size();

                    nativeModule_->setAttribute(handle_, NODE_SLIDER_BLOCK_STYLE, &item);
                }

                /**
                * @brief 设置滑块为自定义路径形状
                * @param blockStyle 滑块样式类型（需传ARKUI_SLIDER_BLOCK_STYLE_SHAPE）
                * @param width 路径宽度（vp）
                * @param height 路径高度（vp）
                * @param pathCommand 路径绘制指令（如"M0,0 L10,10 Z"）
                */
                void SetBlockStylePath(ArkUI_SliderBlockStyle blockStyle, float width, float height, const char* pathCommand) {
                    assert(handle_);
                    assert(pathCommand != nullptr && "Path command cannot be null");

                    std::vector<ArkUI_NumberValue> values;
                    values.push_back({.i32 = static_cast<int32_t>(blockStyle)});          // 0: 样式类型
                    values.push_back({.i32 = static_cast<int32_t>(ArkUI_ShapeType::ARKUI_SHAPE_TYPE_PATH)});  // 1: 形状类型
                    values.push_back({.f32 = width});                                     // 2: 宽度
                    values.push_back({.f32 = height});                                    // 3: 高度

                    ArkUI_AttributeItem item = {};
                    item.value = values.data();
                    item.size = values.size();
                    item.string = const_cast<char*>(pathCommand);  // 设置路径指令

                    nativeModule_->setAttribute(handle_, NODE_SLIDER_BLOCK_STYLE, &item);
                }
            };
        }  // namespace NativeModule

        // 外部C接口，供外部调用
        extern "C" {
            using namespace NativeModule;

            std::string formatNumber(float num) {
                if (std::floor(num) == num) {
                    return std::to_string(static_cast<int>(num)); // 转为整数字符串
                } else {
                    return std::to_string(num); // 保留小数（可结合方案1优化小数位数）
                }
            }

            std::shared_ptr<ArkUIBaseNode> CreateSelectNumber() {
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

                auto row = std::make_shared<ArkUIRowNode>();
                auto sliderNode = std::make_shared<ArkUISliderNode>();
                sliderNode->SetMinValue({% info.minValue %});                // 最小值0
                sliderNode->SetMaxValue({% info.maxValue %});              // 最大值100
                sliderNode->SetStep(1.0f);                    // 步长1
                sliderNode->SetDirection(ArkUI_SliderDirection::ARKUI_SLIDER_DIRECTION_HORIZONTAL);  // 水平方向
                sliderNode->SetReverse(0);                    // 不反转
                sliderNode->SetShowSteps(1);                  // 显示步长值
                sliderNode->SetEnableHapticFeedback(1);       // 启用触觉反馈（需权限）
                sliderNode->SetPercentWidth(0.8);
                sliderNode->SetBlockColor(0xFF0088FF);        // 滑块按钮蓝色
                sliderNode->SetTrackColor(0xFFE0E0E0);        // 轨道背景浅灰色
                sliderNode->SetSelectedColor(0xFF0088FF);     // 选中轨道蓝色
                sliderNode->SetBlockStyleCircleEllipse(
                    ArkUI_SliderBlockStyle::ARKUI_SLIDER_BLOCK_STYLE_SHAPE,
                    ArkUI_ShapeType::ARKUI_SHAPE_TYPE_CIRCLE,
                    20.0f,  // 宽度20vp
                    20.0f   // 高度20vp（圆形宽高一致）
                );
                auto text = std::make_shared<ArkUITextNode>();
                auto onClick = [sliderNode, text](ArkUI_NodeEvent *event) {
                        // 从组件事件获取事件类型
                        auto eventType = OH_ArkUI_NodeEvent_GetEventType(event);
                        switch (eventType) {
                            case NODE_SLIDER_EVENT_ON_CHANGE: {
                                auto componentEvent = OH_ArkUI_NodeEvent_GetNodeComponentEvent(event);
                                std::string num = formatNumber(componentEvent->data[0].f32);
                                text->SetTextContent(num);
                                g_click_callback(\"{% info.title %}\", num);
                            }
                            default: {
                                break;
                            }
                        }
                    };
                sliderNode->RegisterOnSliderChange(onClick);
                text->SetTextContent(formatNumber(sliderNode->GetValue()));
                text->SetFontSize(20);
                row->AddChild(sliderNode);
                row->AddChild(text);
                column->AddChild(row);
                column->SetMargin(0, 0, 20, 0);
                return column;
            }
        }  // extern "C"
    '''
}
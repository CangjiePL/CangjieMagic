package magic.ui.arkui

import magic.dsl.*
import magic.prelude.*
import magic.jsonable.*
import std.collection.*
import stdx.encoding.json.{JsonValue, JsonObject, JsonException, JsonKind, JsonInt, JsonString, JsonBool, JsonFloat, JsonArray, JsonNull}

@jsonable
public class TimeLineData {
    @field["Core content of timeline node, main display text"]
    let content: String
    @field["Timeline node text (e.g. timestamp/phase label)"]
    let nodeText: String
    @field["Background color of timeline node (format: 0xAARRGGBB)"]
    let nodeBgColor: String
    @field["img url"]
    let imgSrc: String
}

@ui[
    description: "适用于时间跨度较大的内容呈现(比如唐宋元明清阶段介绍),按时间顺序线性展示事件节点，适合流程、进度、历史记录等时序化场景。",
    lang: "arkui",
    kind: "display"
]
public func template_time_line(info: Array<TimeLineData>) {
    '''
        #include "native_drawing/drawing_bitmap.h"
        #include "native_drawing/drawing_brush.h"
        #include "native_drawing/drawing_canvas.h"
        #include "native_drawing/drawing_color.h"
        #include "native_drawing/drawing_color_filter.h"
        #include "native_drawing/drawing_filter.h"
        #include "native_drawing/drawing_font.h"
        #include "native_drawing/drawing_path.h"
        #include "native_drawing/drawing_pen.h"
        #include "native_drawing/drawing_pixel_map.h"
        #include "native_drawing/drawing_point.h"
        #include "native_drawing/drawing_rect.h"
        #include "native_drawing/drawing_register_font.h"
        #include "native_drawing/drawing_text_blob.h"
        #include "native_drawing/drawing_text_typography.h"
        #include "native_drawing/drawing_typeface.h"
        #include "native_drawing/drawing_types.h"
        #include "native_drawing/drawing_pixel_map.h"
        #include <codecvt>
        #include <hilog/log.h>
        #include <locale>
        #include <native_drawing/drawing_round_rect.h>
        #include <sstream>
        #include <string>
        #include <vector>
        #include <multimedia/image_framework/image/image_common.h>
        #include <multimedia/image_framework/image/image_source_native.h>

        namespace NativeModule {
            // 时间轴样式常量定义
            constexpr float TIMELINE_LINE_WIDTH = 2.0f;          // 中间竖线宽度
            constexpr uint32_t TIMELINE_LINE_COLOR = 0xFFE0E0E0; // 竖线颜色(浅灰色)
            constexpr float NODE_RADIUS = 55.0f;                 // 节点圆半径（适配文字显示）
            constexpr float NODE_BORDER_WIDTH = 2.0f;            // 节点白色边框宽度
            constexpr uint32_t NODE_BORDER_COLOR = 0xFFFFFFFF;   // 节点边框颜色(白色)
            constexpr float NODE_TEXT_SIZE = 45.0f;              // 节点内文字大小
            constexpr uint32_t NODE_TEXT_COLOR = 0xFFFFFFFF;     // 节点文字颜色(白色，保证彩色可读性)

            // 交叉布局+长文本换行核心常量
            constexpr float CONTENT_PADDING_H = 20.0f;           // 组件水平内边距
            constexpr float CONTENT_NODE_GAP = 70.0f;            // 内容与节点的间距（左/右统一）
            constexpr float ITEM_VERTICAL_SPACING = 100.0f;      // 垂直间距加大，适配多行长文本
            constexpr float TEXT_FONT_SIZE = 55.0f;              // 内容文字大小
            constexpr uint32_t TEXT_COLOR = 0xFF333333;          // 内容文字颜色
            constexpr float IMAGE_SIZE = 80.0f;                  // 图片尺寸
            constexpr float ITEM_MIN_HEIGHT = 150.0f;            // 项最小高度加大，适配换行
            constexpr float TEXT_LINE_SPACING = 10.0f;           // 行间距，控制多行文字疏密

            // 预定义常用彩色值（ARGB格式：0xAARRGGBB）
            const uint32_t COLOR_RED = 0xFFFF4444;
            const uint32_t COLOR_BLUE = 0xFF4A89DC;
            const uint32_t COLOR_YELLOW = 0xFFFFC800;
            const uint32_t COLOR_GREEN = 0xFF00C851;
            const uint32_t COLOR_PURPLE = 0xFFAA66CC;
            const uint32_t COLOR_ORANGE = 0xFFFF8800;
            const uint32_t COLOR_TEAL = 0xFF00ABA9;

            // 内容显示侧枚举
            enum class ShowSide {
                LEFT, // 左侧显示内容
                RIGHT // 右侧显示内容
            };

            // 时间轴数据结构（保留原有，无改动）
            struct TimelineItem {
                std::string content;                // 单内容字段（支持长文本，自动换行）
                std::string nodeText;               // 节点中心显示的文字
                uint32_t nodeBgColor;               // 节点自定义背景色
                std::string imagePath;              // 图片路径(可选，优先级高于文字)
                ShowSide showSide;                  // 显示侧（左/右）
                float itemHeight = ITEM_MIN_HEIGHT; // 项高度

                TimelineItem(const std::string &cont, const std::string &nText, uint32_t nBgColor, ShowSide side,
                            const std::string &imgPath = "", float height = ITEM_MIN_HEIGHT)
                    : content(cont), nodeText(nText), nodeBgColor(nBgColor), imagePath(imgPath), showSide(side),
                    itemHeight(height) {}
            };

            struct TextLayoutCache {
                std::vector<std::string> wrapLines; // WrapText的结果（拆分后的行）
                float realHeight;                   // 文本真实高度
                bool hasImage;                      // 是否显示图片（无需文本计算）
            };

            class ArkUICustomCrossTimelineNode : public ArkUINode {
            public:
                ArkUICustomCrossTimelineNode()
                    : ArkUINode((NativeModuleInstance::GetInstance()->GetNativeNodeAPI())->createNode(ARKUI_NODE_CUSTOM)),
                    canvasWidth_(0.0f), canvasHeight_(0.0f), centerLineX_(0.0f), brush_(nullptr), pen_(nullptr),
                    textFont_(nullptr), nodeTextFont_(nullptr) {
                    InitTimelineData();
                    InitDrawResources();
                    nativeModule_->addNodeCustomEventReceiver(handle_, OnStaticCustomEvent);
                    nativeModule_->registerNodeCustomEvent(handle_, ARKUI_NODE_CUSTOM_EVENT_ON_DRAW, 0, this);
                }

                ~ArkUICustomCrossTimelineNode() override {
                    nativeModule_->removeNodeCustomEventReceiver(handle_, OnStaticCustomEvent);
                    nativeModule_->unregisterNodeCustomEvent(handle_, ARKUI_NODE_CUSTOM_EVENT_ON_DRAW);
                    ReleaseDrawResources();
                }

            private:
                static void OnStaticCustomEvent(ArkUI_NodeCustomEvent *event) {
                    auto customNode = reinterpret_cast<ArkUICustomCrossTimelineNode *>(OH_ArkUI_NodeCustomEvent_GetUserData(event));
                    auto type = OH_ArkUI_NodeCustomEvent_GetEventType(event);
                    switch (type) {
                    case ARKUI_NODE_CUSTOM_EVENT_ON_DRAW:
                        customNode->OnDraw(event);
                        break;
                    default:
                        break;
                    }
                }

                // 初始化时间轴数据
                void InitTimelineData() {
                    auto side = ShowSide::LEFT;
                    {% for (index, item) in enumerate(info) %}
                        side = {% index %} % 2 == 0 ? ShowSide::LEFT : ShowSide::RIGHT;
                        {% if (item.imgSrc.size == 0) %}
                            timelineItems.emplace_back(
                                \"{% item.content %}\", \"{% item.nodeText %}\", {% item.nodeBgColor %},
                                side);
                        {% else %}
                            timelineItems.emplace_back(
                                \"{% item.content %}\", \"{% item.nodeText %}\", {% item.nodeBgColor %},
                                side, \"{% item.imgSrc %}\");
                        {% /if %}
                    {% /for %}
                }

                // 初始化绘制资源
                void InitDrawResources() {
                    brush_ = OH_Drawing_BrushCreate();
                    if (brush_) {
                        OH_Drawing_BrushSetAntiAlias(brush_, true);
                    }

                    pen_ = OH_Drawing_PenCreate();
                    if (pen_) {
                        OH_Drawing_PenSetAntiAlias(pen_, true);
                        OH_Drawing_PenSetWidth(pen_, TIMELINE_LINE_WIDTH);
                        OH_Drawing_PenSetColor(pen_, TIMELINE_LINE_COLOR);
                    }

                    textFont_ = OH_Drawing_FontCreate();
                    if (textFont_) {
                        OH_Drawing_FontSetTextSize(textFont_, TEXT_FONT_SIZE);
                    }

                    nodeTextFont_ = OH_Drawing_FontCreate();
                    if (nodeTextFont_) {
                        OH_Drawing_FontSetTextSize(nodeTextFont_, NODE_TEXT_SIZE);
                    }
                }

                // 释放绘制资源
                void ReleaseDrawResources() {
                    if (brush_) {
                        OH_Drawing_BrushDestroy(brush_);
                        brush_ = nullptr;
                    }
                    if (pen_) {
                        OH_Drawing_PenDestroy(pen_);
                        pen_ = nullptr;
                    }
                    if (textFont_) {
                        OH_Drawing_FontDestroy(textFont_);
                        textFont_ = nullptr;
                    }
                    if (nodeTextFont_) {
                        OH_Drawing_FontDestroy(nodeTextFont_);
                        nodeTextFont_ = nullptr;
                    }
                }

                // 计算单个字符串的绘制宽度
                float GetTextWidth(const std::string &text, OH_Drawing_Font *font) {
                    if (text.empty() || !font)
                        return 0.0f;
                    OH_Drawing_TextBlob *blob =
                        OH_Drawing_TextBlobCreateFromString(text.c_str(), font, OH_Drawing_TextEncoding::TEXT_ENCODING_UTF8);
                    if (!blob)
                        return 0.0f;
                    OH_Drawing_Rect *rect = OH_Drawing_RectCreate(0, 0, 0, 0);
                    OH_Drawing_TextBlobGetBounds(blob, rect);
                    float width = OH_Drawing_RectGetWidth(rect);
                    OH_Drawing_TextBlobDestroy(blob);
                    OH_Drawing_RectDestroy(rect);
                    return width;
                }

                // 判断单个字符是否为中文字符
                bool IsChineseChar(char32_t c) {
                    // 中文Unicode编码范围：0x4E00 - 0x9FFF
                    return (c >= 0x4E00 && c <= 0x9FFF);
                }

                // 将std::string转为UTF32，方便判断中文字符
                std::u32string StringToUtf32(const std::string &str) {
                    std::wstring_convert<std::codecvt_utf8<char32_t>, char32_t> converter;
                    try {
                        return converter.from_bytes(str);
                    } catch (...) {
                        return U"";
                    }
                }

                // 长文本自动换行分割：按最大宽度分割为多行字符串
                std::vector<std::string> WrapText(const std::string &text, OH_Drawing_Font *font, float maxWidth) {
                    std::vector<std::string> lines;
                    if (text.empty() || !font || maxWidth <= 0)
                        return lines;

                    std::u32string utf32Text = StringToUtf32(text); // 转为UTF32处理中文
                    std::string currentLine;                        // 当前行内容
                    std::string currentWord;                        // 临时存储英文单词（避免截断）

                    for (char32_t c32 : utf32Text) {
                        char32_t toChar32[] = {c32, U'\\0'};
                        std::string singleChar = std::wstring_convert<std::codecvt_utf8<char32_t>, char32_t>().to_bytes(toChar32);

                        // 场景1：遇到空格 → 处理英文单词
                        if (c32 == U' ') {
                            if (!currentWord.empty()) {
                                // 拼接当前单词到行，判断宽度
                                std::string tempLine = currentLine.empty() ? currentWord : currentLine + " " + currentWord;
                                float tempWidth = GetTextWidth(tempLine, font);

                                if (tempWidth <= maxWidth) {
                                    currentLine = tempLine; // 未超宽，加入当前行
                                } else {
                                    lines.push_back(currentLine); // 超宽，保存当前行
                                    currentLine = currentWord;    // 新行从当前单词开始
                                }
                                currentWord.clear(); // 清空临时单词
                            }
                            continue;
                        }

                        // 场景2：中文字符 → 逐字判断
                        if (IsChineseChar(c32)) {
                            // 先处理未完成的英文单词（如果有）
                            if (!currentWord.empty()) {
                                std::string tempLine = currentLine.empty() ? currentWord : currentLine + currentWord;
                                float tempWidth = GetTextWidth(tempLine, font);
                                if (tempWidth <= maxWidth) {
                                    currentLine = tempLine;
                                } else {
                                    lines.push_back(currentLine);
                                    currentLine = currentWord;
                                }
                                currentWord.clear();
                            }

                            // 拼接当前中文字符，判断宽度
                            std::string tempLine = currentLine + singleChar;
                            float tempWidth = GetTextWidth(tempLine, font);
                            if (tempWidth <= maxWidth) {
                                currentLine = tempLine; // 未超宽，继续拼接
                            } else {
                                lines.push_back(currentLine); // 超宽，换行
                                currentLine = singleChar;     // 新行从当前字符开始
                            }
                            continue;
                        }

                        // 场景3：英文字符 → 拼接成单词（避免截断）
                        currentWord += singleChar;
                    }

                    // 处理最后剩余的内容（英文单词/中文）
                    if (!currentWord.empty()) {
                        std::string tempLine = currentLine.empty() ? currentWord : currentLine + currentWord;
                        float tempWidth = GetTextWidth(tempLine, font);
                        if (tempWidth <= maxWidth) {
                            currentLine = tempLine;
                        } else {
                            lines.push_back(currentLine);
                            currentLine = currentWord;
                        }
                    }
                    if (!currentLine.empty()) {
                        lines.push_back(currentLine);
                    }

                    return lines;
                }

                // 绘制节点中心文字
                void DrawNodeText(OH_Drawing_Canvas *canvas, const std::string &text, float centerX, float centerY) {
                    if (text.empty() || !nodeTextFont_ || !brush_)
                        return;

                    OH_Drawing_TextBlob *textBlob = OH_Drawing_TextBlobCreateFromString(
                        text.c_str(), nodeTextFont_, OH_Drawing_TextEncoding::TEXT_ENCODING_UTF8);
                    if (!textBlob)
                        return;

                    OH_Drawing_Rect *textRect = OH_Drawing_RectCreate(0, 0, 0, 0);
                    OH_Drawing_TextBlobGetBounds(textBlob, textRect);
                    float textW = OH_Drawing_RectGetWidth(textRect);
                    float textH = OH_Drawing_RectGetHeight(textRect);
                    float drawX = centerX - textW / 2.0f;
                    float drawY = centerY + textH / 3.0f;

                    OH_Drawing_BrushSetColor(brush_, NODE_TEXT_COLOR);
                    OH_Drawing_CanvasAttachBrush(canvas, brush_);
                    OH_Drawing_CanvasDrawTextBlob(canvas, textBlob, drawX, drawY);
                    OH_Drawing_CanvasDetachBrush(canvas);

                    OH_Drawing_TextBlobDestroy(textBlob);
                    OH_Drawing_RectDestroy(textRect);
                }

                // 绘制彩色圆形节点
                void DrawColoredNode(OH_Drawing_Canvas *canvas, float centerX, float centerY, uint32_t nodeColor) {
                    if (!brush_ || !pen_)
                        return;

                    OH_Drawing_Path *circlePath = OH_Drawing_PathCreate();
                    if (!circlePath)
                        return;

                    OH_Drawing_PathAddCircle(circlePath, centerX, centerY, NODE_RADIUS + NODE_BORDER_WIDTH, PATH_DIRECTION_CW);
                    OH_Drawing_BrushSetColor(brush_, NODE_BORDER_COLOR);
                    OH_Drawing_CanvasAttachBrush(canvas, brush_);
                    OH_Drawing_CanvasDrawPath(canvas, circlePath);
                    OH_Drawing_CanvasDetachBrush(canvas);

                    OH_Drawing_PathReset(circlePath);
                    OH_Drawing_PathAddCircle(circlePath, centerX, centerY, NODE_RADIUS, PATH_DIRECTION_CW);
                    OH_Drawing_BrushSetColor(brush_, nodeColor);
                    OH_Drawing_CanvasAttachBrush(canvas, brush_);
                    OH_Drawing_CanvasDrawPath(canvas, circlePath);
                    OH_Drawing_CanvasDetachBrush(canvas);

                    OH_Drawing_PathDestroy(circlePath);
                }

                // 绘制图片占位框
                void DrawImagePlaceholder(OH_Drawing_Canvas *canvas, float x, float y, float width, float height) {
                    if (!brush_ || !pen_)
                        return;

                    OH_Drawing_Path *imgPath = OH_Drawing_PathCreate();
                    if (!imgPath)
                        return;

                    OH_Drawing_PathAddRect(imgPath, x, y, x + width, y + height, PATH_DIRECTION_CW);
                    OH_Drawing_BrushSetColor(brush_, 0xFFF0F0F0);
                    OH_Drawing_CanvasAttachBrush(canvas, brush_);
                    OH_Drawing_CanvasDrawPath(canvas, imgPath);
                    OH_Drawing_CanvasDetachBrush(canvas);

                    OH_Drawing_PenSetColor(pen_, 0xFFCCCCCC);
                    OH_Drawing_PenSetWidth(pen_, 1.0f);
                    OH_Drawing_CanvasAttachPen(canvas, pen_);
                    OH_Drawing_CanvasDrawPath(canvas, imgPath);
                    OH_Drawing_CanvasDetachPen(canvas);

                    OH_Drawing_PathDestroy(imgPath);
                }

                // 计算内容绘制坐标
                void CalContentPos(ShowSide side, float nodeCenterY, float &contentX, float &contentY,
                                    bool isImage = false) {
                    contentY = nodeCenterY;
                    // 文字/图片垂直坐标计算
                    if (isImage) {
                        contentY -= IMAGE_SIZE / 2.0f;
                    } else {
                        contentY += TEXT_FONT_SIZE * 0.3f;
                    }

                    if (side == ShowSide::LEFT) {
                        contentX = CONTENT_PADDING_H;
                    } else {
                        contentX = centerLineX_ + CONTENT_NODE_GAP;
                    }
                }

                // 复用缓存的wrapLines绘制文本，无需再次拆分
                void DrawTextFromCache(OH_Drawing_Canvas *canvas, const std::vector<std::string> &wrapLines, float x, float y) {
                    if (wrapLines.empty() || !textFont_ || !brush_)
                        return;

                    float currentY = y;
                    for (const std::string &line : wrapLines) {
                        OH_Drawing_TextBlob *textBlob = OH_Drawing_TextBlobCreateFromString(
                            line.c_str(), textFont_, OH_Drawing_TextEncoding::TEXT_ENCODING_UTF8);
                        if (!textBlob)
                            continue;

                        OH_Drawing_BrushSetColor(brush_, TEXT_COLOR);
                        OH_Drawing_CanvasAttachBrush(canvas, brush_);
                        OH_Drawing_CanvasDrawTextBlob(canvas, textBlob, x, currentY);
                        OH_Drawing_CanvasDetachBrush(canvas);

                        OH_Drawing_TextBlobDestroy(textBlob);
                        currentY += TEXT_FONT_SIZE + TEXT_LINE_SPACING;
                    }
                }

                void OnDraw(ArkUI_NodeCustomEvent *event) {
                    auto drawContext = OH_ArkUI_NodeCustomEvent_GetDrawContextInDraw(event);
                    auto canvas = reinterpret_cast<OH_Drawing_Canvas *>(OH_ArkUI_DrawContext_GetCanvas(drawContext));
                    auto size = OH_ArkUI_DrawContext_GetSize(drawContext);
                    canvasWidth_ = size.width;
                    canvasHeight_ = size.height;
                    centerLineX_ = canvasWidth_ * 0.5f;

                    if (!brush_ || !pen_ || !textFont_ || !nodeTextFont_ || timelineItems.empty()) {
                        return;
                    }

                    OH_Drawing_CanvasSave(canvas);

                    std::vector<TextLayoutCache> layoutCaches; // 缓存每个item的布局信息
                    float totalHeight = 0.0f;                  // 时间轴总高度

                    for (size_t i = 0; i < timelineItems.size(); ++i) {
                        const auto &item = timelineItems[i];
                        TextLayoutCache cache;
                        cache.hasImage = !item.imagePath.empty();

                        if (cache.hasImage) {
                            // 图片场景：直接计算图片高度
                            cache.realHeight = IMAGE_SIZE + 30.0f; // 图片80f + 上下留白20f
                        } else {
                            float maxWrapWidth = 0.0f;
                            if (item.showSide == ShowSide::LEFT) {
                                maxWrapWidth = centerLineX_ - CONTENT_PADDING_H - CONTENT_NODE_GAP;
                            } else {
                                maxWrapWidth = canvasWidth_ - centerLineX_ - CONTENT_PADDING_H - CONTENT_NODE_GAP;
                            }
                            if (maxWrapWidth < 50.0f)
                                maxWrapWidth = 50.0f;

                            cache.wrapLines = WrapText(item.content, textFont_, maxWrapWidth);
                            int lineCount = cache.wrapLines.size();

                            // 步骤3：基于缓存的行数计算真实高度（无需再次调用WrapText）
                            if (lineCount == 0) {
                                cache.realHeight = ITEM_MIN_HEIGHT;
                            } else {
                                float lineHeight = TEXT_FONT_SIZE + TEXT_LINE_SPACING;
                                cache.realHeight = (lineCount * lineHeight - TEXT_LINE_SPACING) + 20.0f; // 加留白
                                // 兜底：不小于最小高度
                                cache.realHeight = std::max(cache.realHeight, ITEM_MIN_HEIGHT);
                            }
                        }

                        // 保存缓存，累加总高度
                        layoutCaches.push_back(cache);
                        totalHeight += cache.realHeight + ITEM_VERTICAL_SPACING;
                    }
                    // 减去最后一个item的间距
                    if (!timelineItems.empty()) {
                        totalHeight -= ITEM_VERTICAL_SPACING;
                    }

                    // 绘制中间竖线
                    OH_Drawing_Path *linePath = OH_Drawing_PathCreate();
                    if (linePath) {
                        float startY = 0.0f; // 从顶部开始显示
                        OH_Drawing_PathMoveTo(linePath, centerLineX_, startY);
                        OH_Drawing_PathLineTo(linePath, centerLineX_, startY + totalHeight);

                        OH_Drawing_PenSetColor(pen_, TIMELINE_LINE_COLOR);
                        OH_Drawing_PenSetWidth(pen_, TIMELINE_LINE_WIDTH);
                        OH_Drawing_CanvasAttachPen(canvas, pen_);
                        OH_Drawing_CanvasDrawPath(canvas, linePath);
                        OH_Drawing_CanvasDetachPen(canvas);

                        OH_Drawing_PathDestroy(linePath);

                        // 绘制每个时间轴项
                        float currentY = startY;
                        for (size_t i = 0; i < timelineItems.size(); ++i) {
                            const auto &item = timelineItems[i];
                            const auto &cache = layoutCaches[i]; // 取缓存结果
                            float itemHeight = cache.realHeight;
                            float nodeCenterY = currentY + itemHeight * 0.5f;
                            float contentX = 0.0f, contentY = 0.0f;

                            // 绘制节点和节点文字
                            DrawColoredNode(canvas, centerLineX_, nodeCenterY, item.nodeBgColor);
                            DrawNodeText(canvas, item.nodeText, centerLineX_, nodeCenterY);

                            // 绘制内容：复用缓存的wrapLines，不再调用WrapText
                            if (cache.hasImage) {
                                CalContentPos(item.showSide, nodeCenterY,contentX, contentY, true);
                                DrawImagePlaceholder(canvas, contentX, contentY, IMAGE_SIZE, contentY);
                            } else {
                                CalContentPos(item.showSide, nodeCenterY, contentX, contentY, false);
                                // 直接用缓存的wrapLines绘制，无需再次拆分
                                DrawTextFromCache(canvas, cache.wrapLines, contentX, contentY - itemHeight * 0.5f + 25);
                            }

                            currentY += itemHeight + ITEM_VERTICAL_SPACING;
                        }
                    }

                    OH_Drawing_CanvasRestore(canvas);
                }

                // 成员变量
                std::vector<TimelineItem> timelineItems;
                float canvasWidth_;
                float canvasHeight_;
                float centerLineX_;
                OH_Drawing_Brush *brush_;
                OH_Drawing_Pen *pen_;
                OH_Drawing_Font *textFont_;
                OH_Drawing_Font *nodeTextFont_;
            };
        }  // namespace NativeModule

        // 外部C接口，供外部调用
        extern "C" {
            using namespace NativeModule;

            std::shared_ptr<ArkUIBaseNode> DrawCrossTimeline() {
                auto column = std::make_shared<ArkUIColumnNode>();
                auto timelineNode = std::make_shared<ArkUICustomCrossTimelineNode>();
                timelineNode->SetPercentWidth(1);
                timelineNode->SetHeight(600);
                column->AddChild(timelineNode);

                column->SetMargin(0, 0, 15, 0);

                return column;
            }
        }  // extern "C"
    '''
}
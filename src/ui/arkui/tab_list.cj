package magic.ui.arkui

import magic.dsl.*
import magic.prelude.*
import magic.jsonable.*
import std.collection.*
import stdx.encoding.json.{JsonValue, JsonObject, JsonException, JsonKind, JsonInt, JsonString, JsonBool, JsonFloat, JsonArray, JsonNull}

@jsonable
public class Content {
    @field["title"]
    let title: String
    @field["list item summary"]
    let summary: Array<String>
    @field["source (general: publisher/merchant/creator, etc.)"]
    let source: String
    @field["date"]
    let date: Array<String>
    @field["image url"]
    let imgSrc: String
    @field["tags"]
    let tags: Array<String>
}

@jsonable
public class TabListData {
    @field["all tag lists"]
    let tags: Array<String>
    @field["the data information to be displayed"]
    let data: Array<Content>
}

// 以标签页形式切换展示不同内容，适用于多分类、多模块快速切换场景
@ui[
    description: "通用UI",
    lang: "arkui",
    kind: "display"
]
public func template_tab_list(info: TabListData) {
    '''
        #include <map>
        namespace NativeModule {
            struct Content {
                std::string title;
                std::string summary;
                std::string source;
                std::string date;
                std::string img;
                std::vector<std::string> types;

                Content(std::string title, std::string summary, std::string source, std::string date, std::string img, std::vector<std::string> types)
                : title(std::move(title)), summary(std::move(summary)), source(std::move(source)), date(std::move(date)), img(std::move(img)), types(std::move(types)) {}
            };

            struct TabListData {
                std::vector<std::string> types;
                std::vector<Content> content;
            };

            TabListData CreateTabListData() {
                TabListData tabData;

                {% for tag in info.tags %}
                    tabData.types.push_back(\"{% tag %}\");
                {% /for %}

                std::vector<std::string> tags;
                {% for item in info.data %}
                    {% for tag in item.tags %}
                        tags.push_back(\"{% tag %}\");
                    {% /for %}
                    tabData.content.push_back(Content(\"{% item.title %}\", \"{% item.summary %}\", \"{% item.source %}\", \"{% item.date %}\", \"{% item.imgSrc %}\", tags));
                    tags.clear();
                {% /for %}
                return tabData;
            }
        }  // namespace NativeModule

        // 外部C接口，供外部调用
        extern "C" {
            using namespace NativeModule;

            struct HotNews {
                std::string title;
                std::string summary;
                std::string source;
                std::string date;
                std::string img;

                HotNews(std::string title, std::string summary, std::string source, std::string date, std::string img)
                                : title(std::move(title)), summary(std::move(summary)), source(std::move(source)), date(std::move(date)), img(std::move(img)) {}
            };

            static int g_selectedTabIndex = 0;
            static std::vector<std::shared_ptr<ArkUITextNode>> g_tabTextNodes;
            static std::map<std::string, std::vector<HotNews>> g_newsTypeMap;
            static std::vector<HotNews> g_hotNewsLis;

            std::shared_ptr<ArkUIBaseNode> CreateHotNewsFeedExample(TabListData data)
            {
                auto rootContainer = std::make_shared<ArkUIColumnNode>();
                rootContainer->SetPercentWidth(1);
                rootContainer->SetBackgroundColor(0xFFF5F5F5);

                // 创建顶部标签栏
                auto tabBar = std::make_shared<ArkUIFlexNode>();
                tabBar->SetPercentWidth(1);
                tabBar->SetFlexWrap(ARKUI_FLEX_WRAP_WRAP);

                // 标签文本列表
                std::vector<std::string> tabTexts;
                for (int i = 0; i < data.types.size(); i++) {
                    tabTexts.push_back(data.types[i]);
                }

                for (auto item : data.content) {
                    HotNews news = HotNews(item.title, item.summary, item.source, item.date, item.img);
                    g_hotNewsLis.push_back(news);
                    for (auto t : item.types) {
                        if (g_newsTypeMap.count(t)) {
                            g_newsTypeMap[t].push_back(news);
                        } else {
                            std::vector<HotNews> vec;
                            vec.push_back(news);
                            g_newsTypeMap[t] = vec;
                        }
                    }
                }

                // 初始化标签文本节点容器
                g_tabTextNodes.clear();

                for (int32_t i = 0; i < tabTexts.size(); ++i) {
                    // 创建标签文本节点
                    auto tabText = std::make_shared<ArkUITextNode>();
                    tabText->SetBackgroundColor(0xFFFFFFFF);
                    tabText->SetMargin(0, 8, 10, 8);
                    tabText->SetBorderRadius(8);
                    tabText->SetTextContent(tabTexts[i]);
                    tabText->SetFontSize(16);

                    // 设置选中/未选中颜色
                    tabText->SetFontColor(g_selectedTabIndex == i ? 0xFF0066CC : 0xFF666666);
                    tabText->SetFontWeight(g_selectedTabIndex == i ? ARKUI_FONT_WEIGHT_BOLD : ARKUI_FONT_WEIGHT_NORMAL);
                    // 设置点击区域
                    tabText->SetWidth(80);
                    tabText->SetHeight(48);
                    tabText->SetTextAlign(ARKUI_TEXT_ALIGNMENT_CENTER);
                    auto onClick = [i, tabTexts, hostList = &g_hotNewsLis, tabTextNodes = &g_tabTextNodes](ArkUI_NodeEvent *event) -> bool {
                        if (OH_ArkUI_NodeEvent_GetEventType(event) == NODE_ON_CLICK) {
                            g_selectedTabIndex = i;
                            for (int j = 0; j < tabTextNodes->size(); ++j) {
                                (*tabTextNodes)[j]->SetFontColor(g_selectedTabIndex == j ? 0xFF0066CC : 0xFF666666);
                                (*tabTextNodes)[j]->SetFontWeight(g_selectedTabIndex == j ? ARKUI_FONT_WEIGHT_BOLD : ARKUI_FONT_WEIGHT_NORMAL);
                            }
                            OH_LOG_Print(LOG_APP, LOG_INFO, 0xFF00, "[Sample_NdkAddInteractionEvent]",
                                                    "NdkAddInteractionEvent_eventInfoOfCommonEvent %{public}d",
                                                    g_newsTypeMap[tabTexts[i]].size());
                            (*hostList) = g_newsTypeMap[tabTexts[i]];
                            //OH_ArkUI_NodeAdapter_ReloadAllItems(ArkUI_NodeAdapterHandle handle);
                            //OH_ArkUI_NodeAdapter_Create()
                        }
                        return true;
                    };
                    tabText->RegisterOnClick(onClick);

                    g_tabTextNodes.push_back(tabText);
                    tabBar->AddChild(tabText);
                }

                // 创建List组件承载新闻卡片
                auto newsList = std::make_shared<ArkUIListNode>();
                newsList->SetBackgroundColor(0xFFF5F5F5);
                newsList->SetPercentWidth(1);
                newsList->SetPadding(16, 12, 16, 0);

                // 创建新闻卡片ListItem并挂载到List上
                for (int32_t i = 0; i < g_hotNewsLis.size(); ++i) {
                    const auto& news = g_hotNewsLis[i];

                    // 创建ListItem容器
                    auto listItem = std::make_shared<ArkUIListItemNode>();
                    // 创建新闻卡片
                    auto card = std::make_shared<ArkUIColumnNode>();
                    card->SetPercentWidth(1);
                    card->SetBackgroundColor(0xFFFFFFFF);
                    card->SetCornerRadius(8);
                    card->SetPadding(15, 10, 15, 10);
                    listItem->SetMargin(10, 8, 10, 8);

                    // 4.1 创建标题文本
                    auto titleText = std::make_shared<ArkUITextNode>();
                    titleText->SetTextContent(news.title);
                    titleText->SetFontSize(18);
                    titleText->SetFontColor(0xFF333333);
                    titleText->SetFontWeight(ARKUI_FONT_WEIGHT_BOLD);
                    titleText->SetPercentWidth(1);
                    card->InsertChild(titleText, 0);

                    // 4.2 创建摘要文本
                    auto summaryText = std::make_shared<ArkUITextNode>();
                    summaryText->SetTextContent(news.summary);
                    summaryText->SetFontSize(16);
                    summaryText->SetFontColor(0xFF666666);
                    summaryText->SetPercentWidth(1);
                    summaryText->SetMargin(8, 8, 12, 8);
                    card->InsertChild(summaryText, 1);

                    // 4.3 创建来源和时间容器
                    auto footerContainer = std::make_shared<ArkUIRowNode>();
                    footerContainer->SetPercentWidth(1);
                    // 来源文本
                    auto sourceText = std::make_shared<ArkUITextNode>();
                    sourceText->SetTextContent(news.source);
                    sourceText->SetFontSize(12);
                    sourceText->SetFontColor(0xFF999999);
                    sourceText->SetMargin(0, 12, 0, 0);
                    footerContainer->InsertChild(sourceText, 0);
                    // 时间文本
                    auto dateText = std::make_shared<ArkUITextNode>();
                    dateText->SetTextContent(news.date);
                    dateText->SetFontSize(12);
                    dateText->SetFontColor(0xFF999999);
                    footerContainer->InsertChild(dateText, 1);
                    card->InsertChild(footerContainer, 2);

                    listItem->InsertChild(card, 0);
                    auto adapter = std::make_shared<ArkUIListItemAdapter>();
                    newsList->SetLazyAdapter(adapter);
                    //newsList->AddChild(listItem);
                }

                rootContainer->AddChild(tabBar);
                rootContainer->AddChild(newsList);
                return rootContainer;
            }
        }  // extern "C"
    '''
}
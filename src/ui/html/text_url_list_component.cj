/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.ui.html

import magic.dsl.*
import magic.prelude.*



@jsonable
public class TextURLItem {
    @field["title"]
    let title: String
    @field["URL hyperlink"]
    let url: String
    @field["Brief description"]
    let description: String
}

@ui[description: '''
    功能类型：带链接列表 UI・跳转入口型，
    使用场景：以列表形式承载含跳转需求的信息，如帮助中心 FAQ 问题列表、新闻资讯摘要列表、商品分类入口列表、文档目录索引列表、权限说明详情链接列表、活动入口聚合列表，
    交互特性：导航跳转型，支持点击列表项 / 内置链接跳转，
    风格属性：简约通用型
    ''',
    kind: "display"
]
public func textURLListUI(items: Array<TextURLItem>) {
    '''
    <!DOCTYPE html>
    <html lang="zh-CN">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>链表展示</title>
        <link href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css" rel="stylesheet">
        <style>
            /* 链接列表样式 */
            .link-list {
                list-style: none;
                padding: 0;
                margin: 0;
            }

            .link-item {
                margin-bottom: 16px;
                border-bottom: 1px solid hsl(210, 14%, 89%);
                padding-bottom: 16px;
                transition: all 0.3s ease;
            }

            .link-item:last-child {
                border-bottom: none;
                padding-bottom: 0;
                margin-bottom: 0;
            }

            .link-title {
                display: inline-block;
                font-size: 18px;
                font-weight: 600;
                color: hsl(217, 91%, 60%);
                text-decoration: none;
                margin-bottom: 8px;
                transition: all 0.2s ease;
                position: relative;
            }

            .link-title::after {
                content: '';
                position: absolute;
                width: 0;
                height: 2px;
                bottom: -2px;
                left: 0;
                background-color: hsl(217, 91%, 60%);
                transition: width 0.3s ease;
            }

            .link-title:hover::after {
                width: 100%;
            }

            .link-url {
                display: block;
                font-size: 14px;
                color: hsl(215, 19%, 35%);
                margin-bottom: 8px;
                word-break: break-all;
            }

            .link-url a {
                color: hsl(215, 19%, 35%);
                text-decoration: none;
                transition: color 0.2s ease;
            }

            .link-url a:hover {
                color: hsl(217, 91%, 60%);
            }

            .link-description {
                font-size: 16px;
                color: hsl(220, 9%, 46%);
                line-height: 1.5;
            }
        </style>
    </head>
    <body>
    <!-- 主内容区 -->
    <main class="container py-8">
        <!-- 链接列表 -->
        <div class="card">
            <ul class="link-list">
                {% for item in items %}
                <li class="link-item">
                    <h3 class="link-title">
                        <a href=\"{% item.url %}\" target="_blank">{% item.title %}</a>
                    </h3>
                    <p class="link-description">{% item.description %}</p>
                </li>
                {% /for %}
            </ul>
        </div>
    </main>
    </body>
    </html>
    '''
}
/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.ui.html

import magic.dsl.*
import magic.prelude.*



@jsonable
public class ImgItem {
    @field["title"]
    let title: String
    @field["The URL of the image, it must be valid"]
    let url: String
}

@ui[description: '''
    功能类型：图片列表 UI,
    使用场景：以列表形式展示图片及关联信息，如景点风光图片列表、美食菜品展示列表,
    交互特性：信息展示型，仅用于呈现信息，无交互,
    风格属性：简约通用型
    ''',
    kind: "display"
]
public func imgListUI(items: Array<ImgItem>) {
    '''
    <!DOCTYPE html>
    <html lang="zh-CN">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>卡片式图片列表</title>
        <style>
            .img-card-list {
                display: grid;
                gap: 16px;
            }
            .img-card {
                background-color: white;
                border-radius: 8px;
                box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
                overflow: hidden;
                transition: transform 0.2s, box-shadow 0.2s;
            }
            .img-card:hover {
                transform: translateY(-2px);
                box-shadow: 0 6px 16px rgba(0, 0, 0, 0.1);
            }
            .img-card img {
                width: 100%;
                height: auto;
                display: block;
            }
            .img-card h3 {
                font-size: 16px;
                font-weight: 500;
                padding: 12px 16px;
                color: hsl(0, 0%, 20%);
            }
        </style>
    </head>
    <body>
    <div class="container">
        {% for item in items %}
        <div class="img-card">
            <img src=\"{% item.url %}\">
            <h3>{% item.title %}</h3>
        </div>
        {% /for %}
    </div>
    </body>
    </html>
    '''
}
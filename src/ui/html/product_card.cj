/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.ui.html

import magic.dsl.*
import magic.prelude.*



@jsonable
public class ProductCardInfo {
    @field["产品图片URL"]
    let imageUrl: String
    @field["产品名称"]
    let title: String
    @field["产品描述，限制在20字以内"]
    let description: String
    @field["产品价格"]
    let price: String
    @field["产品标签数组"]
    let tags: Array<String>
}

@ui[description: '''
    功能类型：产品卡片组件，
    使用场景：仅可展示一个产品信息，如送礼推荐，电商网站、产品列表页，
    交互特性：包含购买和查看详情按钮，支持点击交互，
    风格属性：简约通用型
''',
    kind: "display"
]
public func productCards(product: ProductCardInfo) {
    '''
    <!DOCTYPE html>
    <html lang="zh-CN">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>卡片组件场景示例</title>
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
        <style>
            /* 通用卡片样式 */
            .product-card {
                background: hsl(0, 0%, 100%);
                border-radius: 12px;
                overflow: hidden;
                box-shadow: 0 5px 15px hsl(0, 0%, 0%, 0.08);
                transition: transform 0.3s, box-shadow 0.3s;
                border: 1px solid hsl(0, 0%, 92%);
            }

            .card-body {
                padding: 5px;
            }

            .card-footer {
                padding: 15px 20px;
                background-color: hsl(210, 17%, 98%);
                border-top: 1px solid hsl(0, 0%, 92%);
            }

            .card-title {
                font-size: 1.25rem;
                font-weight: 600;
                margin-bottom: 10px;
                color: hsl(208, 37%, 20%);
            }

            .card-text {
                color: hsl(209, 15%, 45%);
                font-size: 0.95rem;
                line-height: 1.5;
            }

            .card-img {
                width: 100%;
                height: 180px;
                object-fit: cover;
                display: block;
            }

            .btn {
                display: inline-block;
                padding: 8px 16px;
                border-radius: 6px;
                border: none;
                font-weight: 500;
                cursor: pointer;
                transition: all 0.2s;
                text-align: center;
                font-size: 0.9rem;
            }

            .btn-primary {
                background-color: hsl(205, 70%, 58%);
                color: hsl(0, 0%, 100%);
            }

            .btn-primary:hover {
                background-color: hsl(205, 71%, 45%);
            }

            .btn-outline {
                background-color: transparent;
                border: 1px solid hsl(205, 70%, 58%);
                color: hsl(205, 70%, 58%);
            }

            .btn-outline:hover {
                background-color: hsl(205, 70%, 58%);
                color: hsl(0, 0%, 100%);
            }

            .price {
                font-size: 2rem;
                font-weight: 700;
                color: hsl(208, 37%, 20%);
            }

            .price-period {
                font-size: 1rem;
                color: hsl(180, 2%, 50%);
                font-weight: 400;
            }

            .tag {
                display: inline-block;
                padding: 4px 10px;
                border-radius: 20px;
                font-size: 0.75rem;
                font-weight: 600;
                margin-right: 5px;
                margin-bottom: 5px;
            }

            .tag-primary {
                background-color: hsl(205, 70%, 58%, 0.1);
                color: hsl(205, 70%, 58%);
            }

            .tag-success {
                background-color: hsl(145, 63%, 45%, 0.1);
                color: hsl(146, 58%, 45%);
            }

            .tag-warning {
                background-color: hsl(44, 89%, 52%, 0.1);
                color: hsl(34, 92%, 52%);
            }

            /* 小屏手机（576px以下）：可选双栏/单栏，这里优化双栏的紧凑性 */
            @media (max-width: 476px) {
                /* 进一步压缩小屏的内边距和字体 */
                .card-body {
                    padding: 4px;
                }

                .card-title, .price {
                    font-size: 0.85rem
                }

                .card-description, .price-period {
                    font-size: 0.65rem
                }

                .card-footer {
                    padding: 3px 6px;
                }

                .btn {
                    padding: clamp(5px, 1.5vw, 7px) clamp(8px, 2vw, 14px);
                    font-size: clamp(0.7rem, 1.5vw, 0.8rem);
                }

                .tag {
                    padding: 2px 6px;
                    font-size: clamp(0.7rem, 1.2vw, 0.7rem);
                }
            }
        </style>
    </head>
    <body>

            <div class="product-card">
                {% if (product.imageUrl.size != 0) %}
                <img src=\"{% product.imageUrl %}\" alt="产品图片" class="card-img">
                {% /if %}
                <div class="card-body">
                    <h3 class="card-title">{% product.title %}</h3>
                    <p class="card-text">{% product.description %}</p>

                    <div style="display: flex; justify-content: flex-start; flex-wrap: wrap; justify-content: space-between; align-items: center; margin-top: 20px;">
                        <div>
                            <span class="price">{% product.price %}</span>
                            <span class="price-period">起</span>
                        </div>
                        <div>
                            {% for tag in product.tags %}
                            <span class="tag tag-primary">{% tag %}</span>
                            {% /for %}
                        </div>
                    </div>
                </div>
                <div class="card-footer">
                    <button class="btn btn-primary">立即购买</button>
                    <button class="btn btn-outline" style="float: right;">查看详情</button>
                </div>
            </div>

    </body>
    </html>
    '''
}
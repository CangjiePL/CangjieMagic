/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.ui.html

import magic.dsl.*
import magic.prelude.*



@jsonable
public class CompareInfo {
    @field["Subject Information"]
    let title: String
    @field["A list of the names of the items compared"]
    let name: Array<String>
    @field["A list of types to compare"]
    let category: Array<String>
    @field["""
        Parameter values for each item in each category. First dimension: the length of the corresponding category list (number of categories);
        Second dimension: the length of the corresponding name list (number of items). If the size of name is [2], the size of category is [3], and the size of param is [3, 2].
        such as 'name=['apple','banana'], category=['price','sweetness', 'hardness'], then param=[['high','low'],['moderate','sweet'],['hard','soft']]"""]
    let param: Array<Array<String>>
}

@ui[description: '''
    功能类型：信息对比表格 UI・多维度数据对比型，
    使用场景：展示多主体 / 多维度的对比信息，如产品参数对比、方案优劣对比、候选人资质对比、不同套餐权益对比、多地点性价比对比，
    交互特性：信息展示型，仅用于呈现信息，无交互，
    风格属性：图表型
    ''',
    kind: "display"
]
public func compareUI(info: CompareInfo) {
    '''
    <!DOCTYPE html>
    <html lang="zh-CN">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>对比页面</title>
        <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.8/dist/chart.umd.min.js"></script>
        <style>
            /* 标题区域 */
            .compare-header {
                text-align: center;
                margin: 40px 0;
            }

            .compare-header h1 {
                font-size: clamp(1.5rem, 3vw, 2.5rem);
                color: hsl(210, 10%, 23%);
                margin-bottom: 10px;
                font-weight: 700;
            }

            .compare-header p {
                color: hsl(210, 9%, 31%);
                max-width: 800px;
                margin: 0 auto;
            }

            /* 对比表格 */
            .compare-table {
                width: 100%;
                border-collapse: collapse;
                background: hsl(0, 0%, 100%);
                border-radius: 8px;
                box-shadow: 0 1px 3px hsla(0, 0%, 0%, 0.1);
                overflow: hidden;
            }

            .compare-table th,
            .compare-table td {
                padding: 15px 20px;
                text-align: left;
                border-bottom: 1px solid hsl(210, 14%, 89%);
            }

            .compare-table th {
                background: hsl(210, 16%, 93%);
                font-weight: 600;
                width: 20%;
            }

            .compare-name {
                text-align: center;
                background: hsl(210, 16%, 93%);
                font-weight: 700;
                color: hsl(210, 10%, 23%);
            }

            /* 响应式调整 */
            @media (max-width: 768px) {
                .filter-group {
                    flex-direction: column;
                }

                .compare-table th {
                    font-size: 0.9em;
                    padding: 10px;
                }

                .compare-table td {
                    font-size: 0.9em;
                    padding: 10px;
                }
            }
        </style>
    </head>
    <body>
    <header class="compare-header">
        <h1>{% info.title %}</h1>
    </header>

    <table class="compare-table">
        <thead>
        <tr>
            <th>参数</th>
            {% for n in info.name %}
                <th class="compare-name">{% n %}</th>
            {% /for %}
        </tr>
        </thead>
        <tbody>
            {% for j in 0..info.category.size %}
                <tr>
                    <th>{% info.category[j] %}</th>
                    {% for i in 0..info.name.size %}
                        <td>{% info.param[j][i] %}</td>
                    {% /for %}
                </tr>
            {% /for %}
        </tbody>
    </table>
    </body>
    </html>
    '''
}
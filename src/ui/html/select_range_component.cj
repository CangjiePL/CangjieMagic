/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.ui.html

import magic.dsl.*
import magic.prelude.*



@ui[
    description: '''
    功能类型：选择数值范围 UI・区间数值筛选型，
    使用场景：筛选整数数值区间的相关数据，如价格范围筛选（商品 / 服务）、年龄区间选择、数量范围设置、评分区间筛选、文件大小范围限定，
    交互特性：数据录入型，支持拖动滑块选择区间，
    风格属性：简约通用型
    ''',
    parameters: {
        nr: "数值范围区间，包括最大值和最小值"
    },
    kind: "input"
]
public func selectRangeUI(nr: NumericRange) {
    '''
    <!DOCTYPE html>
    <html lang="zh-CN">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>数值范围选择器</title>
        <script src="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css"></script>
        <style>
            .range-wrapper {
                position: relative;
                height: 3rem;
                margin: 2rem 0;
            }

            .range-slider {
                position: relative;
                height: 0.5rem;
                border-radius: 0.25rem;
                background-color: hsl(0, 0%, 90%);
            }

            .range-selected-{ num } {
                position: absolute;
                height: 100%;
                border-radius: 0.25rem;
                background-color: hsl(217, 91%, 60%);
                transition: background-color 0.2s ease;
            }

            .range-input {
                position: absolute;
                width: 100%;
                height: 0.5rem;
                top: 0;
                left: 0;
                background: none;
                pointer-events: none;
                -webkit-appearance: none;
                -moz-appearance: none;
                appearance: none;
            }

            .range-input::-webkit-slider-thumb {
                height: 1.5rem;
                width: 1.5rem;
                border-radius: 50%;
                background: hsl(217, 91%, 60%);
                border: 2px solid white;
                box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
                cursor: pointer;
                -webkit-appearance: none;
                appearance: none;
                pointer-events: auto;
                transition: all 0.2s ease;
            }

            .range-input::-webkit-slider-thumb:hover {
                transform: scale(1.1);
                background: hsl(217, 89%, 54%);
            }

            .range-input::-moz-range-thumb {
                height: 1.5rem;
                width: 1.5rem;
                border-radius: 50%;
                background: hsl(217, 91%, 60%);
                border: 2px solid white;
                box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
                cursor: pointer;
                pointer-events: auto;
                transition: all 0.2s ease;
            }

            .range-input::-moz-range-thumb:hover {
                transform: scale(1.1);
                background: hsl(217, 89%, 54%);
            }

            .range-values {
                display: flex;
                justify-content: space-between;
                margin-top: 1.5rem;
            }

            .range-value {
                padding: 0.5rem 1rem;
                background-color: hsl(217, 91%, 60%);
                color: white;
                border-radius: 0.5rem;
                font-weight: 500;
                box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
                transition: all 0.2s ease;
            }

            .range-value:hover {
                background-color: hsl(217, 89%, 54%);
                transform: translateY(-2px);
            }

            .fa-sliders {
                margin-right: 0.5rem;
                color: hsl(217, 91%, 60%);
            }

            .range-min-max {
                display: flex;
                justify-content: space-between;
                margin-top: 0.5rem;
                font-size: 0.875rem;
                color: hsl(215, 19%, 49%);
            }
        </style>
    </head>
    <body>
    <div class="container">
        <div class="card">
            <h3 class="range-title"><i class="fa fa-sliders"></i>{% nr.title %}</h3>

            <div class="range-wrapper">
                <div class="range-slider">
                    <div class="range-selected-{ num }"></div>
                </div>

                <input type="range" min=\"{% nr.min %}\" max=\"{% nr.max %}\" value=\"{% nr.min %}\" class="range-input" id="range-min-{ num }" oninput="updateRange-{ num }()">
                <input type="range" min=\"{% nr.min %}\" max=\"{% nr.max %}\" value=\"{% nr.max %}\" class="range-input" id="range-max-{ num }" oninput="updateRange-{ num }()">
            </div>

            <div class="range-min-max">
                <span>最小值: {% nr.min %}</span>
                <span>最大值: {% nr.max %}</span>
            </div>

            <div class="range-values">
                <div class="range-value range-value-min" id="min-value-{ num }">{% nr.min %}</div>
                <div class="range-value range-value-max" id="max-value-{ num }">{% nr.max %}</div>
            </div>
        </div>
    </div>

    <script>
        function updateRange-{ num }() {
            const minRange-{ num } = document.getElementById(\'range-min-{ num }\');
            const maxRange-{ num } = document.getElementById(\'range-max-{ num }\');
            const selected-{ num } = document.querySelector(\'.range-selected-{ num }\');
            const minValue-{ num } = document.getElementById(\'min-value-{ num }\');
            const maxValue-{ num } = document.getElementById(\'max-value-{ num }\');

            if (parseInt(maxRange-{ num }.value) < parseInt(minRange-{ num }.value)) {
                maxRange-{ num }.value = minRange-{ num }.value;
            }

            const minPercent-{ num } = (minRange-{ num }.value - minRange-{ num }.min) / (minRange-{ num }.max - minRange-{ num }.min) * 100;
            const maxPercent-{ num } = (maxRange-{ num }.value - maxRange-{ num }.min) / (maxRange-{ num }.max - maxRange-{ num }.min) * 100;

            selected-{ num }.style.left = minPercent-{ num } + \'%\';
            selected-{ num }.style.right = (100 - maxPercent-{ num }) + \'%\';

            minValue-{ num }.textContent = minRange-{ num }.value;
            maxValue-{ num }.textContent = maxRange-{ num }.value;
        }

        // 初始化范围显示
        updateRange-{ num }();
    </script>
    </body>
    </html>
    '''
}
/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.ui.html

import magic.dsl.*
import magic.prelude.*



@jsonable
public class NumericRange {
    @field["Theme of choice"]
    public let title: String
    @field["Maximum value"]
    public let max: Int64
    @field["Minimum value"]
    public let min: Int64
}

@ui[
    description: '''
    功能类型：选择单个数值 UI・单点数值筛选型，
    使用场景：选择特定单个数值的相关操作，如商品数量选择、评分星级选择、年龄设置、音量调节数值选择、文件页码定位，
    交互特性：数据录入型，支持点击数值选项 / 拖动滑块选择,
    风格属性：简约通用型
    ''',
    parameters: {
        nr: "数值范围区间，包括最大值和最小值"
    },
    kind: "input"
]
public func selectNumberUI(nr: NumericRange) {
    '''
    <!DOCTYPE html>
    <html lang="zh-CN">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <!-- Font Awesome -->
        <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.7.2/css/all.min.css" rel="stylesheet">
        <style>
            .slider-wrapper {
                position: relative;
                height: 2.5rem;
                margin: 1.5rem 0;
            }

            /* 自定义滑块轨道 */
            .slider-track {
                position: absolute;
                top: 50%;
                transform: translateY(-50%);
                height: 0.5rem;
                width: 100%;
                background-color: var(--track-bg);
                border-radius: 0.25rem;
            }

            .slider-progress {
                position: absolute;
                top: 50%;
                transform: translateY(-50%);
                height: 0.5rem;
                background-color: var(--primary);
                border-radius: 0.25rem;
                transition: width 0.1s ease;
            }

            /* 自定义滑块拇指 */
            .slider-thumb {
                position: absolute;
                top: 50%;
                transform: translate(-50%, -50%);
                width: 1.5rem;
                height: 1.5rem;
                background-color: white;
                border-radius: 50%;
                border: 2px solid var(--primary);
                box-shadow: 0 2px 5px hsl(210, 10%, 75%);
                cursor: pointer;
                transition: all 0.15s ease;
                z-index: 1;
            }

            .slider-thumb:hover,
            .slider-thumb:active {
                transform: translate(-50%, -50%) scale(1.1);
                border-color: var(--primary-dark);
                box-shadow: 0 3px 8px hsl(210, 10%, 65%);
            }

            /* 隐藏原生滑块 */
            .slider {
                -webkit-appearance: none;
                appearance: none;
                width: 100%;
                height: 100%;
                background: transparent;
                outline: none;
                margin: 0;
                position: absolute;
                z-index: 2;
            }

            /* 自定义滑块拇指（WebKit/Blink） */
            .slider::-webkit-slider-thumb {
                -webkit-appearance: none;
                appearance: none;
                width: 0;
                height: 0;
            }

            /* 自定义滑块拇指（Firefox） */
            .slider::-moz-range-thumb {
                width: 0;
                height: 0;
                border: none;
            }

            /* 数值范围显示 */
            .slider-range {
                display: flex;
                justify-content: space-between;
                margin-top: 0.5rem;
                font-size: 0.875rem;
                color: hsl(210, 11%, 45%);
            }

            /* 当前值显示 */
            .slider-value-container {
                display: flex;
                justify-content: center;
                margin: 1.5rem 0;
            }

            .slider-value {
                font-size: 2rem;
                font-weight: 600;
                color: var(--primary);
                padding: 0.5rem 1.5rem;
                border-radius: 0.5rem;
                background-color: hsl(210, 100%, 97%);
                min-width: 4rem;
                text-align: center;
                transition: all 0.2s ease;
            }

            .slider-value.changed {
                animation: pulse 0.5s ease-in-out;
            }

            .fa-sliders {
                margin-right: 0.5rem;
                color: hsl(217, 91%, 60%);
            }
        </style>
    </head>
    <body>
    <div class="container">
        <div class="card">
            <h3 class="number-title"""><i class="fa fa-sliders"></i>{% nr.title %}</h3>

            <div class="slider-wrapper">
                <div class="slider-track"></div>
                <div class="slider-progress" id="progress-{ num }"></div>
                <div class="slider-thumb" id="thumb-{ num }"></div>
                <input type="range" min=\"{% nr.min %}\" max=\"{% nr.max %}\" value=\"{% nr.max %}\" class="slider" id="slider-{ num }">
            </div>

            <div class="slider-range">
                <div>最小值: {% nr.min %}</div>
                <div>最大值: {% nr.max %}</div>
            </div>

            <div class="slider-value-container">
                <div class="slider-value" id="sliderValue-{ num }">{% nr.max %}</div>
            </div>
        </div>
    </div>

    <script>
        // 获取DOM元素
        const slider-{ num } = document.getElementById(\'slider-{ num }\');
        const progress-{ num } = document.getElementById(\'progress-{ num }\');
        const thumb-{ num } = document.getElementById(\'thumb-{ num }\');
        const valueDisplay-{ num } = document.getElementById(\'sliderValue-{ num }\');

        // 更新滑块显示
        function updateSlider-{ num }(value) {
            // 计算百分比
            const percent = (value / slider-{ num }.max) * 100;

            // 更新进度条
            progress-{ num }.style.width = `\${percent}%`;

            // 更新滑块位置
            thumb-{ num }.style.left = `\${percent}%`;

            // 更新显示值
            valueDisplay-{ num }.textContent = value;

            // 添加变化动画
            valueDisplay-{ num }.classList.add(\'changed\');
            setTimeout(() => {
                valueDisplay-{ num }.classList.remove(\'changed\');
            }, 500);
        }

        // 初始化滑块
        updateSlider-{ num }(slider-{ num }.value);

        // 滑块值变化事件
        slider-{ num }.addEventListener(\'input\', () => {
            updateSlider-{ num }(slider-{ num }.value);
        });
    </script>
    </body>
    </html>
    '''
}

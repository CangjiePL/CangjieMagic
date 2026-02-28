/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.ui.html

import magic.dsl.*
import magic.prelude.*



@ui[
    description: '''
    功能类型：精准时间选择 UI,
    使用场景：需精确选择时间点的操作，如任务截止时间设定、行程出发时间确认、活动开场时间配置,
    交互特性：滑动交互型，支持上下滚动选择时 / 分 / 秒,
    风格属性：简约通用型
    ''',
    parameters: {
        title: "描述特定选择时间点事件的标题"
    },
    kind: "input"
]
public func clockUI(title: String) {
    '''
    <!DOCTYPE html>
    <html lang="zh-CN">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <style>
            .time-display {
                font-size: 40px;
                text-align: center;
                margin: 20px 0;
                font-weight: bold;
                color: hsl(0, 0%, 20%)
            }

            .clock-picker-wrapper {
                display: flex;
                justify-content: center;
                gap: 20px;
                margin: 30px 0;
            }

            .clock-picker-column {
                width: 80px;
                height: 200px;
                position: relative;
                overflow: hidden;
            }

            .clock-picker-mask {
                position: absolute;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                background: linear-gradient(to bottom,
                    rgba(255,255,255,0.9) 0%,
                    rgba(255,255,255,0.7) 30%,
                    rgba(255,255,255,0) 50%,
                    rgba(255,255,255,0) 50%,
                    rgba(255,255,255,0.7) 70%,
                    rgba(255,255,255,0.9) 100%);
                pointer-events: none;
            }

            .clock-picker-highlight {
                position: absolute;
                top: 60%;
                left: 0;
                width: 100%;
                height: 50px;
                transform: translateY(-50%);
                border-top: 1px solid hsl(217, 89%, 61%);
                border-bottom: 1px solid hsl(217, 89%, 61%);
                pointer-events: none;
            }

            .clock-picker-list {
                list-style: none;
                padding: 0;
                margin: 0;
                position: absolute;
                top: 50%;
                left: 0;
                width: 100%;
                transform: translateY(-50%);
            }

            .clock-picker-item {
                height: 50px;
                display: flex;
                align-items: center;
                justify-content: center;
                font-size: 22px;
                color: gray;
                transition: all 0.2s ease-out;
            }

            .clock-picker-item.selected {
                color: hsl(0, 0%, 20%);
                font-size: 26px;
                font-weight: bold;
            }
        </style>
    </head>
    <body>
    <div class="container">
        <div class="card">
            <h3 class="clock-title">{% title %}</h3>
            <div class="time-display" id="timeDisplay-{ num }">08:00</div>

            <div class="clock-picker-wrapper">
                <div class="clock-picker-column" id="hourColumn-{ num }">
                    <div class="clock-picker-mask"></div>
                    <div class="clock-picker-highlight"></div>
                    <ul class="clock-picker-list" id="hourList-{ num }"></ul>
                </div>

                <div class="clock-picker-column" id="minuteColumn-{ num }">
                    <div class="clock-picker-mask"></div>
                    <div class="clock-picker-highlight"></div>
                    <ul class="clock-picker-list" id="minuteList-{ num }"></ul>
                </div>
            </div>
        </div>
    </div>

    <script>
        document.addEventListener(\'DOMContentLoaded\', function() {
            // 初始化变量
            let selectedHour-{ num } = 8;
            let selectedMinute-{ num } = 0;
            let hourItems-{ num } = [];
            let minuteItems-{ num } = [];

            // 生成小时选项 (0-23)
            const hourList-{ num } = document.getElementById(\'hourList-{ num }\');
            for (let i = 0; i < 24; i++) {
                const hour = document.createElement(\'li\');
                hour.className = \'clock-picker-item\';
                hour.textContent = i.toString().padStart(2, \'0\');
                hour.dataset.value = i;
                hourList-{ num }.appendChild(hour);
                hourItems-{ num }.push(hour);
            }

            // 生成分钟选项 (0-59)
            const minuteList-{ num } = document.getElementById(\'minuteList-{ num }\');
            for (let i = 0; i < 60; i++) {
                const minute = document.createElement(\'li\');
                minute.className = \'clock-picker-item\';
                minute.textContent = i.toString().padStart(2, \'0\');
                minute.dataset.value = i;
                minuteList-{ num }.appendChild(minute);
                minuteItems-{ num }.push(minute);
            }

            // 更新显示的时间和选中状态
            function updateTimeDisplay-{ num }() {
                document.getElementById('timeDisplay-{ num }').textContent =
                    `\${selectedHour-{ num }.toString().padStart(2, \'0\')}:\${selectedMinute-{ num }.toString().padStart(2, \'0\')}`;
                updateTimeSelectedItems-{ num }();
            }

            // 更新选中项的状态
            function updateTimeSelectedItems-{ num }() {
                hourItems-{ num }.forEach(item => {
                    item.classList.remove(\'selected\');
                    if (parseInt(item.dataset.value) === selectedHour-{ num }) {
                        item.classList.add(\'selected\');
                    }
                });

                minuteItems-{ num }.forEach(item => {
                    item.classList.remove(\'selected\');
                    if (parseInt(item.dataset.value) === selectedMinute-{ num }) {
                        item.classList.add(\'selected\');
                    }
                });
            }

            // 初始化选择器
            function setupClockPicker-{ num }(column, list, isHour) {
                const itemHeight = 50;
                let startY = 0;
                let startPosition = 0;
                let currentPosition = 0;
                let isDragging = false;
                let velocity = 0;
                let lastY = 0;
                let lastTime = 0;
                let animationId = null;

                // 计算位置对应的值
                function getValueFromPositionl-{ num }(pos) {
                    const maxItems = isHour ? 24 : 60;
                    return Math.min(maxItems - 1, Math.max(0, Math.round(-pos / itemHeight)));
                }

                // 限制位置范围
                function constrainPosition-{ num }(pos) {
                    const min = isHour ? -23 * itemHeight : -59 * itemHeight;
                    return Math.min(0, Math.max(min, pos));
                }

                // 更新位置和显示
                function updatePosition-{ num }(pos) {
                    currentPosition = constrainPosition-{ num }(pos);
                    list.style.transform = `translateY(\${currentPosition}px)`;

                    const value = getValueFromPositionl-{ num }(currentPosition);
                    if (isHour) {
                        selectedHour-{ num } = value;
                    } else {
                        selectedMinute-{ num } = value;
                    }
                    updateTimeDisplay-{ num }();
                }

                // 惯性滚动效果
                function momentumScroll-{ num }() {
                    if (Math.abs(velocity) > 1) {
                        currentPosition += velocity;
                        velocity *= 0.95; // 减速因子
                        updatePosition-{ num }(currentPosition);
                        animationId = requestAnimationFrame(momentumScroll-{ num });
                    } else {
                        snapToNearest-{ num }();
                    }
                }

                // 对齐到最近的选项
                function snapToNearest-{ num }() {
                    cancelAnimationFrame(animationId);
                    const targetPos = -getValueFromPositionl-{ num }(currentPosition) * itemHeight;

                    // 平滑过渡
                    list.style.transition = \'transform 0.3s cubic-bezier(0.25, 0.46, 0.45, 0.94)\';
                    currentPosition = targetPos;
                    list.style.transform = `translateY(\${targetPos}px)`;

                    setTimeout(() => {
                        list.style.transition = \'\';
                    }, 300);
                }

                // 鼠标/触摸事件
                column.addEventListener(\'mousedown\', (e) => {
                    e.preventDefault();
                    isDragging = true;
                    startY = e.clientY;
                    startPosition = currentPosition;
                    velocity = 0;
                    lastY = e.clientY;
                    lastTime = Date.now();
                });

                document.addEventListener(\'mousemove\', (e) => {
                    if (!isDragging) return;

                    const now = Date.now();
                    const deltaY = e.clientY - startY;
                    const deltaTime = now - lastTime;

                    if (deltaTime > 0) {
                        velocity = (e.clientY - lastY) / deltaTime * 16;
                        lastY = e.clientY;
                        lastTime = now;
                    }

                    updatePosition-{ num }(startPosition + deltaY);
                });

                document.addEventListener(\'mouseup\', () => {
                    if (!isDragging) return;
                    isDragging = false;

                    if (Math.abs(velocity) > 5) {
                        momentumScroll-{ num }();
                    } else {
                        snapToNearest-{ num }();
                    }
                });

                // 触摸事件
                column.addEventListener(\'touchstart\', (e) => {
                    isDragging = true;
                    startY = e.touches[0].clientY;
                    startPosition = currentPosition;
                    velocity = 0;
                    lastY = e.touches[0].clientY;
                    lastTime = Date.now();
                    e.preventDefault();
                }, { passive: false });

                document.addEventListener(\'touchmove\', (e) => {
                    if (!isDragging) return;

                    const now = Date.now();
                    const deltaY = e.touches[0].clientY - startY;
                    const deltaTime = now - lastTime;

                    if (deltaTime > 0) {
                        velocity = (e.touches[0].clientY - lastY) / deltaTime * 16;
                        lastY = e.touches[0].clientY;
                        lastTime = now;
                    }

                    updatePosition-{ num }(startPosition + deltaY);
                    e.preventDefault();
                }, { passive: false });

                document.addEventListener(\'touchend\', () => {
                    if (!isDragging) return;
                    isDragging = false;

                    if (Math.abs(velocity) > 5) {
                        momentumScroll-{ num }();
                    } else {
                        snapToNearest-{ num }();
                    }
                });

                // 滚轮事件
                column.addEventListener(\'wheel\', (e) => {
                    e.preventDefault();
                    updatePosition-{ num }(currentPosition + e.deltaY * 0.5);
                    snapToNearest-{ num }();
                }, { passive: false });

                // 设置初始位置
                updatePosition-{ num }(isHour ? -selectedHour-{ num } * itemHeight : -selectedMinute-{ num } * itemHeight);
            }

            // 初始化picker
            setupClockPicker-{ num }(document.getElementById(\'hourColumn-{ num }\'), hourList-{ num }, true);
            setupClockPicker-{ num }(document.getElementById(\'minuteColumn-{ num }\'), minuteList-{ num }, false);
        });
    </script>
    </body>
    </html>
    '''
}
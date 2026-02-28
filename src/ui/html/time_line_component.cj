/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.ui.html

import magic.dsl.*
import magic.prelude.*




@jsonable
public class TimeLineItem {
    @field["time"]
    let time: String
    @field["title"]
    let title: String
    @field["brief content"]
    let content: String
    @field["hyperlink, if not there is one, it is empty''"]
    let url: String
}

@ui[
    description: '''
    功能类型：时间线 UI，
    使用场景：以时间轴形式展示时序类信息，如物流轨迹跟踪、项目阶段进度、活动流程步骤、版本更新日志、用户操作历史记录、订单状态变更记录，
    交互特性：信息展示型，支持上下滑动查看完整时序，
    风格属性：简约通用型
    ''',
    kind: "display"
]
public func timeLineUI(list: Array<TimeLineItem>) {
    '''
    <!DOCTYPE html>
    <html lang="zh-CN">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <!-- Font Awesome -->
        <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.7.2/css/all.min.css" rel="stylesheet">
        <style>
            .timeline-title {
                font-size: 1.75rem;
                font-weight: 700;
                margin-bottom: 2rem;
                text-align: center;
                color: var(--primary-dark);
            }

            .timeline {
                position: relative;
                padding: 2rem 0;
            }

            /* 时间线中线 */
            .timeline::before {
                content: '';
                position: absolute;
                top: 0;
                bottom: 0;
                left: 50%;
                width: 2px;
                background-color: var(--gray-300);
                transform: translateX(-50%);
            }

            /* 时间线项目 */
            .timeline-item {
                position: relative;
                margin-bottom: 3rem;
                opacity: 0;
                transform: translateY(20px);
                transition: all 0.6s ease;
            }

            .timeline-item.visible {
                opacity: 1;
                transform: translateY(0);
            }

            /* 左侧项目 */
            .timeline-item:nth-child(odd) {
                padding-right: calc(50% + 2rem);
                text-align: right;
            }

            /* 右侧项目 */
            .timeline-item:nth-child(even) {
                padding-left: calc(50% + 2rem);
            }

            /* 时间点标记 */
            .timeline-dot {
                position: absolute;
                top: 0;
                width: 1.5rem;
                height: 1.5rem;
                border-radius: 50%;
                background-color: var(--primary);
                border: 3px solid white;
                box-shadow: 0 0 0 2px var(--primary);
                z-index: 1;
            }

            .timeline-item:nth-child(odd) .timeline-dot {
                right: calc(50% - 0.75rem);
            }

            .timeline-item:nth-child(even) .timeline-dot {
                left: calc(50% - 0.75rem);
            }

            /* 时间内容卡片 */
            .timeline-content {
                background-color: white;
                border-radius: 0.5rem;
                padding: 1.25rem;
                box-shadow: 0 4px 6px -1px hsl(210, 10%, 75%);
                transition: all 0.3s ease;
            }

            .timeline-content:hover {
                box-shadow: 0 10px 15px -3px hsl(210, 10%, 70%);
                transform: translateY(-2px);
            }

            /* 时间标签 */
            .timeline-time {
                font-size: 1rem;
                font-weight: 600;
                color: var(--primary);
                margin-bottom: 0.5rem;
            }

            /* 标题 */
            .timeline-header {
                font-size: 1.25rem;
                font-weight: 700;
                margin-bottom: 0.75rem;
            }

            /* 描述 */
            .timeline-body {
                color: var(--gray-500);
                margin-bottom: 1rem;
            }

            /* 标签 */
            .timeline-tags {
                display: flex;
                flex-wrap: wrap;
                gap: 0.5rem;
            }

            .timeline-tag {
                font-size: 0.75rem;
                padding: 0.25rem 0.5rem;
                border-radius: 0.25rem;
                background-color: var(--primary-light);
                color: var(--primary-dark);
            }

            /* 查看更多按钮 */
            .timeline-more {
                display: inline-flex;
                align-items: center;
                color: var(--primary);
                text-decoration: none;
                font-weight: 500;
                transition: all 0.2s ease;
            }

            .timeline-more:hover {
                color: var(--primary-dark);
            }

            .timeline-more i {
                margin-left: 0.25rem;
                transition: transform 0.2s ease;
            }

            .timeline-more:hover i {
                transform: translateX(2px);
            }

            /* 响应式设计 */
            @media (max-width: 768px) {
                .timeline::before {
                    left: 1.5rem;
                }

                .timeline-item {
                    padding-left: 3.5rem !important;
                    padding-right: 0 !important;
                    text-align: left !important;
                    margin-bottom: 2rem;
                }

                .timeline-dot {
                    left: calc(1.5rem - 0.75rem) !important;
                }
            }

            /* 加载更多按钮 */
            .load-more {
                display: flex;
                justify-content: center;
                margin-top: 2rem;
            }

            .load-more button {
                background-color: var(--primary);
                color: white;
                border: none;
                border-radius: 0.375rem;
                padding: 0.75rem 1.5rem;
                font-size: 1rem;
                font-weight: 500;
                cursor: pointer;
                transition: all 0.2s ease;
                box-shadow: 0 2px 4px hsl(210, 10%, 80%);
            }

            .load-more button:hover {
                background-color: var(--primary-dark);
                transform: translateY(-1px);
                box-shadow: 0 3px 6px hsl(210, 10%, 75%);
            }

            .load-more button:active {
                transform: translateY(0);
                box-shadow: 0 1px 2px hsl(210, 10%, 80%);
            }

            .load-more button i {
                margin-left: 0.5rem;
            }
        </style>
    </head>
    <body>
    <div class="container">
        <h2 class="timeline-title">时间线</h2>
        <div class="timeline">
            <!-- 时间线项目1 -->
            {% for item in list %}
            <div class="timeline-item">
                <div class="timeline-dot"></div>
                <div class="timeline-content">
                    <div class="timeline-time">{% item.time %}</div>
                    <div class="timeline-header">{% item.title %}</div>
                    <div class="timeline-body">
                        {% item.content %}
                    </div>
                    {% if (item.url != '') %}
                    <a href=\"{% item.url %}\" class="timeline-more">
                        了解更多 <i class="fa fa-arrow-right"></i>
                    </a>
                    {% /if %}
                </div>
            </div>
            {% /for %}
        </div>
    </div>

    <script>
        // 初始化时间线项目动画
        function initTimelineAnimations-{ num }() {
            const timelineItems = document.querySelectorAll(\'.timeline-item\');

            const observer = new IntersectionObserver((entries) => {
                entries.forEach(entry => {
                    if (entry.isIntersecting) {
                        entry.target.classList.add(\'visible\');
                    }
                });
            }, {
                threshold: 0.1
            });

            timelineItems.forEach(item => {
                observer.observe(item);
            });
        }

        // 页面加载完成后初始化
        document.addEventListener(\'DOMContentLoaded\', () => {
            initTimelineAnimations-{ num }();
        });
    </script>
    </body>
    </html>'''
}
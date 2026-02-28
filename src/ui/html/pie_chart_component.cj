/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.ui.html

import magic.dsl.*
import magic.prelude.*



@jsonable
public class PieChartData {
    @field["The title of the chart"]
    let title: String
    @field["Compare the categories of items"]
    let categories: Array<String>
    @field["The length of the array is the same as that of categories, and the content in desc[i] is used to describe categories[i]"]
    let desc: Array<String>
    @field["The length of the array is the same as that of categories, and the data in PCT[i] corresponds to the proportion of categories[i] in the whole, the sum of all item data in PCT is 100"]
    let PCT: Array<Int64>
}

@ui[description: '''
    功能类型：饼图 UI・占比数据可视化型,
    使用场景：展示数据分类占比信息，如旅游支出占比（交通 / 住宿 / 餐饮）、美食消费占比（中餐 / 西餐 / 小吃）、用户偏好占比、订单来源渠道占比,
    交互特性：数据可视化型，将抽象数据转化为可视化图表，便于理解分析,
    风格属性：图表型
    ''',
    kind: "display"
]
public func pieChartUI(data: PieChartData) {
    '''
    <!DOCTYPE html>
    <html lang="zh-CN">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>自适应交互式饼图</title>
        <link href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css" rel="stylesheet">
        <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.8/dist/chart.umd.min.js"></script>
        <style>
            .pie-container {
                max-width: 100%;
                margin: 0 auto;
                padding: clamp(1rem, 3vw, 2rem);
            }

            .pie-card {
                background-color: white;
                border-radius: clamp(0.75rem, 2vw, 1.25rem);
                box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
                overflow: hidden;
            }

            .pie-card-body {
                padding: clamp(1rem, 3vw, 1.5rem);
            }

            .pie-chart-container {
                position: relative;
                width: 100%;
                /* 动态计算高度，保持图表比例 */
                height: clamp(300px, 50vh, 500px);
            }

            .pie-card-footer {
                padding: clamp(1rem, 3vw, 1.5rem);
                background-color: hsl(210, 17%, 98%);
                border-top: 1px solid hsl(210, 14%, 93%);
            }

            .pie-stats-grid {
                display: grid;
                grid-template-columns: 1fr;
                gap: clamp(0.75rem, 2vw, 1.25rem);
            }

            @media (min-width: 640px) {
                .pie-stats-grid {
                    grid-template-columns: repeat(2, 1fr);
                }
            }

            @media (min-width: 1024px) {
                .pie-stats-grid {
                    grid-template-columns: repeat(3, 1fr);
                }
            }

            .pie-stat-card {
                background-color: white;
                padding: clamp(0.75rem, 2vw, 1rem);
                border-radius: clamp(0.375rem, 1vw, 0.5rem);
                box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06);
                border: 1px solid hsl(216, 16%, 95%);
                transition: box-shadow 0.3s ease;
            }

            .pie-stat-card:hover {
                box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
            }

            .pie-stat-header {
                display: flex;
                align-items: center;
            }

            .pie-stat-dot {
                width: clamp(0.5rem, 1.5vw, 0.75rem);
                height: clamp(0.5rem, 1.5vw, 0.75rem);
                border-radius: 50%;
                margin-right: clamp(0.25rem, 1vw, 0.5rem);
            }

            .pie-stat-title {
                font-weight: 500;
                font-size: clamp(0.875rem, 2vw, 1rem);
            }

            .pie-stat-description {
                font-size: clamp(0.75rem, 1.5vw, 0.875rem);
                color: hsl(220, 14%, 41%);
                margin-top: 0.25rem;
            }
        </style>
    </head>
    <body>
    <div class="pie-container">
        <div class="pie-card">
            <div class="pie-card-body">
                <div class="pie-chart-container">
                    <canvas id="salesPieChart-{ num }"></canvas>
                </div>
            </div>
            <div class="pie-card-footer">
                <div class="pie-stats-grid">
                    {% for i in 0..data.categories.size %}
                    <div class="pie-stat-card">
                        <div class="stat-header">
                            <div class="pie-stat-dot" style="background-color: hsl(217, 91%, 60%);"></div>
                            <span class="pie-stat-title">{% data.categories[i] %}</span>
                        </div>
                        <p class="pie-stat-description">{% data.desc[i] %}</p>
                    </div>
                    {% /for %}
                </div>
            </div>
        </div>
    </div>

    <script>
        document.addEventListener('DOMContentLoaded', function() {
            const ctxPie-{ num } = document.getElementById('salesPieChart-{ num }').getContext('2d');
            const pieKind-{ num } = '{% data.categories %}'.slice(1, -1).split(",").map(item => `'\${item.trim()}'`);

            const data-{ num } = {
                labels: pieKind-{ num },
                datasets: [{
                    data: {% data.PCT %},
                    borderWidth: 2,
                    hoverOffset: 20,
                    borderRadius: 6,
                }]
            };

            // 响应式配置
            const isSmallScreen-{ num } = window.innerWidth < 640;

            const config-{ num } = {
                type: 'pie',
                data: data-{ num },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            position: isSmallScreen-{ num } ? 'bottom' : 'right',
                            labels: {
                                padding: isSmallScreen-{ num } ? 10 : 20,
                                font: {
                                    size: isSmallScreen-{ num } ? 12 : 14,
                                    family: 'Inter'
                                },
                                usePointStyle: true,
                                pointStyle: 'circle'
                            }
                        },
                        tooltip: {
                            backgroundColor: 'hsla(222, 47%, 11%, 0.9)',
                            titleFont: {
                                size: isSmallScreen-{ num } ? 14 : 16,
                                family: 'Inter',
                                weight: 'bold'
                            },
                            bodyFont: {
                                size: isSmallScreen-{ num } ? 12 : 14,
                                family: 'Inter'
                            },
                            padding: 12,
                            cornerRadius: 8,
                            displayColors: true,
                            callbacks: {
                                label: function(context) {
                                    const label = context.label || '';
                                    const value = context.raw || 0;
                                    const total = context.dataset.data.reduce((acc, val) => acc + val, 0);
                                    const percentage = Math.round((value / total) * 100);
                                    return `\${label}: \${percentage}%`;
                                }
                            }
                        },
                        title: {
                            display: true,
                            text: '{% data.title %}',
                            font: {
                                size: isSmallScreen-{ num } ? 16 : 18,
                                family: 'Inter',
                                weight: 'bold'
                            },
                            padding: {
                                top: 10,
                                bottom: 20
                            }
                        }
                    },
                    animation: {
                        animateRotate: true,
                        animateScale: true,
                        duration: 2000,
                        easing: 'easeOutQuart'
                    },
                    cutout: isSmallScreen-{ num } ? '30%' : '20%',
                    elements: {
                        arc: {
                            borderWidth: 1
                        }
                    }
                }
            };

            const myPieChart-{ num } = new Chart(ctxPie-{ num }, config-{ num });

            // 窗口大小变化时重新渲染图表
            window.addEventListener('resize', function() {
                myPieChart-{ num }.destroy();
                const newIsSmallScreen = window.innerWidth < 640;

                // 更新配置
                config-{ num }.options.plugins.legend.position = newIsSmallScreen ? 'bottom' : 'right';
                config-{ num }.options.plugins.legend.labels.padding = newIsSmallScreen ? 10 : 20;
                config-{ num }.options.plugins.legend.labels.font.size = newIsSmallScreen ? 12 : 14;
                config-{ num }.options.plugins.title.font.size = newIsSmallScreen ? 16 : 18;
                config-{ num }.options.cutout = newIsSmallScreen ? '30%' : '20%';

                // 重新创建图表
                myPieChart-{ num } = new Chart(ctxPie-{ num }, config-{ num });
            });
        });
    </script>
    </body>
    </html>
    '''
}
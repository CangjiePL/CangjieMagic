/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.ui.html

import magic.dsl.*
import magic.prelude.*



@jsonable
public class LineItemData {
    @field["legend"]
    let name: String
    @field["Data Information Array"]
    let data: Array<Int64>
}

@jsonable
public class LineChartData {
    @field["The title of the chart"]
    let title: String
    @field["Label of the horizontal axis (x-axis)"]
    let xLabel: String
    @field["Label of the vertical axis (y-axis)"]
    let yLabel: String
    @field["A specific value or classification on an x-axis"]
    let xAxisLabel: Array<String>
    @field["One or more sets of data information"]
    let dataArr: Array<LineItemData>
}

@ui[description: '''
    功能类型：折线图 UI・趋势数据可视化型,
    使用场景：展示数据变化趋势信息，如天气变化趋势、景点客流量变化、美食店营收波动、用户活跃度走势、项目进度完成率趋势,
    交互特性：数据可视化型，将抽象数据转化为可视化图表，便于理解分析,
    风格属性：图表型
    ''',
    kind: "display"
]
public func lineChartUI(data: LineChartData) {
    '''
    <!DOCTYPE html>
    <html lang="zh-CN">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>交互式折线图</title>
        <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.8/dist/chart.umd.min.js"></script>
        <style>
            .line-chart-container {
                position: relative;
                margin: 20px;
                height: 400px;
            }
            .line-chart-controls {
                display: flex;
                flex-wrap: wrap;
                gap: 10px;
                margin-bottom: 20px;
            }
            .line-chat-btn {
                padding: 8px 16px;


                background-color: hsl(217, 89%, 61%);
                color: white;
                border: none;
                border-radius: 4px;
                cursor: pointer;
                transition: background-color 0.2s;
            }
            .line-chat-btn:hover {
                background-color: hsl(221, 67%, 52%);
            }
        </style>
    </head>
    <body>
    <h3>{% data.title %}</h3>
    <div class="line-chart-controls">
        <button class="line-chat-btn" id="toggleSmooth-{ num }">切换平滑曲线</button>
        <button class="line-chat-btn" id="togglePoints-{ num }">显示/隐藏数据点</button>
    </div>

    <div class="line-chart-container">
        <canvas id="lineChart-{ num }"></canvas>
    </div>

    <script>
        // 基础数据
        const months-{ num } = '{% data.xAxisLabel %}'.slice(1, -1).split(",").map(item => `'\${item.trim()}'`);

        // 初始化图表
        let lineChart-{ num };
        let isSmooth-{ num } = true;
        let showPoints-{ num } = true;

        function initChart-{ num }() {
            const ctx = document.getElementById('lineChart-{ num }').getContext('2d');

            const dataList = [];
            {% for item in data.dataArr %}
                dataList.push({
                    label: '{% item.name %}',
                    data: {% item.data %},
                    tension: isSmooth-{ num } ? 0.4 : 0,
                    pointRadius: showPoints-{ num } ? 4 : 0,
                });
            {% /for %}

            // 创建图表
            lineChart-{ num } = new Chart(ctx, {
                type: 'line',
                data: {
                    labels: months-{ num },
                    datasets: dataList
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            position: 'top',
                        },
                        tooltip: {
                            mode: 'index',
                            intersect: false,
                            callbacks: {
                                label: function(context) {
                                    let label = context.dataset.label || '';
                                    if (label) {
                                        label += ': ';
                                    }
                                    label += context.parsed.y;
                                    return label;
                                }
                            }
                        }
                    },
                    scales: {
                        y: {
                            beginAtZero: true,
                            title: {
                                display: true,
                                text: '{% data.yLabel %}'
                            }
                        },
                        x: {
                            title: {
                                display: true,
                                text: '{% data.xLabel %}'
                            }
                        }
                    },
                    interaction: {
                        mode: 'nearest',
                        axis: 'x',
                        intersect: false
                    },
                    animations: {
                        tension: {
                            duration: 1000,
                            easing: 'linear'
                        }
                    }
                }
            });
        }

        // 初始化图表
        initChart-{ num }();

        document.getElementById('toggleSmooth-{ num }').addEventListener('click', function() {
            isSmooth-{ num } = !isSmooth-{ num };
            lineChart-{ num }.data.datasets.forEach(dataset => {
                dataset.tension = isSmooth-{ num } ? 0.4 : 0;
            });
            lineChart-{ num }.update();
        });

        document.getElementById('togglePoints-{ num }').addEventListener('click', function() {
            showPoints-{ num } = !showPoints-{ num };
            lineChart-{ num }.data.datasets.forEach(dataset => {
                dataset.pointRadius = showPoints-{ num } ? 4 : 0;
            });
            lineChart-{ num }.update();
        });
    </script>
    </body>
    </html>
    '''
}
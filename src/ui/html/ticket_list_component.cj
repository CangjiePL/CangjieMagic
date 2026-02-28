/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.ui.html

import magic.dsl.*
import magic.prelude.*



@jsonable
public class TicketInfo {
    @field["Train number or flight number"]
    let tripID: String
    @field["The name of the departure station"]
    let startStation: String
    @field["Departure time, the year is not required, such as '6月1日 周日 8:00'"]
    let startTime: String
    @field["Destination Station"]
    let endStation: String
    @field["Arrival time, the year is not required, such as '6月1日 周日 11:00'"]
    let endTime: String
    @field["Travel Time, such as '3小时20分'"]
    let duration: String
    @field["Ticket Price, sucn as '二等座 ￥100.00'"]
    let price: String
    @field["Departure date, such as '2025-06-01'"]
    let data: String
    @field["Seat information, such as '12车05A号'"]
    let seatInfo: String
    //    @field["The name of the passenger"]
    //    let name: String
    //    @field["QR code URL"]
    //    let qrCode: String
}

@ui[description: '''
    功能类型：车票展示 UI・出行凭证型，
    使用场景：展示出行类凭证核心信息，如高铁 / 火车票信息（车次 / 时间 / 座位）、飞机登机牌信息（航班 / 航站楼 / 座位）、汽车票信息（线路 / 时间 / 座位）、地铁票信息（站点 / 票价 / 有效期）、景区接驳车票信息（线路 / 发车时间），
    交互特性：信息展示型，不支持编辑车票信息，
    风格属性：简约型，仅适合特定场景
    ''',
    kind: "display"
]
public func ticketListUI(arr: Array<TicketInfo>) {
    '''
    <!DOCTYPE html>
    <html lang="zh-CN">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>车票列表</title>
        <link href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css" rel="stylesheet">
        <style>
            .ticket-list {
                display: grid;
                grid-template-columns: 1fr;
                gap: 20px;
            }

            .ticket {
                background-color: white;
                border-radius: 10px;
                box-shadow: 0 4px 15px hsla(210, 22%, 49%, 0.1);
                overflow: hidden;
                transition: transform 0.2s ease;
            }

            .ticket:hover {
                transform: translateY(-3px);
            }

            .ticket-header {
                background-color: hsl(205, 78%, 60%);
                color: white;
                padding: 15px 20px;
                display: flex;
                justify-content: space-between;
                align-items: center;
            }

            .train-number {
                font-size: 18px;
                font-weight: bold;
            }

            .ticket-type {
                background-color: hsla(0, 0%, 100%, 0.2);
                padding: 3px 8px;
                border-radius: 4px;
                font-size: 14px;
            }

            .ticket-body {
                padding: 20px;
            }

            .ticket-journey-info {
                display: flex;
                justify-content: space-between;
                align-items: center;
                margin-bottom: 15px;
            }

            .ticket-station {
                font-size: 22px;
                font-weight: bold;
            }

            .ticket-time {
                font-size: 14px;
                color: hsl(210, 22%, 49%);
            }

            .ticket-duration {
                text-align: center;
                color: hsl(205, 78%, 60%);
                font-size: 14px;
                width: 100px;
            }

            .ticket-details {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
                gap: 10px;
                margin-top: 15px;
                font-size: 14px;
            }

            .ticket-detail-item {
                display: flex;
                flex-direction: column;
            }

            .ticket-detail-label {
                color: hsl(210, 22%, 49%);
                font-size: 12px;
            }

            .dashed-line {
                height: 1px;
                border-top: 2px dashed hsla(210, 22%, 49%, 0.2);
                margin: 15px 0;
            }

            .ticket-actions {
                display: flex;
                justify-content: flex-end;
                padding: 15px 20px;
                background-color: hsl(210, 36%, 98%);
            }

            .ticket-btn {
                padding: 8px 15px;
                border-radius: 4px;
                cursor: pointer;
                font-size: 14px;
                transition: background-color 0.2s ease;
                margin-left: 10px;
            }

            .ticket-btn-view {
                background-color: hsl(205, 78%, 60%);
                color: white;
                border: none;
            }

            .ticket-btn-view:hover {
                background-color: hsl(205, 68%, 50%);
            }

            .ticket-btn-cancel {
                background-color: hsl(0, 0%, 90%);
                color: hsl(209, 61%, 16%);
                border: none;
            }

            .ticket-btn-cancel:hover {
                background-color: hsl(0, 0%, 80%);
            }

            @media (max-width: 500px) {
                .ticket-header {
                    flex-direction: column;
                    align-items: flex-start;
                }

                .ticket-type {
                    margin-top: 5px;
                }

                .ticket-journey-info {
                    flex-direction: column;
                    text-align: center;
                }

                .ticket-duration {
                    margin: 15px 0;
                }

                .ticket-details {
                    grid-template-columns: 1fr 1fr;
                }
            }
        </style>
    </head>
    <body>
    <div class="container">
        <h3>我的车票</h3>

        <div class="ticket-list">
        {% for item in arr %}
            <div class="ticket">
                <div class="ticket-header">
                    <div class="train-number">{% item.tripID %}</div>
                    <div class="ticket-type">电子票</div>
                </div>
                <div class="ticket-body">
                    <div class="ticket-journey-info">
                        <div>
                            <div class="ticket-station">{% item.startStation %}</div>
                            <div class="ticket-time">{% item.startTime %}</div>
                        </div>
                        <div class="ticket-duration">
                            <i class="fa fa-train" aria-hidden="true"></i> {% item.duration %}
                        </div>
                        <div>
                            <div class="ticket-station">{% item.endStation %}</div>
                            <div class="ticket-time">{% item.endTime %}</div>
                        </div>
                    </div>

                    <div class="dashed-line"></div>

                    <div class="ticket-details">
                        <div class="ticket-detail-item">
                            <div class="ticket-detail-label">日期</div>
                            <div>{% item.data %}</div>
                        </div>
                        <div class="ticket-detail-item">
                            <div class="ticket-detail-label">座位</div>
                            <div>{% item.seatInfo %}</div>
                        </div>
                        <div class="ticket-detail-item">
                            <div class="ticket-detail-label">票价</div>
                            <div>{% item.price %}</div>
                        </div>
    <!--                    <div class="ticket-detail-item">-->
    <!--                        <div class="ticket-detail-label">乘客</div>-->
    <!--                        <div></div>-->
    <!--                    </div>-->
                    </div>
                </div>
                <div class="ticket-actions">
                    <button class="ticket-btn ticket-btn-cancel">退票</button>
                    <button class="ticket-btn ticket-btn-view">查看详情</button>
                </div>
            </div>
        {% /for %}
        </div>
    </div>
    </body>
    </html>
    '''
}

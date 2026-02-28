/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.ui.html

import magic.dsl.*
import magic.prelude.*



@jsonable
public class MeetingInfo {
    @field["Conference subject"]
    let subject: String
    @field["Meeting time, displayed in the format '2025-06-10 09:30-10:30'"]
    let time: String
    @field["Meeting location"]
    let location: String
    @field["Convener of the meeting"]
    let convener: String
    @field["Attendees"]
    let attendees: String
    @field["Description of the meeting"]
    let description: String
    @field["Meeting link"]
    let url: String
}

@ui[description: '''
    功能类型：会议信息展示 UI,
    使用场景：展示会议相关核心信息，如会议名称 / 时间 / 地点、参会人员名单、会议纪要摘要,
    交互特性：信息展示型，仅用于呈现信息，无交互,
    风格属性：简约型，仅适合特定场景
    ''',
    kind: "display"
]
public func meetingUI(info: MeetingInfo) {
    '''
    <!DOCTYPE html>
    <html lang="zh-CN">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>会议通知</title>
        <script src="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/js/font-awesome.min.js"></script>
        <style>
            main {
                flex-grow: 1;
                padding: 1.5rem 0;
            }

            .meeting-card {
                background-color: var(--white);
                border-radius: 0.75rem;
                box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
                overflow: hidden;
                margin-bottom: 2rem;
                animation: fadeIn 0.5s ease-in-out;
            }

            @keyframes fadeIn {
                from { opacity: 0; }
                to { opacity: 1; }
            }

            .meeting-card-header {
                position: relative;
            }

            .meeting-card-header::before {
                content: '';
                position: absolute;
                top: 0;
                left: 0;
                width: 100%;
                height: 0.25rem;
                background: linear-gradient(90deg, var(--primary), var(--secondary));
            }

            .meeting-card-content {
                padding: 1.5rem;
            }

            @media (min-width: 768px) {
                .meeting-card-content {
                    padding: 2rem;
                }
            }

            .meeting-header {
                display: flex;
                flex-direction: column;
                margin-bottom: 1.5rem;
            }

            @media (min-width: 768px) {
                .meeting-header {
                    flex-direction: row;
                    align-items: center;
                    justify-content: space-between;
                }
            }

            .meeting-title {
                font-size: clamp(1.25rem, 3vw, 2rem);
                font-weight: bold;
                color: var(--dark);
                margin-bottom: 0.75rem;
                text-shadow: 0 1px 2px rgba(0,0,0,0.1);
            }

            .meeting-info {
                display: flex;
                flex-wrap: wrap;
                align-items: center;
                gap: 1rem;
                color: var(--gray-600);
                font-size: 0.875rem;
            }

            .meeting-info-item {
                display: flex;
                align-items: center;
                gap: 0.5rem;
            }

            .meeting-info i {
                color: var(--primary);
            }

            .meeting-details {
                display: grid;
                grid-template-columns: 1fr;
                gap: 1.5rem;
                margin-bottom: 2rem;
            }

            .meeting-detail-group {
                background-color: var(--gray-100);
                border-radius: 0.5rem;
                padding: 1rem;
            }

            .meeting-detail-title {
                font-size: 1rem;
                font-weight: 600;
                color: var(--dark);
                margin-bottom: 0.75rem;
                display: flex;
                align-items: center;
                gap: 0.5rem;
            }

            .meeting-detail-title i {
                color: var(--primary);
            }

            .meeting-detail-list {
                list-style: none;
            }

            .meeting-detail-item {
                margin-bottom: 0.75rem;
                display: flex;
                flex-direction: column;
            }

            .meeting-detail-label {
                font-size: 0.875rem;
                color: var(--gray-500);
                margin-bottom: 0.25rem;
            }

            .meeting-detail-value {
                font-size: 0.9375rem;
                color: var(--gray-800);
            }

            .meeting-description {
                margin-bottom: 2rem;
            }

            .meeting-description-title {
                font-size: 1.25rem;
                font-weight: 600;
                color: var(--dark);
                margin-bottom: 1rem;
                display: flex;
                align-items: center;
                gap: 0.5rem;
            }

            .meeting-description-title i {
                color: var(--primary);
            }

            .meeting-description-content {
                line-height: 1.6;
                color: var(--gray-700);
                text-align: justify;
            }
        </style>
    </head>
    <body>
    <!-- 主要内容 -->
    <main class="container">
        <!-- 会议通知卡片 -->
        <div class="meeting-card">
            <div class="meeting-card-header">
                <div class="meeting-card-content">
                    <div class="meeting-header">
                        <div>
                            <h2 class="meeting-title">{% info.subject %}</h2>
                            <div class="meeting-info">
                                <div class="meeting-info-item">
                                    <i class="fa fa-user-o"></i>
                                    <span>发起人：{% info.convener %}</span>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="meeting-details">
                        <div class="meeting-detail-group">
                            <h3 class="meeting-detail-title">
                                <i class="fa fa-calendar-check-o"></i>
                                会议基本信息
                            </h3>
                            <ul class="meeting-detail-list">
                                <li class="meeting-detail-item">
                                    <span class="detail-label">会议主题</span>
                                    <span class="detail-value">{% info.subject %}</span>
                                </li>
                                <li class="meeting-detail-item">
                                    <span class="detail-label">会议时间</span>
                                    <span class="detail-value">{% info.time %}</span>
                                </li>
                                <li class="meeting-detail-item">
                                    <span class="meeting-detail-label">会议链接</span>
                                    <span class="meeting-detail-value"><a href=\"{% info.url %}\">{% info.url %}</a></span>
                                </li>
                                <li class="meeting-detail-item">
                                    <span class="meeting-detail-label">会议地点</span>
                                    <span class="meeting-detail-value">{% info.location %}</span>
                                </li>
                                <li class="meeting-detail-item">
                                    <span class="meeting-detail-label">召集人</span>
                                    <span class="meeting-detail-value">{% info.convener %}</span>
                                </li>
                                <li class="meeting-detail-item">
                                    <span class="meeting-detail-label">参会人员</span>
                                    <span class="meeting-detail-value">{% info.attendees %}</span>
                                </li>
                            </ul>
                        </div>
                    </div>

                    <div class="meeting-description">
                        <h3 class="meeting-description-title">
                            <i class="fa fa-file-text-o"></i>
                            会议描述
                        </h3>
                        <div class="meeting-description-content">
                            {% info.description %}
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </main>
    </body>
    </html>
    '''
}
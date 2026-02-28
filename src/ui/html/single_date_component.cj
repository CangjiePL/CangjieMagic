/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.ui.html

import magic.dsl.*
import magic.prelude.*



@ui[
    description: '''
    功能类型：选择单个日期 UI・单点筛选型,
    使用场景：选择特定单个日期的相关操作，如日程安排日期选择、生日设置、订单创建日期查询、活动参与日期选择、预约服务日期确认，
    交互特性：数据录入型，支持滑动选择单个日期，
    风格属性：简约通用型
    ''',
    parameters: {
        title: "描述特定选择日期事件的标题"
    },
    kind: "input"
]
public func singleDateUI(title: String) {
    '''
    <!DOCTYPE html>
    <html lang="zh-CN">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>单程车票日期选择</title>
        <style>
            /* 表单样式 */
            .date-form-group {
                margin-bottom: 16px;
            }

            .date-form-group label {
                display: block;
                color: hsl(210, 20%, 30%);
                margin-bottom: 8px;
                font-size: 14px;
            }

            .date-form-group input[type="date"] {
                width: 100%;
                padding: 10px 12px;
                border: 1px solid hsl(210, 20%, 70%);
                border-radius: 6px;
                font-size: 16px;
                color: hsl(210, 20%, 30%);
                box-sizing: border-box;
            }

            .date-form-group input[type="date"]:focus {
                outline: none;
                border-color: hsl(217, 89%, 61%);
                box-shadow: 0 0 0 2px hsla(217, 89%, 61%, 0.2);
            }
        </style>
    </head>
    <body>
    <div class="container">
        <div class="card">
            <h3 class="date-title">{% title %}</h3>
            <form>
                <div class="date-form-group">
                    <label for="departure-date-{ num }">日期选择：</label>
                    <input type="date" id="departure-date-{ num }" required>
                </div>
            </form>
        </div>
    </div>

    <script>
        // 获取DOM元素
        const departureDate-{ num } = document.getElementById('departure-date-{ num }');

        // 设置默认日期为今天
        const today-{ num } = new Date().toISOString().split('T')[0];
        departureDate-{ num }.value = today-{ num };

        // 日期格式化函数
        function formatDate-{ num }(dateString) {
            const date = new Date(dateString);
            const year = date.getFullYear();
            const month = String(date.getMonth() + 1).padStart(2, '0');
            const day = String(date.getDate()).padStart(2, '0');
            return `\${year}年\${month}月\${day}日`;
        }
    </script>
    </body>
    </html>
    '''
}
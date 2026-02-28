/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.ui.html

import magic.dsl.*
import magic.prelude.*



@ui[
    description: '''
    功能类型：文本输入框 UI・信息录入型,
    使用场景：用于各类文本信息录入操作，如会议备注输入、用户基本信息录入,
    交互特性：数据录入型，支持手动输入文本，
    风格属性：简约通用型，仅当其他UI均不适合时才选用
    ''',
    parameters: {
        title: "描述需要输入文本内容的标题"
    },
    kind: "input"
]
public func textAreaUI(title: String) {
    '''
    <!DOCTYPE html>
    <html lang="zh-CN">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>简单多行输入框</title>
        <style>
            textarea {
                width: 100%;
                padding: 10px;
                border: 1px solid hsl(0, 0%, 86%);
                border-radius: 4px;
                min-height: 120px;
                resize: vertical; /* 允许垂直调整大小 */
                font-family: inherit; /* 继承父元素字体 */
                font-size: 16px;
                box-sizing: border-box;
            }
            textarea:focus {
                outline: none;
                border-color:  hsl(217, 98%, 65%);
                box-shadow: 0 0 0 2px rgba(77, 144, 254, 0.2);
            }
            .info {
                color: hsl(0, 0%, 40%);
                font-size: 14px;
                margin-top: 5px;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="card">
                 <h3 class="input-title"><i class="fa fa-pencil-square"></i> {% title %}</h3>
                <textarea
                    class="input-comment"
                    placeholder="请输入..."
                    maxlength="1500"
                ></textarea>
                <div class="info">最多输入1500个字符，可换行</div>
            </div>
        </div>
    </body>
    </html>
    '''
}
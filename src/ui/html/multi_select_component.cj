/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.ui.html

import magic.dsl.*
import magic.prelude.*



@ui[
    description: '''
    功能类型：多选 UI・多点选项选择型,
    使用场景：需从多个选项中选择多个结果，如景点标签筛选（自然 / 人文 / 亲子）、美食口味选择（微辣 / 酸甜 / 清淡）、问卷多选题答题、兴趣爱好勾选,
    交互特性：操作交互型，支持点击选中 / 取消多个选项；选中状态高亮提示；,
    风格属性：简约通用型
    ''',
    parameters: {
        info: "选项列表"
    },
    kind: "input"
]
public func multiListUI(info: OptionInfo) {
    '''
    <!DOCTYPE html>
    <html lang="zh-CN">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>自定义多选按钮列表</title>
        <style>
            .checkbox-multi-group {
                display: flex;
                flex-direction: column;
                gap: 0.75rem;
                margin-bottom: 1.5rem;
            }

            .checkbox-multi-item {
                display: flex;
                align-items: center;
                padding: 1rem;
                border-radius: 0.25rem;
                border: 1px solid var(--gray-200);
                transition: all 0.3s ease;
            }

            .checkbox-multi-item:hover {
                border-color: hsla(220, 100%, 54%, 0.5);
                background-color: hsla(220, 100%, 54%, 0.05);
            }

            .checkbox-multi-item input[type="checkbox"] {
                width: 1.25rem;
                height: 1.25rem;
                color: var(--primary);
                border: 1px solid var(--gray-300);
                border-radius: 0.25rem;
                margin-right: 0.75rem;
            }

            .input-multi-group {
                display: flex;
                gap: 0.5rem;
                margin-bottom: 1rem;
            }

            .new-multi-option {
                flex: 1;
                padding: 0.5rem;
                border: 1px solid hsl(210, 22%, 49%);
                border-radius: 0.25rem;
                font-size: 1rem;
            }

            .add-option-multi-btn {
                padding: 0.5rem 0.5rem;
                border: none;
                border-radius: 0.25rem;
                background-color: var(--primary);
                color: white;
                font-size: 1rem;
                cursor: pointer;
                transition: background-color 0.3s;
            }

            .add-option-multi-btn:hover {
                background-color: hsl(205, 63%, 48%);
            }
        </style>
    </head>
    <body>
    <div class="container">
        <div class="card">
            <h3 class="multi-title"><i class="fa fa-list-ul"></i> {% info.title %}</h3>

            <div id="checkboxMultiGroup-{ num }" class="checkbox-multi-group">
                {% for item in info.arr %}
                    <label class="checkbox-multi-item">
                        <input type="checkbox">{% item %}
                    </label>
                {% /for %}
            </div>

            <div class="input-multi-group">
                <input type="text" class="new-multi-option" id="newMultiOption-{ num }" placeholder="请输入...">
                <button class="add-option-multi-btn" id="addOptionMultiBtn-{ num }">添加选项</button>
            </div>
        </div>
    </div>

    <script>
        document.addEventListener('DOMContentLoaded', function() {
            const checkboxMultiGroup-{ num } = document.getElementById('checkboxMultiGroup-{ num }');
            const newOptionInput-{ num } = document.getElementById('newMultiOption-{ num }');
            const addOptionMultiBtn-{ num } = document.getElementById('addOptionMultiBtn-{ num }');

            // 添加新选项
            addOptionMultiBtn-{ num }.addEventListener('click', function() {
                const optionText = newOptionInput-{ num }.value.trim();
                if (optionText) {
                    // 生成唯一值
                    const optionValue = optionText.toLowerCase();

                    // 检查选项是否已存在
                    const exists = Array.from(checkboxMultiGroup-{ num }.querySelectorAll('input[type="checkbox"]'))
                        .some(checkbox => checkbox.value === optionValue);

                    if (!exists) {
                        const checkboxItem = document.createElement('label');
                        checkboxItem.className = 'checkbox-multi-item';

                        const checkbox = document.createElement('input');
                        checkbox.type = 'checkbox';
                        checkbox.value = optionValue;

                        const textNode = document.createTextNode(' ' + optionText);

                        checkboxItem.appendChild(checkbox);
                        checkboxItem.appendChild(textNode);
                        checkboxMultiGroup-{ num }.appendChild(checkboxItem);

                        newOptionInput-{ num }.value = '';
                    } else {
                        alert('该选项已存在!');
                    }
                } else {
                    alert('请输入选项名称!');
                }
            });
        });
    </script>
    </body>
    </html>
    '''
}
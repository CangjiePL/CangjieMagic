/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.ui.html

import magic.dsl.*
import magic.prelude.*



@jsonable
public class OptionInfo {
    @field["Title"]
    public let title: String
    @field["A list of options, all of which are fixed presets, with no 'other' or custom choices."]
    public let arr: Array<String>
}

@ui[description: '''
    功能类型：单选 UI・单点选项选择型,
    使用场景：需从多个选项中选择唯一结果，如问卷答题选择、订单支付方式选择、性别 / 身份类型选择、偏好设置单选（如口味 / 风格）.
    交互特性：操作交互型，支持点击选中单个选项；
    风格属性：简约通用型
    ''',
     parameters: {
        info: "选项列表"
     },
     kind: "input"
]
public func radioListUI(info: OptionInfo) {
    '''
    <!DOCTYPE html>
    <html lang="zh-CN">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>自定义选择列表</title>
        <link href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css" rel="stylesheet">
        <style>
            .card:hover {
                box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
            }

            .option-radio-group {
                display: flex;
                flex-direction: column;
                gap: 0.75rem;
                margin-bottom: 1.5rem;
            }

            .option-radio-card {
                display: flex;
                align-items: center;
                padding: 1rem;
                border-radius: 0.5rem;
                border: 1px solid var(--gray-200);
                cursor: pointer;
                transition: all 0.3s ease;
            }

            .option-radio-card:hover {
                border-color: hsla(220, 100%, 54%, 0.5);
                background-color: hsla(220, 100%, 54%, 0.05);
            }

            .option-radio-card input[type="radio"] {
                width: 1.25rem;
                height: 1.25rem;
                color: var(--primary);
                border: 1px solid var(--gray-300);
                border-radius: 50%;
                appearance: none;
                -webkit-appearance: none;
                outline: none;
                cursor: pointer;
                position: relative;
            }

            .option-radio-card input[type="radio"]:checked {
                border-color: var(--primary);
            }

            .option-radio-card input[type="radio"]:checked::before {
                content: '';
                width: 0.75rem;
                height: 0.75rem;
                background-color: var(--primary);
                border-radius: 50%;
                position: absolute;
                top: 50%;
                left: 50%;
                transform: translate(-50%, -50%);
            }

            .option-radio-card span {
                margin-left: 0.75rem;
            }

            .custom-radio-inputs {
                background-color: white;
                padding: 1.25rem;
                border-radius: 0.5rem;
                box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
                border: 1px solid var(--gray-200);
                display: none;
            }

            .input-radio-group {
                margin-bottom: 1rem;
            }

            .input-radio-label {
                display: block;
                font-size: 0.875rem;
                font-weight: 500;
                color: var(--gray-700);
                margin-bottom: 0.25rem;
            }

            .custom-radio-input {
                width: 100%;
                padding: 0.5rem 0.75rem;
                border: 1px solid var(--gray-300);
                border-radius: 0.375rem;
                box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
                outline: none;
                transition: all 0.15s ease-in-out;
            }

            .custom-radio-input:focus {
                border-color: var(--primary);
                box-shadow: 0 0 0 2px hsla(220, 100%, 54%, 0.2);
            }
        </style>
    </head>
    <body>
    <div class="container">
        <div class="card">
            <h3 class="radio-title"><i class="fa fa-list-ul"></i> {% info.title %}</h3>

            <div class="option-radio-group">
                {% for item in info.arr %}
                    <label class="option-radio-card">
                        <input type="radio" name="radio-name-{ num }" value=\"{% item %}\">
                        <span>{% item %}</span>
                    </label>
                {% /for %}

                <label class="option-radio-card">
                    <input type="radio" name="radio-name-{ num }" value="custom">
                    <span>其他(自定义)</span>
                </label>
            </div>

            <div id="customRadioOption-{ num }" class="custom-radio-inputs">
                <div class="input-radio-group">
                    <label for="customRadioLabel" class="input-radio-label">请输入您选择:</label>
                    <input type="text" class="custom-radio-input">
                </div>
            </div>
        </div>
    </div>

    <script>
        // 获取DOM元素
        const customRadio-{ num } = document.querySelector('input[name="radio-name-{ num }"][value="custom"]');
        const customRadioOption-{ num } = document.getElementById('customRadioOption-{ num }');

        // 初始隐藏自定义选项
        customRadioOption-{ num }.style.display = 'none';

        // 切换自定义选项的显示/隐藏
        customRadio-{ num }.addEventListener('change', function() {
            if (this.checked) {
                customRadioOption-{ num }.style.display = 'block';
            } else {
                customRadioOption-{ num }.style.display = 'none';
            }
        });
    </script>
    </body>
    </html>
    '''
}

@template
public func template_drop_list(info: OptionInfo) {
    '''
    <!DOCTYPE html>
    <html lang="zh-CN">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>可自定义输入的下拉框</title>
        <link href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css" rel="stylesheet">
        <style>
            .drop-container {
                max-width: 600px;
                margin: 0 auto;
                padding: 2rem;
            }

            .drop-card {
                background-color: white;
                border-radius: 1rem;
                box-shadow: 0 4px 6px -1px hsla(215, 28%, 17%, 0.1), 0 2px 4px -1px hsla(215, 28%, 17%, 0.06);
                margin-bottom: 2rem;
                padding: 2rem;
            }

            .custom-drop-container {
                margin-bottom: 2rem;
                position: relative; /* 添加相对定位 */
            }

            .custom-drop {
                width: 100%;
                border: 1px solid hsl(216, 16%, 95%);
                border-radius: 0.5rem;
                padding: 0.75rem 1rem;
                display: flex;
                align-items: center;
                justify-content: space-between;
                cursor: pointer;
                transition: all 0.2s ease;
            }

            .custom-drop:focus-within {
                border-color: hsl(217, 91%, 60%);
                box-shadow: 0 0 0 2px hsla(217, 91%, 60%, 0.2);
            }

            .custom-drop input[type="drop-text"] {
                flex-grow: 1;
                background: transparent;
                border: none;
                outline: none;
                color: hsl(215, 28%, 17%);
            }

            .drop-icon {
                font-size: 1.25rem;
                color: hsl(220, 14%, 41%);
                transition: transform 0.2s ease;
            }

            .drop-options {
                position: absolute;
                top: calc(100% + 0.25rem); /* 减小与输入框的间距 */
                left: 0;
                right: 0;
                background-color: white;
                border: 1px solid hsl(216, 16%, 95%);
                border-radius: 0.5rem;
                box-shadow: 0 4px 6px -1px hsla(215, 28%, 17%, 0.1);
                margin-top: 0;
                max-height: 200px;
                overflow-y: auto;
                display: none;
                animation: fadeIn 0.2s ease-in-out;
                z-index: 10; /* 添加z-index确保在其他元素上方 */
            }

            .drop-options.open {
                display: block;
            }

            .search-drop-section {
                padding: 0.75rem;
                border-bottom: 1px solid hsl(216, 16%, 95%);
            }

            .custom-search-drop-input {
                width: 100%;
                padding: 0.5rem 0.75rem;
                border: 1px solid hsl(216, 16%, 95%);
                border-radius: 0.375rem;
                font-size: 0.875rem;
                color: hsl(215, 28%, 17%);
            }

            .custom-search-drop-input:focus {
                border-color: hsl(217, 91%, 60%);
                outline: none;
                box-shadow: 0 0 0 2px hsla(217, 91%, 60%, 0.2);
            }

            .option-drop-{ num } {
                padding: 0.75rem 1rem;
                cursor: pointer;
                transition: background-color 0.2s ease;
            }

            .option-drop-{ num }:hover,
            .option-drop-{ num }.active {
                background-color: hsla(217, 91%, 60%, 0.1);
            }

            .option-drop-{ num }.custom-drop-option {
                color: hsl(160, 84%, 39%);
                font-weight: 500;
                border-top: 1px solid hsl(216, 16%, 95%);
            }

            /* 响应式调整 */
            @media (max-width: 640px) {
                .drop-container {
                    padding: 1rem;
                }

                .custom-drop {
                    padding: 0.5rem 1rem;
                }
            }
        </style>
    </head>
    <body>
    <div class="drop-container">
        <div class="drop-card">
            <h3 class="text-xl font-bold mb-4 drop-title">{% info.title %}</h3>

            <div class="custom-drop-container relative">
                <div class="custom-drop" id="drop-trigger-{ num }">
                    <input class ="custom-drop-input" type="drop-text" id="custom-drop-{ num }" placeholder="请选择或输入..." autocomplete="off">
                    <span class="drop-icon">
                            <i class="fa fa-chevron-down"></i>
                        </span>
                </div>

                <div class="drop-options" id="options-drop-container-{ num }">
                    <div class="search-drop-section">
                        <input type="text" class="custom-search-drop-input" id="search-drop-input-{ num }" placeholder="搜索选项...">
                    </div>
                    <ul>
                        {% for item in info.arr %}
                            <li class="option-drop-{ num }" data-value=\"{% item %}\">{% item %}</li>
                        {% /for %}
                        <li class="option-drop-{ num } custom-drop-option" data-value="other">
                            <i class="fa fa-plus-circle mr-1"></i> 输入自定义内容
                        </li>
                    </ul>
                </div>
            </div>
        </div>
    </div>

    <script>
        const dropTrigger-{ num } = document.getElementById('drop-trigger-{ num }');
        const optionsDropContainer-{ num } = document.getElementById('options-drop-container-{ num }');
        const inputDropField-{ num } = document.getElementById('custom-drop-{ num }');
        const searchDropInput-{ num } = document.getElementById('search-drop-input-{ num }');
        const selectDropIcon-{ num } = dropTrigger-{ num }.querySelector('.fa-chevron-down');
        const optionDrop-{ num } = document.querySelectorAll('.option-drop-{ num }');

        let isOpen-{ num } = false;

        // 切换下拉框状态
        dropTrigger-{ num }.addEventListener('click', () => {
            isOpen-{ num } = !isOpen-{ num };
            optionsDropContainer-{ num }.classList.toggle('open');
            selectDropIcon-{ num }.style.transform = isOpen-{ num } ? 'rotate(180deg)' : 'rotate(0)';

            if (isOpen-{ num }) {
                searchDropInput-{ num }.focus();
                filterOptions-{ num }('');
            }
        });

        // 点击选项处理
        optionDrop-{ num }.forEach(option => {
            option.addEventListener('click', () => {
                const value = option.dataset.value;

                if (value === 'other') {
                    inputDropField-{ num }.value = '';
                    inputDropField-{ num }.placeholder = '请输入...';
                } else {
                    inputDropField-{ num }.value = value;
                }

                isOpen-{ num } = false;
                optionsDropContainer-{ num }.classList.remove('open');
                selectDropIcon-{ num }.style.transform = 'rotate(0)';
            });
        });

        // 搜索过滤选项
        searchDropInput-{ num }.addEventListener('input', (e) => {
            const keyword = e.target.value.toLowerCase();
            filterOptions-{ num }(keyword);
        });

        // 键盘导航
        inputDropField-{ num }.addEventListener('keydown', (e) => {
            if (!isOpen-{ num }) return;

            const visibleOptions = Array.from(optionDrop-{ num }).filter(option => !option.hidden);
            const activeOption = document.querySelector('.option-drop.active');
            let index = activeOption ? visibleOptions.indexOf(activeOption) : -1;

            switch(e.key) {
                case 'ArrowDown':
                    e.preventDefault();
                    setActiveOption-{ num }(index + 1, visibleOptions);
                    break;
                case 'ArrowUp':
                    e.preventDefault();
                    setActiveOption-{ num }(index - 1, visibleOptions);
                    break;
                case 'Enter':
                    e.preventDefault();
                    if (activeOption) activeOption.click();
                    break;
            }
        });

        // 过滤选项
        function filterOptions-{ num }(keyword) {
            optionDrop-{ num }.forEach(option => {
                const text = option.textContent.toLowerCase();
                option.hidden = !text.includes(keyword);
            });

            const visibleOptions = Array.from(optionDrop-{ num }).filter(option => !option.hidden);
            setActiveOption-{ num }(0, visibleOptions);
        }

        // 设置活动选项
        function setActiveOption-{ num }(index, optionsArray) {
            if (optionsArray.length === 0) return;

            index = (index + optionsArray.length) % optionsArray.length;

            optionDrop-{ num }.forEach(option => option.classList.remove('active'));
            optionsArray[index].classList.add('active');
            optionsArray[index].scrollIntoView({ behavior: 'smooth' });
        }
    </script>

    </body>
    </html>
    '''
}
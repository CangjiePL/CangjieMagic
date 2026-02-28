/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.ui.html

import magic.dsl.*
import magic.prelude.*



@ui[description: '''
    功能类型：确认按钮 UI,
    使用场景：触发确认类核心操作，如提交表单、确认订单、保存设置、执行删除操作、确认时间选择结果、提交表格编辑内容,
    交互特性：操作交互型，支持点击触发操作,
    风格属性：简约通用型，对于收集信息页面必须有且只有一个，且必须放在组件列表最后
    ''',
    kind: "input"
]
public func confirmBtnUI() {
    '''
    <!DOCTYPE html>
    <html lang="zh-CN">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <style>
            .confirm-btn {
                display: block;
                width: calc(100% - 50px);;
                padding: 15px;
                background-color: hsl(217, 89%, 61%);
                color: white;
                border: none;
                border-radius: 8px;
                font-size: 16px;
                font-weight: bold;
				margin: 0 25px;
            }
        </style>
    </head>
    <body>
        <button class="confirm-btn" id="confirmBtn">确认</button>
        <script>
            // 确认按钮事件
            let flag = true
            let userAnswer = ''
            document.getElementById('confirmBtn').addEventListener('click', function() {
                if (flag) {
                    OH_LOG_Print(LOG_APP, LOG_INFO, 0xFF00, "[Sample_NdkAddInteractionEvent]",
                                        "NdkAddInteractionEvent_eventInfoOfCommonEvent %{public}s",
                                        "aaaa");
                    // displayListItems
                    const selectedRadios = document.querySelectorAll('.option-radio-card input[type="radio"]:checked');
                    const radioTitles = document.querySelectorAll('h3.radio-title');
                    const customInputs = document.querySelectorAll('.custom-radio-input');
                    if (selectedRadios.length > 0 && selectedRadios.length == radioTitles.length) {
                        for (let i = 0; i < selectedRadios.length; i++) {
                            const radioElement = selectedRadios[i];
                            const titleElement = radioTitles[i];
                            const customInput = customInputs[i]
                            if (radioElement.value === 'custom') {
                                if (customInput.value.trim() === '') {
                                    showToast('自定义不能为空，请输入', 'error');
                                } else {
                                    userAnswer += titleElement.textContent.trim() + ": " + customInput.value.trim() + "\\n"
                                }
                            } else {
                                userAnswer += titleElement.textContent.trim() + ": " + radioElement.value + "\\n"
                            }
                        }
                    }

                    const selectedDrops = document.querySelectorAll('.custom-drop-input');
                    const dropTitles = document.querySelectorAll('h3.drop-title');
                    if (selectedDrops.length > 0 && selectedDrops.length == dropTitles.length) {
                        for (let i = 0; i < selectedDrops.length; i++) {
                            const dropElement = selectedDrops[i];
                            const titleElement = dropTitles[i];
                            userAnswer += titleElement.textContent.trim() + ": " + dropElement.value.trim() + "\\n"
                        }
                    }

                    // multiListUI
                    const checkboxGroups = document.querySelectorAll('.checkbox-multi-group');
                    const multiTitles = document.querySelectorAll('h3.multi-title');
                    if (checkboxGroups.length > 0 && checkboxGroups.length == multiTitles.length) {
                        for (let i = 0; i < checkboxGroups.length; i++) {
                            const checkboxGroup = checkboxGroups[i];
                            const titleElement = multiTitles[i];
                            const selectedOptions = Array.from(checkboxGroup.querySelectorAll('input[type="checkbox"]:checked'))
                                .map(checkbox => {
                                    // 获取对应的文本标签内容
                                    return checkbox.nextSibling.textContent.trim();
                                });

                            if (selectedOptions.length > 0) {
                                // 添加选中的选项到结果列表
                                let multiRes = ''
                                selectedOptions.forEach(option => {
                                    multiRes += option + ' '
                                });

                                userAnswer += titleElement.textContent.trim() + ": " + multiRes + "\\n"
                            } else {
                                alert('请至少选择一个选项!');
                            }
                        }
                    }

                    // inputUI
                    const inputComments = document.querySelectorAll('.input-comment');
                    const inputTitles = document.querySelectorAll('h3.input-title');
                    if (inputComments.length > 0 && inputComments.length == inputTitles.length) {
                        for (let i = 0; i < inputTitles.length; i++) {
                            const inputComment = inputComments[i];
                            const titleElement = inputTitles[i];
                            userAnswer += titleElement.textContent.trim() + ": " + inputComment.value + "\\n"
                        }
                    }

                    // clockUI
                    const clockRes = document.querySelectorAll('.time-display');
                    const clockTitles = document.querySelectorAll('h3.clock-title');
                    if (clockRes.length > 0 && clockRes.length == clockTitles.length) {
                        for (let i = 0; i < clockRes.length; i++) {
                            const time = clockRes[i];
                            const titleElement = clockTitles[i];
                            userAnswer += titleElement.textContent.trim() + time.textContent + "\\n"
                        }
                    }

                    // startEndDateUI
                    const calendarRes = document.querySelectorAll('.date-selected-range');
                    const calendarTitles = document.querySelectorAll('h3.date-range-title');
                    if (calendarRes.length > 0 && calendarRes.length == calendarTitles.length) {
                        for (let i = 0; i < calendarRes.length; i++) {
                            const selectedRangeElement = calendarRes[i];
                            const titleElement = calendarTitles[i];
                            userAnswer += titleElement.textContent.trim() + ": " + selectedRangeElement.textContent + "\\n"
                        }
                    }

                    // singleDateUI
                    const dateRes = document.querySelectorAll('.date-form-group input[type="date"]');
                    const dateTitles = document.querySelectorAll('h3.date-title');
                    if (dateRes.length > 0 && dateRes.length == dateTitles.length) {
                        for (let i = 0; i < dateTitles.length; i++) {
                            const dateElement = dateRes[i];
                            const titleElement = dateTitles[i];
                            userAnswer += titleElement.textContent.trim() + ": " + dateElement.value + "\\n"
                        }
                    }

                    // selectNumberUI
                    const sliderValues = document.querySelectorAll('.slider-value');
                    const numberTitles = document.querySelectorAll('h3.number-title');
                    if (sliderValues.length > 0 && sliderValues.length == numberTitles.length) {
                        for (let i = 0; i < numberTitles.length; i++) {
                            const sliderValue = sliderValues[i];
                            const titleElement = numberTitles[i];
                            userAnswer += titleElement.textContent.trim() + ": " + sliderValue.textContent + "\\n"
                        }
                    }

                    // selectRangeUI
                    const minValues = document.querySelectorAll('.range-value-min');
                    const maxValues = document.querySelectorAll('.range-value-max');
                    const rangeTitles = document.querySelectorAll('h3.range-title');
                    if (minValues.length > 0 && minValues.length == rangeTitles.length) {
                        for (let i = 0; i < minValues.length; i++) {
                            const maxValue = maxValues[i];
                            const minValue = minValues[i];
                            const titleElement = rangeTitles[i];
                            userAnswer += titleElement.textContent.trim() + ": " + minValue.textContent + "-" + maxValue.textContent + "\\n"
                        }
                    }
                    OH_LOG_Print(LOG_APP, LOG_INFO, 0xFF00, "[Sample_NdkAddInteractionEvent]",
                                        "NdkAddInteractionEvent_eventInfoOfCommonEvent %{public}s",
                                        userAnswer.trim().c_str());
                    agentCallbackObject.sendMessage(userAnswer.trim());
                    OH_LOG_Print(LOG_APP, LOG_INFO, 0xFF00, "[Sample_NdkAddInteractionEvent]",
                                        "NdkAddInteractionEvent_eventInfoOfCommonEvent1 %{public}s",
                                        userAnswer.trim().c_str());
                    flag = false
                }
            });
        </script>
    </body>
    </html>
    '''
}
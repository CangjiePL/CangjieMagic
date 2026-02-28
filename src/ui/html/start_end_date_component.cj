/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.ui.html

import magic.dsl.*
import magic.prelude.*



@ui[
    description: '''
    功能类型：选择日期范围 UI・区间筛选型,
    使用场景：筛选指定时间区间的相关数据，如订单日期筛选、报表时间范围查询、行程日期选择、活动报名时间限定、数据统计时间区间设置,
    交互特性：数据录入型，支持点击日历面板选择起始 / 结束日期，
    风格属性：简约通用型
    ''',
    parameters: {
        title: "描述特定选择日期事件的标题"
    },
    kind: "input"
]
public func startEndDateUI(title: String) {
    '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <link href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css" rel="stylesheet">
        <style>
            /* 输入框样式 */
            .date-input-group {
                margin-bottom: 16px;
            }

            .date-input-group label {
                display: block;
                font-size: 14px;
                font-weight: 500;
                color: hsl(0, 0%, 33%);
                margin-bottom: 6px;
            }

            .date-input-group input {
                padding: 10px 14px;
                border: 1px solid hsl(0, 0%, 80%);
                border-radius: 8px;
                font-size: 16px;
                color: hsl(0, 0%, 15%);
                background-color: white;
                outline: none;
                transition: border-color 0.2s ease, box-shadow 0.2s ease;
            }

            .date-input-group input:focus {
                border-color: hsl(212, 80%, 42%);
                box-shadow: 0 0 0 3px hsla(212, 80%, 42%, 0.2);
            }

            .date-input-group input::placeholder {
                color: hsl(0, 0%, 60%);
            }

            /* 日历样式 */
            .calendar {
                border: 1px solid hsl(0, 0%, 87%);
                border-radius: 8px;
                overflow: hidden;
                margin-top: 24px;
                background-color: white;
                box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
            }

            .calendar-header {
                display: flex;
                justify-content: space-between;
                align-items: center;
                padding: 16px;
                border-bottom: 1px solid hsl(0, 0%, 93%);
            }

            .calendar-header h3 {
                margin: 0;
                font-size: 18px;
                font-weight: 500;
                color: hsl(0, 0%, 15%);
            }

            .calendar-grid {
                display: grid;
                grid-template-columns: repeat(7, 1fr);
                gap: 2px;
                padding: 12px;
            }

            .calendar-day-names {
                margin-bottom: 8px;
            }

            .calendar-day-names div {
                text-align: center;
                font-size: 12px;
                font-weight: 500;
                color: hsl(0, 0%, 40%);
                padding: 6px 0;
            }

            .calendar-days .day {
                aspect-ratio: 1;
                display: flex;
                align-items: center;
                justify-content: center;
                font-size: 14px;
                color: hsl(0, 0%, 15%);
                border-radius: 50%;
                transition: all 0.2s ease;
                cursor: pointer;
            }

            .calendar-days .day.other-month {
                color: hsl(0, 0%, 60%);
                opacity: 0.5;
                cursor: default;
            }

            .calendar-days .day.today {
                font-weight: 600;
                box-shadow: inset 0 0 0 1px hsl(212, 80%, 42%);
            }

            .calendar-days .day.start-date,
            .calendar-days .day.end-date {
                background-color: hsl(212, 80%, 42%);
                color: white;
                font-weight: 600;
                box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
            }

            .calendar-days .day.in-range {
                background-color: hsl(212, 80%, 90%);
                border-radius: 0;
            }

            .calendar-days .day:not(.other-month):hover:not(.start-date):not(.end-date):not(.in-range) {
                background-color: hsl(0, 0%, 93%);
            }

            .calendar-footer {
                display: flex;
                justify-content: space-between;
                padding: 12px 16px;
                border-top: 1px solid hsl(0, 0%, 93%);
            }

            /* 日期范围信息 */
            .date-range-info {
                padding: 12px;
                background-color: hsl(203, 77%, 95%);
                border: 1px solid hsl(203, 77%, 90%);
                border-radius: 8px;
                margin-top: 16px;
                color: hsl(203, 77%, 25%);
                font-size: 14px;
            }

            .date-btn {
                color: hsl(0, 0%, 40%);
                padding: 8px 12px;
                border-radius: 4px;
                font-size: 14px;
                border: none;
                background: none;
            }

            .date-btn:hover {
                background-color: hsl(0, 0%, 93%);
                color: hsl(0, 0%, 30%);
            }
        </style>
    </head>
    <body>
    <main class="flex-grow container py-8">
    <div class="max-w-3xl mx-auto card">
        <div class="mb-8">
            <h3 class="text-xl font-semibold mb-4 date-range-title">{% title %}</h3>

            <div class="date-inputs">
                <div class="date-input-group">
                    <label for="startDate-{ num }">起始日期</label>
                    <div class="relative">
                        <input type="text" id="startDate-{ num }" class="w-full" placeholder="点击选择起始日期" readonly>
                    </div>
                </div>

                <div class="date-input-group">
                    <label for="endDate-{ num }">终止日期</label>
                    <div class="relative">
                        <input type="text" id="endDate-{ num }" class="w-full" placeholder="点击选择终止日期" readonly>
                    </div>
                </div>
            </div>

            <div id="dateRangeInfo-{ num }" class="date-range-info hidden">
            <p><span class="date-selected-range" id="selectedRange-{ num }"></span></p>
        </div>
        </div>

        <div id="calendarContainer-{ num }" class="hidden calendar">
            <div class="calendar-header">
                <button id="prevMonth-{ num }" class="date-btn">
                    <i class="fa fa-chevron-left"></i>
                </button>
                <h3 id="currentMonth-{ num }"></h3>
                <button id="nextMonth-{ num }" class="date-btn">
                    <i class="fa fa-chevron-right"></i>
                </button>
            </div>

            <div class="calendar-grid calendar-day-names">
            <div>日</div>
            <div>一</div>
            <div>二</div>
            <div>三</div>
            <div>四</div>
            <div>五</div>
            <div>六</div>
            </div>

            <div id="calendarDays-{ num }" class="calendar-grid calendar-days"></div>

            <div class="calendar-footer">
                <button id="clearDates-{ num }" class="date-btn">
                    <i class="fa fa-refresh mr-1"></i> 重置
                </button>
            </div>
        </div>
    </div>
    </main>

    <script>
        // 当前选中的日期
        let selectedStartDate-{ num } = null;
        let selectedEndDate-{ num } = null;
        let currentViewDate-{ num } = new Date();
        let isSelectingStartDate-{ num } = true; // 用户是否正在选择起始日期

        // DOM 元素
        const startDateInput-{ num } = document.getElementById('startDate-{ num }');
        const endDateInput-{ num } = document.getElementById('endDate-{ num }');
        const calendarContainer-{ num } = document.getElementById('calendarContainer-{ num }');
        const currentMonthElement-{ num } = document.getElementById('currentMonth-{ num }');
        const calendarDaysElement-{ num } = document.getElementById('calendarDays-{ num }');
        const prevMonthButton-{ num } = document.getElementById('prevMonth-{ num }');
        const nextMonthButton-{ num } = document.getElementById('nextMonth-{ num }');
        const clearDatesButton-{ num } = document.getElementById('clearDates-{ num }');
        const dateRangeInfo-{ num } = document.getElementById('dateRangeInfo-{ num }');
        const selectedRangeElement-{ num } = document.getElementById('selectedRange-{ num }');

        // 初始化事件监听
        startDateInput-{ num }.addEventListener('click', () => showCalendar-{ num }(true));
        endDateInput-{ num }.addEventListener('click', () => showCalendar-{ num }(false));
        prevMonthButton-{ num }.addEventListener('click', showPreviousMonth-{ num });
        nextMonthButton-{ num }.addEventListener('click', showNextMonth-{ num });
        clearDatesButton-{ num }.addEventListener('click', clearSelectedDates-{ num });

        // 显示日历
        function showCalendar-{ num }(forStartDate) {
            isSelectingStartDate-{ num } = forStartDate;
            calendarContainer-{ num }.classList.remove('hidden');

            // 如果是选择起始日期但已有起始日期，则跳转到该月
            if (isSelectingStartDate-{ num } && selectedStartDate-{ num }) {
                currentViewDate-{ num } = new Date(selectedStartDate-{ num });
            }
            // 如果是选择终止日期但已有终止日期，则跳转到该月
            else if (!isSelectingStartDate-{ num } && selectedEndDate-{ num }) {
                currentViewDate-{ num } = new Date(selectedEndDate-{ num });
            }

            renderCalendar-{ num }();
        }
        showCalendar-{ num }(true)

        // 渲染日历
        function renderCalendar-{ num }() {
            const year = currentViewDate-{ num }.getFullYear();
            const month = currentViewDate-{ num }.getMonth();

            // 更新当前月份显示
            currentMonthElement-{ num }.textContent = `\${year}年 \${month + 1}月`;

            // 清空日历
            calendarDaysElement-{ num }.innerHTML = '';

            // 获取当月第一天和最后一天
            const firstDay = new Date(year, month, 1);
            const lastDay = new Date(year, month + 1, 0);

            // 获取当月第一天是星期几 (0-6)
            const firstDayOfWeek = firstDay.getDay();

            // 获取上个月的最后几天
            const prevMonthLastDay = new Date(year, month, 0).getDate();

            // 生成日历格子
            // 添加上个月的最后几天
            for (let i = firstDayOfWeek; i > 0; i--) {
                const day = prevMonthLastDay - i + 1;
                const date = new Date(year, month - 1, day);
                addCalendarDay-{ num }(date, true);
            }

            // 添加当月的天数
            for (let i = 1; i <= lastDay.getDate(); i++) {
                const date = new Date(year, month, i);
                addCalendarDay-{ num }(date, false);
            }

            // 添加下个月的开始几天，使日历总共有42个格子 (6行7列)
            const nextMonthDays = 42 - (firstDayOfWeek + lastDay.getDate());
            for (let i = 1; i <= nextMonthDays; i++) {
                const date = new Date(year, month + 1, i);
                addCalendarDay-{ num }(date, true);
            }
        }

        // 添加日历中的一天
        function addCalendarDay-{ num }(date, isOtherMonth) {
            const dayElement = document.createElement('div');
            dayElement.className = 'day';

            const dayNumber = date.getDate();
            const isToday = isSameDay-{ num }(date, new Date());
            const isStartDate = selectedStartDate-{ num } && isSameDay-{ num }(date, selectedStartDate-{ num });
            const isEndDate = selectedEndDate-{ num } && isSameDay-{ num }(date, selectedEndDate-{ num });
            const isInRange = selectedStartDate-{ num } && selectedEndDate-{ num } &&
                            date > selectedStartDate-{ num } && date < selectedEndDate-{ num };

            // 其他月份的日期
            if (isOtherMonth) {
                dayElement.textContent = dayNumber;
                dayElement.classList.add('other-month');
            }
            // 当月日期
            else {
                dayElement.textContent = dayNumber;

                // 如果有起始日期和终止日期，且当前日期在范围内
                if (isInRange) {
                    dayElement.classList.add('in-range');
                }

                // 如果是起始日期
                if (isStartDate) {
                    dayElement.classList.add('start-date');
                }

                // 如果是终止日期
                if (isEndDate) {
                    dayElement.classList.add('end-date');
                }

                // 如果是今天
                if (isToday && !isStartDate && !isEndDate) {
                    dayElement.classList.add('today');
                }

                // 如果是可选日期
                if (!isOtherMonth) {
                    dayElement.addEventListener('click', () => selectDate-{ num }(date));
                }
            }

            calendarDaysElement-{ num }.appendChild(dayElement);
        }

        // 选择日期
        function selectDate-{ num }(date) {
            if (isSelectingStartDate-{ num }) {
                // 选择起始日期
                selectedStartDate-{ num } = date;

                // 如果已有终止日期，且终止日期早于新选择的起始日期，则清除终止日期
                if (selectedEndDate-{ num } && selectedEndDate-{ num } < selectedStartDate-{ num }) {
                    selectedEndDate-{ num } = null;
                    endDateInput-{ num }.value = '';
                }

                // 更新输入框
                startDateInput-{ num }.value = formatDate-{ num }(date);

                // 切换到选择终止日期模式
                isSelectingStartDate-{ num } = false;

                // 如果没有选择终止日期，则聚焦到终止日期输入框
                if (!selectedEndDate-{ num }) {
                    setTimeout(() => {
                        endDateInput-{ num }.click();
                    }, 10);
                }
            } else {
                // 选择终止日期（必须晚于或等于起始日期）
                if (selectedStartDate-{ num } && date >= selectedStartDate-{ num }) {
                    selectedEndDate-{ num } = date;
                    endDateInput-{ num }.value = formatDate-{ num }(date);

                    // 显示选择的日期范围
                    showDateRangeInfo-{ num }();
                }
            }

            // 重新渲染日历以反映选择
            renderCalendar-{ num }();
        }

        // 显示上一个月
        function showPreviousMonth-{ num }() {
            currentViewDate-{ num }.setMonth(currentViewDate-{ num }.getMonth() - 1);
            renderCalendar-{ num }();
        }

        // 显示下一个月
        function showNextMonth-{ num }() {
            currentViewDate-{ num }.setMonth(currentViewDate-{ num }.getMonth() + 1);
            renderCalendar-{ num }();
        }

        // 清除已选日期
        function clearSelectedDates-{ num }() {
            selectedStartDate-{ num } = null;
            selectedEndDate-{ num } = null;
            startDateInput-{ num }.value = '';
            endDateInput-{ num }.value = '';
            dateRangeInfo-{ num }.classList.add('hidden');
            renderCalendar-{ num }();
        }

        // 显示日期范围信息
        function showDateRangeInfo-{ num }() {
            if (selectedStartDate-{ num } && selectedEndDate-{ num }) {
                const start = formatDate-{ num }(selectedStartDate-{ num });
                const end = formatDate-{ num }(selectedEndDate-{ num });
                selectedRangeElement-{ num }.textContent = `已选择日期范围: \${start} 至 \${end}`;
                dateRangeInfo-{ num }.classList.remove('hidden');
            }
        }

        // 辅助函数：检查两个日期是否是同一天
        function isSameDay-{ num }(date1, date2) {
            return date1.getDate() === date2.getDate() &&
                date1.getMonth() === date2.getMonth() &&
                date1.getFullYear() === date2.getFullYear();
        }

        // 辅助函数：格式化日期为 YYYY-MM-DD
        function formatDate-{ num }(date) {
            const year = date.getFullYear();
            const month = String(date.getMonth() + 1).padStart(2, '0');
            const day = String(date.getDate()).padStart(2, '0');
            return `\${year}-\${month}-\${day}`;
        }
    </script>
    </body>
    </html>
    '''
}
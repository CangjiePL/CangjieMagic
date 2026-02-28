/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.ui.html

import magic.dsl.*
import magic.prelude.*

@ui[
    description: '''
    功能类型：创意设计简历 UI,
    使用场景：展示艺术岗位求职相关信息，如个人技能栈、项目经验、工作履历、教育背景、证书资质、技术成果（论文 / 专利），
    交互特性：信息展示型，仅用于呈现信息，无交互，
    风格属性：复杂型，仅适合展示单个UI，不适合与其他UI进行组合
    ''',
    parameters: {
        info: "个人简历需要收集的信息"
    },
    thumbnail: "D:/Work/Cangjie/deveco5.1.1/CangjieMagic-HarmonyOS/entry/src/main/cangjie/cartoon_resume.png",
    title: "创意设计模板",
    category: "resume",
    kind: "display"
]
public func creativeResume(info: CommonResumeInfo) {
    '''
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>漫画风格简历</title>
    <link href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css" rel="stylesheet">
    <style>
        /* 基础颜色定义 - HSL格式 */
        :root {
            --comic-yellow: hsl(52, 100%, 70%);
            --comic-red: hsl(0, 100%, 65%);
            --comic-blue: hsl(197, 93%, 65%);
            --comic-green: hsl(124, 35%, 55%);
            --comic-black: hsl(0, 0%, 13%);
            --comic-white: hsl(0, 0%, 98%);
            --gray-light: hsl(0, 0%, 90%);
        }

        /* 全局样式 */
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Comic Sans MS', 'Chalkboard SE', cursive, sans-serif;
            background-color: var(--comic-white);
            color: var(--comic-black);
            min-height: 100vh;
            line-height: 1.6;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 2rem;
        }

        /* 工具类 */
        .border-comic {
            border: 3px solid var(--comic-black);
        }

        .border-comic-sm {
            border: 2px solid var(--comic-black);
        }

        .text-outline {
            -webkit-text-stroke: 1px var(--comic-black);
        }

        .shadow-comic {
            box-shadow: 4px 4px 0px var(--comic-black);
        }

        .shadow-comic-sm {
            box-shadow: 2px 2px 0px var(--comic-black);
        }

        .hand-drawn {
            clip-path: polygon(
                0% 2%, 3% 0%, 5% 3%, 8% 1%, 12% 4%, 15% 2%, 18% 5%, 22% 3%, 25% 6%,
                28% 4%, 32% 7%, 35% 5%, 38% 8%, 42% 6%, 45% 9%, 48% 7%, 52% 10%,
                55% 8%, 58% 11%, 62% 9%, 65% 12%, 68% 10%, 72% 13%, 75% 11%, 78% 14%,
                82% 12%, 85% 15%, 88% 13%, 92% 16%, 95% 14%, 98% 17%, 100% 15%,
                100% 98%, 97% 100%, 95% 97%, 92% 100%, 88% 97%, 85% 100%, 82% 97%,
                78% 100%, 75% 97%, 72% 100%, 68% 97%, 65% 100%, 62% 97%, 58% 100%,
                55% 97%, 52% 100%, 48% 97%, 45% 100%, 42% 97%, 38% 100%, 35% 97%,
                32% 100%, 28% 97%, 25% 100%, 22% 97%, 18% 100%, 15% 97%, 12% 100%,
                8% 97%, 5% 100%, 2% 97%, 0% 95%
            );
        }

        .speech-bubble {
            position: relative;
        }

        .speech-bubble::after {
            content: '';
            position: absolute;
            width: 0;
            height: 0;
            border: 12px solid transparent;
            border-top-color: inherit;
            bottom: -24px;
            left: 30px;
        }

        .comic-dot-pattern {
            background-image: radial-gradient(var(--comic-black) 1px, transparent 1px);
            background-size: 20px 20px;
        }

        .comic-stripe {
            background: repeating-linear-gradient(
                45deg,
                rgba(0,0,0,0.05),
                rgba(0,0,0,0.05) 5px,
                transparent 5px,
                transparent 10px
            );
        }

        /* 布局组件 */
        header {
            text-align: center;
            margin-bottom: 2.5rem;
        }

        .grid {
            display: grid;
            gap: 2rem;
        }

        @media (min-width: 768px) {
            .grid-cols-3 {
                grid-template-columns: 1fr 2fr;
            }
        }

        .space-y-6 > * {
            margin-bottom: 1.5rem;
        }

        .space-y-6 > *:last-child {
            margin-bottom: 0;
        }

        .space-y-4 > * {
            margin-bottom: 1rem;
        }

        .space-y-4 > *:last-child {
            margin-bottom: 0;
        }

        .space-y-3 > * {
            margin-bottom: 0.75rem;
        }

        .space-y-3 > *:last-child {
            margin-bottom: 0;
        }

        .flex {
            display: flex;
        }

        .items-center {
            align-items: center;
        }

        .justify-center {
            justify-content: center;
        }

        .justify-between {
            justify-content: space-between;
        }

        .flex-col {
            flex-direction: column;
        }

        @media (min-width: 768px) {
            .md:flex-row {
                flex-direction: row;
            }
        }

        .mb-10 {
            margin-bottom: 2.5rem;
        }

        .mb-4 {
            margin-bottom: 1rem;
        }

        .mb-3 {
            margin-bottom: 0.75rem;
        }

        .mb-2 {
            margin-bottom: 0.5rem;
        }

        .mb-1 {
            margin-bottom: 0.25rem;
        }

        .mt-12 {
            margin-top: 3rem;
        }

        .mt-2 {
            margin-top: 0.5rem;
        }

        .mt-1 {
            margin-top: 0.25rem;
        }

        .mr-3 {
            margin-right: 0.75rem;
        }

        .mr-2 {
            margin-right: 0.5rem;
        }

        .p-5 {
            padding: 1.25rem;
        }

        .p-4 {
            padding: 1rem;
        }

        .p-3 {
            padding: 0.75rem;
        }

        .px-8 {
            padding-left: 2rem;
            padding-right: 2rem;
        }

        .py-4 {
            padding-top: 1rem;
            padding-bottom: 1rem;
        }

        .px-6 {
            padding-left: 1.5rem;
            padding-right: 1.5rem;
        }

        .py-3 {
            padding-top: 0.75rem;
            padding-bottom: 0.75rem;
        }

        .px-2 {
            padding-left: 0.5rem;
            padding-right: 0.5rem;
        }

        .py-1 {
            padding-top: 0.25rem;
            padding-bottom: 0.25rem;
        }

        .pl-6 {
            padding-left: 1.5rem;
        }

        .text-center {
            text-align: center;
        }

        .text-left {
            text-align: left;
        }

        .font-bold {
            font-weight: bold;
        }

        .text-4xl {
            font-size: 2.5rem;
        }

        .text-5xl {
            font-size: 3.125rem;
        }

        .text-xl {
            font-size: 1.25rem;
        }

        .text-lg {
            font-size: 1.125rem;
        }

        .text-sm {
            font-size: 0.875rem;
        }

        .text-2xl {
            font-size: 1.5rem;
        }

        .inline-block {
            display: inline-block;
        }

        .w-36 {
            width: 9rem;
        }

        .h-36 {
            height: 9rem;
        }

        .w-8 {
            width: 2rem;
        }

        .h-8 {
            height: 2rem;
        }

        .w-4 {
            width: 1rem;
        }

        .h-4 {
            height: 1rem;
        }

        .rounded-full {
            border-radius: 50%;
        }

        .overflow-hidden {
            overflow: hidden;
        }

        .object-cover {
            object-fit: cover;
        }

        .list-disc {
            list-style-type: disc;
        }

        .list-inside {
            list-style-position: inside;
        }

        .w-full {
            width: 100%;
        }

        .h-full {
            height: 100%;
        }

        .relative {
            position: relative;
        }

        .absolute {
            position: absolute;
        }

        .-left-6 {
            left: -1.5rem;
        }

        .top-1 {
            top: 0.25rem;
        }

        .before:absolute::before {
            position: absolute;
        }

        .before:left-0::before {
            left: 0;
        }

        .before:top-0::before {
            top: 0;
        }

        .before:bottom-0::before {
            bottom: 0;
        }

        .before:w-1.5::before {
            width: 0.375rem;
        }

        .before:bg-comicBlack::before {
            background-color: var(--comic-black);
        }

        .rotate-1 {
            transform: rotate(1deg);
        }

        .-rotate-1 {
            transform: rotate(-1deg);
        }

        .-rotate-3 {
            transform: rotate(-3deg);
        }

        .bg-white {
            background-color: white;
        }

        .bg-comicYellow {
            background-color: var(--comic-yellow);
        }

        .bg-comicRed {
            background-color: var(--comic-red);
        }

        .bg-comicBlue {
            background-color: var(--comic-blue);
        }

        .bg-comicGreen {
            background-color: var(--comic-green);
        }

        .bg-comicBlack {
            background-color: var(--comic-black);
        }

        .text-white {
            color: white;
        }

        .text-comicRed {
            color: var(--comic-red);
        }

        .text-comicBlue {
            color: var(--comic-blue);
        }

        .text-comicGreen {
            color: var(--comic-green);
        }

        .text-comicYellow {
            color: var(--comic-yellow);
        }

        .bg-comicYellow-30 {
            background-color: hsl(52, 100%, 70%, 30%);
        }

        .bg-comicBlue-30 {
            background-color: hsl(197, 93%, 65%, 30%);
        }

        .bg-comicGreen-30 {
            background-color: hsl(124, 35%, 55%, 30%);
        }

        .bg-comicRed-30 {
            background-color: hsl(0, 100%, 65%, 30%);
        }

        .bg-comicYellow-50 {
            background-color: hsl(52, 100%, 70%, 50%);
        }

        .w-fit {
            width: fit-content;
        }

        /* 进度条样式 */
        .progress-bar-container {
            height: 1rem;
            background-color: var(--gray-light);
            border: 2px solid var(--comic-black);
        }

        .progress-bar {
            height: 100%;
        }

        /* 网格布局 */
        .grid-cols-2 {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 0.75rem;
        }

        /* 动画效果 */
        .hand-drawn {
            transition: transform 0.3s ease;
        }

        .hand-drawn:hover {
            transform: rotate(0deg) scale(1.02);
        }
    </style>
</head>
<body>
    <div class="container">
        <!-- 顶部标题区 -->
        <header class="mb-10 text-center">
            <div class="inline-block bg-comicYellow border-comic shadow-comic px-8 py-4 -rotate-1 hand-drawn">
                <h1 class="text-4xl md:text-5xl font-bold text-comicRed">个人简历</h1>
                <p class="text-xl mt-1">Comic Style Resume</p>
            </div>
        </header>

        <!-- 主要内容区 -->
        <div class="grid grid-cols-3 gap-8">
            <!-- 左侧栏 -->
            <div class="space-y-6">
                <!-- 个人信息卡片 -->
                <div class="bg-white border-comic shadow-comic p-5 rotate-1 hand-drawn">
                    <div class="flex justify-center mb-4">
                        <div class="w-36 h-36 rounded-full border-comic overflow-hidden -rotate-3">
                            <img src="https://picsum.photos/200/200?random=10" alt="个人照片" class="w-full h-full object-cover">
                        </div>
                    </div>

                    <h2 class="text-2xl font-bold text-center mb-3 text-comicBlue">{% info.name %}</h2>
                    <p class="text-center text-lg mb-4">{% info.position %}</p>

                    <div class="space-y-3">
                        <div class="flex items-center">
                            <i class="fa fa-birthday-cake text-comicRed mr-3 text-xl"></i>
                            <span>1995年3月</span>
                        </div>
                        <div class="flex items-center">
                            <i class="fa fa-map-marker text-comicRed mr-3 text-xl"></i>
                            <span>{% info.address %}</span>
                        </div>
                        <div class="flex items-center">
                            <i class="fa fa-envelope text-comicRed mr-3 text-xl"></i>
                            <span>{% info.email %}</span>
                        </div>
                        <div class="flex items-center">
                            <i class="fa fa-phone text-comicRed mr-3 text-xl"></i>
                            <span>{% info.phone %}</span>
                        </div>
                        <div class="flex items-center">
                            <i class="fa fa-globe text-comicRed mr-3 text-xl"></i>
                            <span>portfolio.com</span>
                        </div>
                    </div>
                </div>

                <!-- 技能卡片 -->
                <div class="bg-white border-comic shadow-comic p-5 -rotate-1 hand-drawn">
                    <div class="flex items-center mb-4">
                        <div class="w-8 h-8 bg-comicGreen rounded-full flex items-center justify-center text-white mr-2 border-comic-sm">
                            <i class="fa fa-star"></i>
                        </div>
                        <h2 class="text-xl font-bold">专业技能</h2>
                    </div>

                    <div class="space-y-4">
                        <div>
                            <div class="flex justify-between mb-1">
                                <span class="font-bold">UI设计</span>
                                <span>95%</span>
                            </div>
                            <div class="progress-bar-container">
                                <div class="progress-bar bg-comicRed" style="width: 95%"></div>
                            </div>
                        </div>

                        <div>
                            <div class="flex justify-between mb-1">
                                <span class="font-bold">UX研究</span>
                                <span>85%</span>
                            </div>
                            <div class="progress-bar-container">
                                <div class="progress-bar bg-comicBlue" style="width: 85%"></div>
                            </div>
                        </div>

                        <div>
                            <div class="flex justify-between mb-1">
                                <span class="font-bold">Figma</span>
                                <span>90%</span>
                            </div>
                            <div class="progress-bar-container">
                                <div class="progress-bar bg-comicGreen" style="width: 90%"></div>
                            </div>
                        </div>

                        <div>
                            <div class="flex justify-between mb-1">
                                <span class="font-bold">插画设计</span>
                                <span>80%</span>
                            </div>
                            <div class="progress-bar-container">
                                <div class="progress-bar bg-comicYellow" style="width: 80%"></div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- 右侧栏 -->
            <div class="space-y-6">
                <!-- 个人简介 - 漫画对话框风格 -->
                <div class="bg-comicYellow border-comic shadow-comic p-5 speech-bubble hand-drawn" style="margin-bottom: 40px; background-color: var(--comic-yellow);">
                    <div class="flex items-center mb-3">
                        <div class="w-8 h-8 bg-comicRed rounded-full flex items-center justify-center text-white mr-2 border-comic-sm">
                            <i class="fa fa-user"></i>
                        </div>
                        <h2 class="text-xl font-bold">关于我</h2>
                    </div>
                    <p class="text-lg">
                        {% info.careerOverview %}
                    </p>
                </div>

                <!-- 工作经历 -->
                 {% if (info.workExperience.size != 0) %}
                <div class="bg-white border-comic shadow-comic p-5 -rotate-1 hand-drawn">
                    <div class="flex items-center mb-4">
                        <div class="w-8 h-8 bg-comicBlue rounded-full flex items-center justify-center text-white mr-2 border-comic-sm">
                            <i class="fa fa-briefcase"></i>
                        </div>
                        <h2 class="text-xl font-bold">工作经历</h2>
                    </div>

                    <div class="space-y-6">
                        <!-- 工作1 -->
                        {% for workItem in info.workExperience %}
                            <div class="relative pl-6 before:absolute before:left-0 before:top-0 before:bottom-0 before:w-1.5 before:bg-comicBlack">
                                <div class="absolute -left-6 top-1 w-4 h-4 bg-comicRed rounded-full border-comic-sm"></div>
                                <div class="flex flex-col md:flex-row md:justify-between">
                                    <h3 class="text-lg font-bold">{% workItem.positionTitle %}</h3>
                                    <span class="text-sm bg-comicYellow-50 px-2 py-1 border-comic-sm inline-block w-fit mt-1 md:mt-0">{% workItem.time %}</span>
                                </div>
                                <p class="text-comicBlue font-bold">{% workItem.company %}</p>
                                <ul class="mt-2 space-y-1 list-disc list-inside">
                                    {% for item in workItem.content %}
                                        <li>{% item %}</li>
                                    {% /for %}
                                </ul>
                            </div>
                        {% /for %}
                    </div>
                </div>
                {% /if %}

                <!-- 教育经历 -->
                {% if (info.education.size != 0) %}
                <div class="bg-white border-comic shadow-comic p-5 rotate-1 hand-drawn">
                    <div class="flex items-center mb-4">
                        <div class="w-8 h-8 bg-comicGreen rounded-full flex items-center justify-center text-white mr-2 border-comic-sm">
                            <i class="fa fa-graduation-cap"></i>
                        </div>
                        <h2 class="text-xl font-bold">教育经历</h2>
                    </div>

                    <div class="space-y-6">
                        {% for eduItem in info.education %}
                            <div class="relative pl-6 before:absolute before:left-0 before:top-0 before:bottom-0 before:w-1.5 before:bg-comicBlack">
                                <div class="absolute -left-6 top-1 w-4 h-4 bg-comicBlue rounded-full border-comic-sm"></div>
                                <div class="flex flex-col md:flex-row md:justify-between">
                                    <h3 class="text-lg font-bold">{% eduItem.major %} | {% eduItem.educationBG %}</h3>
                                    <span class="text-sm bg-comicYellow-50 px-2 py-1 border-comic-sm inline-block w-fit mt-1 md:mt-0">{% eduItem.time %}</span>
                                </div>
                                <p class="text-comicBlue font-bold">{% eduItem.university %}</p>
                                <p class="mt-2">专注于用户体验设计与交互设计研究</p>
                            </div>
                        {% /for %}
                    </div>
                </div>
                {% /if %}

                <!-- 获奖经历 -->
                <div class="bg-white border-comic shadow-comic p-5 -rotate-1 hand-drawn">
                    <div class="flex items-center mb-4">
                        <div class="w-8 h-8 bg-comicRed rounded-full flex items-center justify-center text-white mr-2 border-comic-sm">
                            <i class="fa fa-trophy"></i>
                        </div>
                        <h2 class="text-xl font-bold">获奖经历</h2>
                    </div>

                    <ul class="space-y-3">
                        <li class="flex">
                            <span class="text-comicRed mr-2">🏆</span>
                            <div>
                                <span class="font-bold">2021年全国UI设计大赛二等奖</span>
                                <p class="text-sm">中国设计师协会</p>
                            </div>
                        </li>
                        <li class="flex">
                            <span class="text-comicRed mr-2">🏆</span>
                            <div>
                                <span class="font-bold">2020年度最佳用户体验设计奖</span>
                                <p class="text-sm">互联网产品设计大会</p>
                            </div>
                        </li>
                        <li class="flex">
                            <span class="text-comicRed mr-2">🏆</span>
                            <div>
                                <span class="font-bold">2019年度新锐设计师</span>
                                <p class="text-sm">设计周刊</p>
                            </div>
                        </li>
                    </ul>
                </div>
            </div>
        </div>
    </div>

    <script>
        // 添加简单的交互动画
        document.addEventListener('DOMContentLoaded', () => {
            // 获取所有卡片元素
            const cards = document.querySelectorAll('.hand-drawn');

            // 为每个卡片添加悬停效果
            cards.forEach(card => {
                // 保存原始旋转角度
                const originalTransform = card.style.transform || window.getComputedStyle(card).transform;

                card.addEventListener('mouseenter', () => {
                    card.style.transform = 'rotate(0deg) scale(1.02)';
                });

                card.addEventListener('mouseleave', () => {
                    card.style.transform = originalTransform;
                });
            });
        });
    </script>
</body>
</html>
    '''
}
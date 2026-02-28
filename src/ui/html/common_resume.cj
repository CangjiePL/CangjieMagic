/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.ui.html

import magic.dsl.*
import magic.prelude.*


@jsonable
public class EducationItem {
    @field["专业名称"]
    let major: String
    @field["学历，如：本科、硕士、博士"]
    let educationBG: String
    @field["毕业院校"]
    let university: String
    @field["就读时间段（如2019.9-2022.6）"]
    let time: String
    @field["教育经历亮点，如：主修课程、GPA排名、获奖情况、学术成果等"]
    let content: Array<String>
}

@jsonable
public class WorkItem {
    @field["职位名称"]
    let positionTitle: String
    @field["公司名称"]
    let company: String
    @field["任职时间，格式建议：YYYY年MM月 - YYYY年MM月（至今）"]
    let time: String
    @field["工作主要业绩"]
    let content: Array<String>
}

@jsonable
public class CertificateItem {
    @field["证书名称"]
    let name: String
    @field["获得时间"]
    let time: String
}

@jsonable
public class CommonResumeInfo {
    @field["姓名"]
    let name: String
    @field["联系电话"]
    let phone: String
    @field["电子邮箱"]
    let email: String
    @field["居住地址"]
    let address: String
    @field["应聘职位"]
    let position: String
    @field["工作经验年数，如5年软件开发经验或应届毕业生"]
    let years: String
    @field["个人简介，简洁概括职业优势和核心竞争力"]
    let careerOverview: String
    @field["工作经历列表"]
    let workExperience: Array<WorkItem>
    @field["教育经历列表"]
    let education: Array<EducationItem>
    @field["专业技能"]
    let skills: Array<String>
    @field["证书列表"]
    let certificate: Array<CertificateItem>
}

@ui[
    description: '''
    功能类型：现代简约型简历 UI,
    使用场景：展示岗位求职相关信息，如个人技能栈、项目经验、工作履历、教育背景、证书资质、技术成果（论文 / 专利），
    交互特性：信息展示型，仅用于呈现信息，无交互，
    风格属性：复杂型，仅适合展示单个UI，不适合与其他UI进行组合
    ''',
    parameters: {
        info: "个人简历需要收集的信息"
    },
    thumbnail: "D:/Work/Cangjie/deveco5.1.1/CangjieMagic-HarmonyOS/entry/src/main/cangjie/common_resume.png",
    title: "现代简约模板",
    category: "resume",
    kind: "display"
]
public func commonResume(info: CommonResumeInfo) {
    '''
 <!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>个人简历</title>
    <link href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css" rel="stylesheet">
    <style>
        /* 基础样式 */
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        body {
            font-family: 'Inter', system-ui, sans-serif;
            background-color: hsl(0, 0%, 96%);
            padding: 1rem;
            color: hsl(0, 0%, 20%);
            position: relative; /* 添加相对定位，用于定位更多模板按钮 */
            min-height: 100vh; /* 确保页面高度足够 */
        }

        /* 容器样式 */
        .resume-container {
            width: 100%;
            max-width: 800px;
            margin: 0 auto;
            background-color: hsl(0, 0%, 100%);
            box-shadow: 0 4px 6px hsl(0, 0%, 0%, 0.1);
            padding: 1.5rem;
            border-radius: 0.5rem;
        }

        @media (min-width: 768px) {
            .resume-container {
                padding: 2.5rem;
            }

            body {
                padding: 2rem;
            }
        }

        /* 通用组件样式 */
        section {
            margin-bottom: 2rem;
            position: relative;
            padding-top: 1.5rem;
        }

        .section-title {
            color: hsl(221, 70%, 33%);
            font-weight: bold;
            font-size: 1.125rem;
            border-bottom: 2px solid hsl(217, 91%, 60%);
            padding-bottom: 0.25rem;
            margin-bottom: 0.75rem;
            display: flex;
            align-items: center;
        }

        .section-title i {
            margin-right: 0.5rem;
        }

        .entry-title {
            font-weight: bold;
            color: hsl(0, 0%, 20%);
        }

        .entry-meta {
            color: hsl(183, 14%, 25%);
            font-size: 0.875rem;
        }

        .module-controls {
            position: absolute;
            right: 0;
            top: 0;
            display: flex;
            gap: 0.5rem;
        }

        .module-control-btn {
            font-size: 0.875rem;
            padding: 0.25rem 0.5rem;
            border-radius: 0.25rem;
            border: none;
            background: none;
            cursor: pointer;
            transition: background-color 0.2s;
        }

        .module-control-btn:hover {
            background-color: hsl(0, 0%, 90%);
        }

        /* 头部样式 */
        header {
            text-align: center;
            margin-bottom: 2rem;
            position: relative;
            padding-top: 1.5rem;
        }

        header h1 {
            font-size: 1.75rem;
            font-weight: bold;
            color: hsl(0, 0%, 10%);
            margin-bottom: 0.5rem;
        }

        @media (min-width: 768px) {
            header h1 {
                font-size: 2.5rem;
            }
        }

        header p {
            color: hsl(217, 91%, 60%);
            font-size: 1.125rem;
            margin-bottom: 1rem;
        }

        .contact-info {
            display: flex;
            flex-wrap: wrap;
            justify-content: center;
            gap: 0.75rem 1.5rem;
            font-size: 0.875rem;
            color: hsl(183, 14%, 25%);
        }

        /* 在超小屏幕上调整联系方式布局 */
        @media (max-width: 360px) {
            .contact-info {
                flex-direction: column;
                align-items: center;
                gap: 0.5rem;
            }
        }

        .contact-info div {
            display: flex;
            align-items: center;
        }

        .contact-info i {
            margin-right: 0.5rem;
        }

        /* 职业概述样式 */
        .summary p {
            color: hsl(0, 0%, 50%);
            line-height: 1.6;
            text-align: justify;
        }

        /* 工作经历样式 */
        .experience-entry {
            margin-bottom: 1.5rem;
        }

        .experience-header {
            display: flex;
            flex-direction: column;
        }

        @media (min-width: 768px) {
            .experience-header {
                flex-direction: row;
                justify-content: space-between;
                align-items: flex-start;
            }
        }

        .experience-header .entry-meta {
            margin-top: 0.25rem;
        }

        @media (min-width: 768px) {
            .experience-header .entry-meta {
                margin-top: 0;
            }
        }

        .experience-details {
            color: hsl(0, 0%, 50%);
            margin-top: 0.5rem;
            padding-left: 0.5rem;
        }

        .experience-details ul {
            list-style-type: disc;
            list-style-position: inside;
            padding-left: 0.5rem;
        }

        .experience-details li {
            margin-bottom: 0.5rem;
            line-height: 1.5;
        }

        /* 教育背景样式 */
        .education-header {
            display: flex;
            flex-direction: column;
        }

        @media (min-width: 768px) {
            .education-header {
                flex-direction: row;
                justify-content: space-between;
                align-items: flex-start;
            }
        }

        .education-header .entry-meta {
            margin-top: 0.25rem;
        }

        @media (min-width: 768px) {
            .education-header .entry-meta {
                margin-top: 0;
            }
        }

        .education-details {
            color: hsl(0, 0%, 50%);
            margin-top: 0.5rem;
            padding-left: 0.5rem;
        }

        .education-details ul {
            list-style-type: disc;
            list-style-position: inside;
            padding-left: 0.5rem;
        }

        .education-details li {
            margin-bottom: 0.5rem;
            line-height: 1.5;
        }

        /* 技能与证书样式 */
        .skills-container {
            display: grid;
            grid-template-columns: 1fr;
            gap: 1.5rem;
            position: relative;
            padding-top: 1.5rem;
        }

        @media (min-width: 768px) {
            .skills-container {
                grid-template-columns: 1fr 1fr;
            }
        }

        .skills-list {
            display: flex;
            flex-wrap: wrap;
            gap: 0.5rem;
            margin-top: 0.5rem;
        }

        .skill-tag {
            background-color: hsl(217, 91%, 90%);
            color: hsl(221, 70%, 33%);
            padding: 0.25rem 0.75rem;
            border-radius: 9999px;
            font-size: 0.875rem;
        }

        .certifications-list {
            color: hsl(0, 0%, 50%);
            margin-top: 0.5rem;
        }

        .certifications-list li {
            display: flex;
            justify-content: space-between;
            margin-bottom: 0.5rem;
            list-style: none;
            flex-wrap: wrap;
        }

        .certifications-list .cert-date {
            font-size: 0.875rem;
            color: hsl(183, 14%, 25%);
            margin-left: 0.5rem;
        }

        /* 编辑状态样式 */
        [contenteditable="true"] {
            background-color: hsl(48, 100%, 90%);
            outline: 1px dashed hsl(48, 100%, 60%);
        }

        /* 打印样式优化 */
        @media print {
            .fa, .module-controls {
                display: none !important;
            }

            body {
                background-color: hsl(0, 0%, 100%);
                padding: 0;
            }

            .resume-container {
                box-shadow: none;
                padding: 0;
                border-radius: 0;
            }
        }
    </style>
</head>
<body>
    <div class="resume-container">
        <!-- 个人信息头部 -->
        <header id="header-module">
            <div class="module-controls">
                <button class="module-control-btn edit-btn" data-target="header-module">
                    <i class="fa fa-pencil"></i> 编辑
                </button>
                <button class="module-control-btn delete-btn" data-target="header-module">
                    <i class="fa fa-trash" style="color: hsl(0, 100%, 60%);"></i> 删除
                </button>
            </div>
            {% if (info.name.size != 0) %}
            <h1 contenteditable="false">{% info.name %}</h1>
            {% /if %}
            <p contenteditable="false">{% if (info.position.size != 0) %} {% info.position %} {% /if %} {% if (info.years.size != 0) %} | {% info.years %} {% /if %}</p>
            <div class="contact-info">
                {% if (info.phone.size != 0) %}
                <div>
                    <i class="fa fa-phone"></i>
                    <span contenteditable="false">{% info.phone %}</span>
                </div>
                {% /if %}
                {% if (info.email.size != 0) %}
                <div>
                    <i class="fa fa-envelope"></i>
                    <span contenteditable="false">{% info.email %}</span>
                </div>
                {% /if %}
                {% if (info.address.size != 0) %}
                <div>
                    <i class="fa fa-map-marker"></i>
                    <span contenteditable="false">{% info.address %}</span>
                </div>
                {% /if %}
            </div>
        </header>

        <!-- 职业概述 -->
        {% if (info.careerOverview.trimStart().trimEnd().size != 0) %}
        <section class="summary" id="summary-module">
            <div class="module-controls">
                <button class="module-control-btn edit-btn" data-target="summary-module">
                    <i class="fa fa-pencil"></i> 编辑
                </button>
                <button class="module-control-btn delete-btn" data-target="summary-module">
                    <i class="fa fa-trash" style="color: hsl(0, 100%, 60%);"></i> 删除
                </button>
            </div>
            <h2 class="section-title">
                <i class="fa fa-user-circle"></i>职业概述
            </h2>
            <p contenteditable="false">
                {% info.careerOverview %}
            </p>
        </section>
        {% /if %}

        <!-- 工作经历 -->
        {% if (info.workExperience.size != 0) %}
        <section id="experience-module">
            <div class="module-controls">
                <button class="module-control-btn edit-btn" data-target="experience-module">
                    <i class="fa fa-pencil"></i> 编辑
                </button>
                <button class="module-control-btn delete-btn" data-target="experience-module">
                    <i class="fa fa-trash" style="color: hsl(0, 100%, 60%);"></i> 删除
                </button>
            </div>
            <h2 class="section-title">
                <i class="fa fa-briefcase"></i>工作经历
            </h2>

            {% for workItem in info.workExperience %}
            <div class="experience-entry">
                <div class="experience-header">
                    <div>
                        <h3 class="entry-title" contenteditable="false">{% workItem.positionTitle %}</h3>
                        <p style="color: hsl(217, 91%, 60%);" contenteditable="false">{% workItem.company %}</p>
                    </div>
                    <p class="entry-meta" contenteditable="false">{% workItem.time %}</p>
                </div>
                <div class="experience-details">
                    <ul>
                        {% for item in workItem.content %}
                            <li contenteditable="false">{% item %}</li>
                        {% /for %}
                    </ul>
                </div>
            </div>
            {% /for %}
        </section>
        {% /if %}

        <!-- 教育背景 -->
        {% if (info.education.size != 0) %}
        <section id="education-module">
            <div class="module-controls">
                <button class="module-control-btn edit-btn" data-target="education-module">
                    <i class="fa fa-pencil"></i> 编辑
                </button>
                <button class="module-control-btn delete-btn" data-target="education-module">
                    <i class="fa fa-trash" style="color: hsl(0, 100%, 60%);"></i> 删除
                </button>
            </div>
            <h2 class="section-title">
                <i class="fa fa-graduation-cap"></i>教育背景
            </h2>
            {% for eduItem in info.education %}
                <div class="education-header">
                    <div>
                        <h3 class="entry-title" contenteditable="false">{% eduItem.major %} | {% eduItem.educationBG %}</h3>
                        <p style="color: hsl(217, 91%, 60%);" contenteditable="false">{% eduItem.university %}</p>
                    </div>
                    <p class="entry-meta" contenteditable="false">{% eduItem.time %}</p>
                </div>
                <div class="education-details">
                    <ul>
                        {% for item in eduItem.content %}
                            <li contenteditable="false">{% item %}</li>
                        {% /for %}
                    </ul>
                </div>
            {% /for %}
        </section>
        {% /if %}


        <!-- 技能与证书 -->
        <section class="skills-container" id="skills-module">
            {% if (info.skills.size != 0) %}
            <div class="module-controls">
                <button class="module-control-btn edit-btn" data-target="skills-module">
                    <i class="fa fa-pencil"></i> 编辑
                </button>
                <button class="module-control-btn delete-btn" data-target="skills-module">
                    <i class="fa fa-trash" style="color: hsl(0, 100%, 60%);"></i> 删除
                </button>
            </div>
            <!-- 专业技能 -->
            <div>
                <h2 class="section-title">
                    <i class="fa fa-cogs"></i>专业技能
                </h2>
                <div class="skills-list">
                    {% for skill in info.skills %}
                        <span class="skill-tag" contenteditable="false">{% skill %}</span>
                    {% /for %}
                </div>
            </div>
            {% /if %}

            {% if (info.certificate.size != 0) %}
            <div class="module-controls">
                <button class="module-control-btn edit-btn" data-target="certificate-module">
                    <i class="fa fa-pencil"></i> 编辑
                </button>
                <button class="module-control-btn delete-btn" data-target="certificate-module">
                    <i class="fa fa-trash" style="color: hsl(0, 100%, 60%);"></i> 删除
                </button>
            </div>
            <!-- 证书与培训 -->
            <div>
                <h2 class="section-title">
                    <i class="fa fa-certificate"></i>证书与培训
                </h2>
                <ul class="certifications-list">
                    {% for item in info.certificate %}
                        <li>
                            <span contenteditable="false">{% item.name %}</span>
                            <span class="cert-date" contenteditable="false">{% item.time %}</span>
                        </li>
                    {% /for %}
                </ul>
            </div>
            {% /if %}
        </section>
    </div>

    <script>
        // 存储待删除的模块
        let moduleToDelete = null;

        // 编辑功能实现
        document.querySelectorAll('.edit-btn').forEach(button => {
            button.addEventListener('click', function() {
                const targetId = this.getAttribute('data-target');
                const module = document.getElementById(targetId);

                // 切换编辑状态
                const editableElements = module.querySelectorAll('[contenteditable]');
                editableElements.forEach(el => {
                    const currentState = el.getAttribute('contenteditable') === 'true';
                    el.setAttribute('contenteditable', !currentState);

                    // 视觉反馈
                    if (!currentState) {
                        this.innerHTML = '<i class="fa fa-check" style="color: hsl(120, 100%, 30%);"></i> 完成';
                        el.focus();
                    } else {
                        this.innerHTML = '<i class="fa fa-pencil"></i> 编辑';
                    }
                });
            });
        });

        // 删除功能实现 - 使用自定义对话框
        document.querySelectorAll('.delete-btn').forEach(button => {
            button.addEventListener('click', function() {
                const targetId = this.getAttribute('data-target');
                moduleToDelete = document.getElementById(targetId);
                const moduleTitle = moduleToDelete.querySelector('h2, h1')?.textContent.trim() || '此模块';

                // 设置对话框消息
                dialogMessage.textContent = `确定要删除"\${moduleTitle}"吗？`;

                // 显示自定义对话框
                confirmDialog.classList.add('active');
            });
        });
    </script>
</body>
</html>
    '''
}
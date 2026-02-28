/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.ui.html

import magic.dsl.*
import magic.prelude.*

@jsonable
public class ProjectInfo {
    @field["项目名称"]
    let name: String
    @field["所在公司"]
    let company: String
    @field["项目时间"]
    let time: String
    @field["参与角色"]
    let role: String
    @field["项目简洁"]
    let description: String
}

@ui[
    description: '''
    功能类型：专业商务型简历 UI，
    使用场景：展示商务岗位求职相关信息，如个人技能栈、项目经验、工作履历、教育背景、证书资质、技术成果（论文 / 专利），
    交互特性：信息展示型，仅用于呈现信息，无交互，
    风格属性：复杂型，仅适合展示单个UI，不适合与其他UI进行组合
    ''',
    parameters: {
        info: "个人简历需要收集的信息"
    },
    thumbnail: "D:/Work/Cangjie/deveco5.1.1/CangjieMagic-HarmonyOS/entry/src/main/cangjie/business_resume.png",
    title: "专业商务模板",
    category: "resume",
    kind: "display"
]
public func businessResume(info: CommonResumeInfo, pi: Array<ProjectInfo>) {
    '''
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>商务简历模板</title>
    <link href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css" rel="stylesheet">
    <style>
        /* 基础样式与颜色定义 - 头部颜色调深 */
        :root {
            --primary: hsl(220, 80%, 20%); /* 更深的蓝色主色 */
            --primary-light: hsl(220, 70%, 30%); /* 稍浅的蓝色 */
            --primary-lighter: hsl(220, 60%, 45%); /* 更浅的蓝色 */
            --text-dark: hsl(220, 20%, 15%); /* 深色文本 */
            --text-gray: hsl(220, 10%, 40%); /* 灰色文本 */
            --bg-light: hsl(220, 10%, 97%); /* 浅色背景 */
            --border-light: hsl(220, 20%, 85%); /* 浅色边框 */
            --white: hsl(0, 0%, 100%); /* 白色 */
            --text-light: hsl(220, 10%, 95%); /* 极浅的文本色，提高对比度 */
        }

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
            font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
        }

        body {
            background-color: var(--bg-light);
            color: var(--text-dark);
            line-height: 1.6;
            padding: 20px;
        }

        /* 简历容器 */
        .resume-container {
            max-width: 1000px;
            margin: 0 auto;
            background: white;
            padding: 0;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
            overflow: hidden;
        }

        /* 头部样式 - 更深的蓝色背景 */
        header {
            background-color: var(--primary);
            padding: 45px;
            color: var(--white);
            margin-bottom: 30px;
            position: relative;
            overflow: hidden;
        }

        /* 增加细微纹理，增强深度感 */
        header::after {
            content: "";
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background-image: radial-gradient(rgba(255,255,255,0.05) 1px, transparent 1px);
            background-size: 20px 20px;
            pointer-events: none;
        }

        .header-content {
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            position: relative; /* 确保内容在纹理之上 */
        }

        .name-title h1 {
            color: var(--white);
            font-size: 2.8rem;
            margin-bottom: 8px;
            transition: color 0.3s ease, transform 0.3s ease;
            text-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }

        .name-title h1:hover {
            color: var(--text-light);
            transform: translateX(3px);
        }

        .name-title h2 {
            color: var(--text-light);
            font-size: 1.4rem;
            font-weight: 600;
            opacity: 0.95;
        }

        .contact-info {
            margin-top: 15px;
            text-align: right;
        }

        .contact-info p {
            margin-bottom: 6px;
            display: flex;
            justify-content: flex-end;
            align-items: center;
            color: var(--text-light);
            font-size: 0.95rem;
        }

        .contact-info i {
            color: var(--primary-lighter);
            margin-right: 10px;
            width: 16px;
        }

        /* 主要内容区域内边距 */
        .resume-content {
            padding: 0 45px 45px;
        }

        /* 网格布局 */
        .resume-grid {
            display: grid;
            grid-template-columns: 1fr;
            gap: 30px;
        }

        /* 章节通用样式 */
        section {
            margin-bottom: 30px;
            opacity: 0;
            transform: translateY(20px);
            transition: opacity 0.6s ease-out, transform 0.6s ease-out;
        }

        section.visible {
            opacity: 1;
            transform: translateY(0);
        }

        .section-title {
            color: var(--primary);
            font-size: 1.2rem;
            border-bottom: 1px solid var(--primary-lighter);
            padding-bottom: 5px;
            margin-bottom: 15px;
            display: flex;
            align-items: center;
        }

        .section-title i {
            margin-right: 8px;
        }

        /* 技能条样式 */
        .skills-list {
            list-style: none;
        }

        .skill-item {
            margin-bottom: 10px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .skill-name {
            font-size: 0.9rem;
            width: 35%;
        }

        .skill-bar-container {
            width: 60%;
            height: 8px;
            background-color: var(--border-light);
            border-radius: 4px;
            overflow: hidden;
        }

        .skill-bar {
            height: 100%;
            background-color: var(--primary);
        }

        /* 工作经验与项目经验样式 */
        .experience-item, .project-item {
            margin-bottom: 25px;
            padding: 10px;
            border-radius: 4px;
            transition: background-color 0.3s ease;
        }

        .experience-item:hover, .project-item:hover {
            background-color: hsl(220, 5%, 95%);
        }

        .experience-header, .project-header {
            display: flex;
            flex-direction: column;
            margin-bottom: 10px;
        }

        .position, .project-name {
            font-weight: bold;
            font-size: 1.1rem;
            margin-bottom: 3px;
        }

        .company, .project-meta {
            color: var(--primary-light);
            font-size: 0.95rem;
            margin-bottom: 5px;
        }

        .period {
            color: var(--text-gray);
            font-size: 0.85rem;
        }

        .experience-details {
            font-size: 0.9rem;
            padding-left: 20px;
        }

        .experience-details li {
            margin-bottom: 5px;
        }

        .project-description {
            font-size: 0.9rem;
        }

        /* 教育背景与证书样式 */
        .education-item, .certificate-item {
            margin-bottom: 15px;
        }

        .degree, .certificate-name {
            font-weight: bold;
            margin-bottom: 2px;
        }

        .school, .certificate-issuer {
            color: var(--text-gray);
            font-size: 0.85rem;
        }

        .certificates-list {
            list-style: none;
        }

        .certificate-item {
            font-size: 0.9rem;
            position: relative;
            padding-left: 18px;
        }

        .certificate-item::before {
            content: "•";
            color: var(--primary);
            position: absolute;
            left: 0;
        }

        /* 个人简介与自我评价 */
        .bio-text, .self-evaluation {
            font-size: 0.95rem;
            line-height: 1.7;
        }

        /* 响应式设计 */
        @media (min-width: 768px) {
            .resume-grid {
                grid-template-columns: 1fr 2fr;
            }

            .header-content {
                flex-direction: row;
                align-items: flex-end;
            }

            .contact-info {
                margin-top: 0;
            }

            .experience-header, .project-header {
                flex-direction: row;
                justify-content: space-between;
                align-items: flex-start;
            }

            .company, .project-meta {
                margin-bottom: 0;
            }
        }
    </style>
</head>
<body>
    <!-- 简历容器 -->
    <div class="resume-container">
        <!-- 个人信息头部 - 更深的蓝色背景 -->
        <header>
            <div class="header-content">
                <div class="name-title">
                    <h1>{% info.name %}</h1>
                    <h2>{% info.position %}</h2>
                </div>

                <div class="contact-info">
                    <p>
                        <i class="fa fa-envelope-o"></i>
                        <span>{% info.email %}</span>
                    </p>
                    <p>
                        <i class="fa fa-phone"></i>
                        <span>{% info.phone %}</span>
                    </p>
                    <p>
                        <i class="fa fa-map-marker"></i>
                        <span>{% info.address %}</span>
                    </p>
                </div>
            </div>
        </header>

        <!-- 主要内容区域 -->
        <div class="resume-content">
            <div class="resume-grid">
                <!-- 左侧栏 -->
                <div class="left-column">
                    <!-- 个人简介 -->
                    <section>
                        <h3 class="section-title">
                            <i class="fa fa-user-circle-o"></i>个人简介
                        </h3>
                        <p class="bio-text">
                            {% info.careerOverview %}
                        </p>
                    </section>

                    <!-- 技能 -->
                    {% if (info.skills.size != 0) %}
                    <section>
                        <h3 class="section-title">
                            <i class="fa fa-briefcase"></i>专业技能
                        </h3>
                        <ul class="skills-list">
                            {% for skill in info.skills %}
                                <li class="skill-item">
                                    <span class="skill-name">{% skill %}</span>
                                    <div class="skill-bar-container">
                                        <div class="skill-bar" style="width: 90%"></div>
                                    </div>
                                </li>
                            {% /for %}
                        </ul>
                    </section>
                    {% /if %}

                    <!-- 教育背景 -->
                    {% if (info.education.size != 0) %}
                    <section>
                        <h3 class="section-title">
                            <i class="fa fa-graduation-cap"></i>教育背景
                        </h3>
                        <div class="education-list">
                            {% for eduItem in info.education %}
                                <div class="education-item">
                                    <h4 class="degree">{% eduItem.major %} | {% eduItem.educationBG %}</h4>
                                    <p class="school">{% eduItem.university %} | {% eduItem.time %}</p>
                                </div>
                            {% /for %}
                        </div>
                    </section>
                    {% /if %}

                    <!-- 证书 -->
                    {% if (info.certificate.size != 0) %}
                    <section>
                        <h3 class="section-title">
                            <i class="fa fa-certificate"></i>证书
                        </h3>
                        <ul class="certificates-list">
                            {% for item in info.certificate %}
                                <li class="certificate-item">{% item.name %}</li>
                            {% /for %}
                        </ul>
                    </section>
                    {% /if %}
                </div>

                <!-- 右侧栏 -->
                <div class="right-column">
                    <!-- 工作经验 -->
                    {% if (info.workExperience.size != 0) %}
                    <section>
                        <h3 class="section-title">
                            <i class="fa fa-history"></i>工作经验
                        </h3>

                        <div class="experience-list">
                            {% for workItem in info.workExperience %}
                                <div class="experience-item">
                                    <div class="experience-header">
                                        <div>
                                            <h4 class="position">{% workItem.positionTitle %}</h4>
                                            <p class="company">{% workItem.company %}</p>
                                        </div>
                                        <p class="period">{% workItem.time %}</p>
                                    </div>
                                    <ul class="experience-details">
                                        {% for item in workItem.content %}
                                            <li>{% item %}</li>
                                        {% /for %}
                                    </ul>
                                </div>
                            {% /for %}
                        </div>
                    </section>
                    {% /if %}

                    <!-- 项目经验 -->
                     {% if (pi.size != 0) %}
                    <section>
                        <h3 class="section-title">
                            <i class="fa fa-tasks"></i>主要项目
                        </h3>

                        <div class="projects-list">
                            {% for item in pi %}
                            <div class="project-item">
                                <div class="project-header">
                                    <div>
                                        <h4 class="project-name">{% item.name %}</h4>
                                        <p class="project-meta">{% item.company %} | {% item.time %}</p>
                                    </div>
                                    <p class="period">{% item.role %}</p>
                                </div>
                                <p class="project-description">
                                    {% item.description %}
                                </p>
                            </div>
                            {% /for %}
                        </div>
                    </section>
                    {% /if %}
                </div>
            </div>
        </div>
    </div>

    <script>
        // 滚动显示动画
        document.addEventListener('DOMContentLoaded', function() {
            const sections = document.querySelectorAll('section');

            // 初始检查可见的部分
            const checkVisibility = () => {
                sections.forEach(section => {
                    const rect = section.getBoundingClientRect();
                    const windowHeight = window.innerHeight || document.documentElement.clientHeight;

                    // 如果元素进入视口
                    if (rect.top <= windowHeight * 0.8) {
                        section.classList.add('visible');
                    }
                });
            };

            // 初始检查
            checkVisibility();

            // 滚动时检查
            window.addEventListener('scroll', checkVisibility);
        });
    </script>
</body>
</html>
    '''
}
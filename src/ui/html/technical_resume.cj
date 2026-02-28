/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.ui.html

import magic.dsl.*
import magic.prelude.*


@jsonable
public class ProjectItem {
    @field["项目名称"]
    let projectName: String
    @field["项目角色（如核心开发者等）"]
    let role: String
    @field["项目开发时间，格式建议：YYYY年MM月 - YYYY年MM月（至今）"]
    let time: String
    @field["项目简要描述"]
    let desc: String
    @field["项目要点"]
    let content: Array<String>
}

@jsonable
public class openSourceItem {
    @field["开源项目名称"]
    let projectName: String
    @field["开源项目类型"]
    let kind: String
    @field["开源项目简介"]
    let desc: String
}

@jsonable
public class TechnicalResumeInfo {
    @field["姓名"]
    let name: String
    @field["联系电话"]
    let phone: String
    @field["github联系方式"]
    let github: String
    @field["linkedin联系方式"]
    let linkedin: String
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
    @field["项目经历列表"]
    let projectExperience: Array<ProjectItem>
    @field["教育经历列表"]
    let education: Array<EducationItem>
    @field["专业技能"]
    let skills: Array<String>
    @field["证书列表"]
    let certificate: Array<CertificateItem>
    @field["开源贡献"]
    let openSource: Array<openSourceItem>
}

@ui[
    description: '''
    功能类型：学术科研型简历 UI，
    使用场景：展示技术岗位求职相关信息，如个人技能栈、项目经验、工作履历、教育背景、证书资质、技术成果（论文 / 专利），
    交互特性：信息展示型，仅用于呈现信息，无交互，
    风格属性：复杂型，仅适合展示单个UI，不适合与其他UI进行组合
    ''',
    parameters: {
        info: "个人简历需要收集的信息"
    },
    thumbnail: "D:/Work/Cangjie/deveco5.1.1/CangjieMagic-HarmonyOS/entry/src/main/cangjie/technical_resume.png",
    title: "学术科研模板",
    category: "resume",
    kind: "display"
]
public func technicalResume(info: TechnicalResumeInfo) {
    '''
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>技术型简历</title>
  <!-- 引入Font Awesome -->
  <link href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css" rel="stylesheet">
  <style>
    /* 颜色定义 - hsl格式 */
    :root {
      --primary: hsl(210, 100%, 35%); /* 深蓝色 */
      --primary-dark: hsl(210, 100%, 25%); /* 深一点的蓝色 */
      --secondary: hsl(195, 100%, 40%); /* 青色 */
      --secondary-dark: hsl(195, 100%, 30%); /* 深青色 */
      --dark: hsl(210, 20%, 15%); /* 青黑色 */
      --text: hsl(210, 20%, 20%); /* 文本颜色 */
      --text-light: hsl(210, 10%, 40%); /* 次要文本 */
      --bg-light: hsl(210, 15%, 95%); /* 浅色背景 */
      --bg-white: hsl(0, 0%, 100%); /* 白色背景 */
      --border: hsl(210, 20%, 85%); /* 边框颜色 */
      --accent: hsl(260, 70%, 50%); /* 强调色 */
    }

    /* 基础样式重置 */
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }

    body {
      font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
      background-color: var(--bg-light);
      color: var(--text);
      line-height: 1.6;
      padding: 20px 0;
    }

    .container {
      max-width: 1200px;
      margin: 0 auto;
      background-color: var(--bg-white);
      box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
      border-radius: 8px;
      overflow: hidden;
    }

    /* 头部样式 */
    header {
      background: linear-gradient(135deg, var(--primary), var(--secondary));
      color: white;
      padding: 40px;
      position: relative;
      overflow: hidden;
    }

    header::before {
      content: '';
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background-image: url(\'https://picsum.photos/id/1/1000/300\');
      background-size: cover;
      background-position: center;
      opacity: 0.1;
    }

    .header-content {
      position: relative;
      z-index: 1;
    }

    .name-title {
      margin-bottom: 20px;
    }

    .name {
      font-size: clamp(2rem, 5vw, 3rem);
      font-weight: 700;
      margin-bottom: 10px;
      text-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
    }

    .title {
      font-size: clamp(1.2rem, 3vw, 1.5rem);
      opacity: 0.9;
    }

    .contact-info {
      display: flex;
      flex-wrap: wrap;
      gap: 20px;
      margin-bottom: 20px;
    }

    .contact-item {
      display: flex;
      align-items: center;
      font-size: 14px;
    }

    .contact-item i {
      margin-right: 8px;
    }

    .contact-item a {
      color: white;
      text-decoration: none;
    }

    .contact-item a:hover {
      text-decoration: underline;
    }

    /* 主内容样式 */
    main {
      padding: 40px;
      display: grid;
      grid-template-columns: 1fr;
      gap: 40px;
    }

    @media (min-width: 992px) {
      main {
        grid-template-columns: 1fr 2fr;
      }
    }

    .section {
      margin-bottom: 30px;
      opacity: 0;
      transform: translateY(20px);
      transition: opacity 0.6s ease-out, transform 0.6s ease-out;
    }

    .section-visible {
      opacity: 1;
      transform: translateY(0);
    }

    .section-title {
      font-size: 1.4rem;
      color: var(--primary);
      border-bottom: 2px solid var(--primary);
      padding-bottom: 8px;
      margin-bottom: 15px;
      font-weight: 600;
    }

    /* 左侧边栏样式 */
    .sidebar-section {
      margin-bottom: 40px;
    }

    /* 个人简介 */
    .profile p {
      color: var(--text-light);
      line-height: 1.7;
    }

    /* 技能部分 */
    .skills-category {
      margin-bottom: 20px;
    }

    .skills-title {
      font-weight: 600;
      margin-bottom: 10px;
      color: var(--dark);
    }

    .skills-tags {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
    }

    .skill-tag {
      background-color: hsla(210, 100%, 35%, 0.1);
      color: var(--primary);
      padding: 4px 12px;
      border-radius: 20px;
      font-size: 13px;
    }

    /* 教育背景 */
    .education-item {
      margin-bottom: 25px;
    }

    .education-header {
      display: flex;
      justify-content: space-between;
      margin-bottom: 5px;
    }

    .education-degree {
      font-weight: 600;
    }

    .education-date {
      color: var(--text-light);
      font-size: 14px;
    }

    .education-school {
      color: var(--text);
      margin-bottom: 5px;
    }

    .education-details {
      color: var(--text-light);
      font-size: 14px;
    }

    /* 证书与荣誉 */
    .certificates-list {
      list-style: none;
    }

    .certificate-item {
      display: flex;
      margin-bottom: 15px;
    }

    .certificate-item i {
      color: var(--accent);
      margin-right: 10px;
      margin-top: 3px;
    }

    /* 右侧内容样式 */
    /* 工作经验 */
    .experience-list {
      position: relative;
    }

    .experience-list::before {
      content: '';
      position: absolute;
      top: 0;
      bottom: 0;
      left: 8px;
      width: 2px;
      background-color: var(--border);
    }

    .experience-item {
      position: relative;
      padding-left: 30px;
      margin-bottom: 40px;
    }

    .experience-item:last-child {
      margin-bottom: 0;
    }

    .experience-item::before {
      content: '';
      position: absolute;
      left: 0;
      top: 5px;
      width: 18px;
      height: 18px;
      border-radius: 50%;
      background-color: var(--primary);
    }

    .experience-header {
      display: flex;
      flex-wrap: wrap;
      justify-content: space-between;
      margin-bottom: 10px;
    }

    .experience-position {
      font-weight: 600;
      font-size: 1.1rem;
    }

    .experience-company {
      color: var(--primary);
      margin-bottom: 5px;
    }

    .experience-date {
      color: var(--text-light);
      font-size: 14px;
    }

    .experience-details {
      margin-bottom: 15px;
    }

    .experience-details li {
      margin-bottom: 10px;
      display: flex;
    }

    .experience-details li i {
      color: var(--primary);
      margin-right: 10px;
      margin-top: 3px;
    }

    .experience-tags {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
    }

    .experience-tag {
      background-color: hsl(210, 10%, 90%);
      color: var(--text);
      padding: 3px 10px;
      border-radius: 4px;
      font-size: 12px;
    }

    /* 项目经验 */
    .projects-list {
      display: flex;
      flex-direction: column;
      gap: 25px;
    }

    .project-card {
      background-color: var(--bg-light);
      padding: 20px;
      border-radius: 6px;
      transition: box-shadow 0.3s ease;
    }

    .project-card:hover {
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
    }

    .project-header {
      display: flex;
      flex-wrap: wrap;
      justify-content: space-between;
      align-items: flex-start;
      margin-bottom: 10px;
    }

    .project-title {
      font-weight: 600;
      font-size: 1.1rem;
    }

    .project-role {
      color: var(--text-light);
      font-size: 14px;
      margin-bottom: 10px;
    }

    .project-link {
      color: var(--primary);
      text-decoration: none;
      font-size: 14px;
      display: flex;
      align-items: center;
    }

    .project-link i {
      margin-right: 5px;
      font-size: 12px;
    }

    .project-link:hover {
      text-decoration: underline;
    }

    .project-description {
      margin-bottom: 15px;
      color: var(--text-light);
    }

    .project-achievements {
      margin-bottom: 15px;
      font-size: 14px;
    }

    .project-achievements li {
      margin-bottom: 8px;
      display: flex;
    }

    .project-achievements li i {
      color: var(--secondary);
      margin-right: 10px;
      margin-top: 3px;
    }

    .project-tags {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
    }

    .project-tag {
      background-color: hsl(210, 10%, 85%);
      color: var(--text);
      padding: 3px 10px;
      border-radius: 4px;
      font-size: 12px;
    }

    /* 开源贡献 */
    .open-source-list {
      display: flex;
      flex-direction: column;
      gap: 20px;
    }

    .open-source-item {
      display: flex;
      gap: 15px;
    }

    .open-source-icon {
      color: var(--dark);
      font-size: 2rem;
      margin-top: 3px;
    }

    .open-source-info {
      flex: 1;
    }

    .open-source-title {
      font-weight: 600;
      margin-bottom: 3px;
    }

    .open-source-meta {
      color: var(--text-light);
      font-size: 13px;
      margin-bottom: 8px;
    }

    .open-source-description {
      color: var(--text-light);
      font-size: 14px;
    }

    /* 响应式调整 */
    @media (max-width: 768px) {
      header, main, footer {
        padding: 20px;
      }

      .contact-info {
        gap: 15px 20px;
      }

      .experience-header {
        flex-direction: column;
      }

      .experience-date {
        margin-top: 5px;
      }
    }
  </style>
</head>
<body>
  <div class="container">
    <!-- 顶部个人信息区域 -->
    <header>
      <div class="header-content">
        <div class="name-title">
          {% if (info.name.size != 0) %}
            <h1 class="name">{% info.name %}</h1>
          {% /if %}
          {% if (info.position.size != 0) %}
            <h2 class="title">{% info.position %}</h2>
          {% /if %}
        </div>

        <div class="contact-info">
          {% if (info.email.size != 0) %}
              <div class="contact-item">
                <i class="fa fa-envelope-o" aria-hidden="true"></i>
                <span>{% info.email %}</span>
              </div>
          {% /if %}
          {% if (info.phone.size != 0) %}
              <div class="contact-item">
                <i class="fa fa-phone" aria-hidden="true"></i>
                <span>{% info.phone %}</span>
              </div>
          {% /if %}
          {% if (info.address.size != 0) %}
              <div class="contact-item">
                <i class="fa fa-map-marker" aria-hidden="true"></i>
                <span>{% info.address %}</span>
              </div>
          {% /if %}
        </div>

        <div class="contact-info">
          {% if (info.github.size != 0) %}
              <div class="contact-item">
                <i class="fa fa-github" aria-hidden="true"></i>
                <a href="">{% info.github %}</a>
              </div>
          {% /if %}
          {% if (info.linkedin.size != 0) %}
              <div class="contact-item">
                <i class="fa fa-linkedin" aria-hidden="true"></i>
                <a href="">{% info.linkedin %}</a>
              </div>
          {% /if %}
        </div>
      </div>
    </header>

    <!-- 主要内容区域 -->
    <main>
      <!-- 左侧边栏 -->
      <div class="sidebar">
        <!-- 个人简介 -->
        {% if (info.careerOverview.size != 0) %}
            <section class="section profile sidebar-section">
              <h3 class="section-title">个人简介</h3>
              <p>
                {% info.careerOverview %}
              </p>
            </section>
        {% /if %}

        <!-- 技术技能 -->
        {% if (info.skills.size != 0) %}
            <section class="section skills sidebar-section">
              <h3 class="section-title">技术技能</h3>

              <div class="skills-category">
                <div class="skills-tags">
                  {% for skill in info.skills %}
                    <span class="skill-tag">{% skill %}</span>
                  {% /for %}
                </div>
              </div>
            </section>
        {% /if %}

        <!-- 教育背景 -->
        {% if (info.education.size != 0) %}
            <section class="section education sidebar-section">
              <h3 class="section-title">教育背景</h3>
              {% for eduItem in info.education %}
                  <div class="education-item">
                    <div class="education-header">
                      <h4 class="education-degree">{% eduItem.major %} - {% eduItem.educationBG %}</h4>
                      <span class="education-date">{% eduItem.time %}</span>
                    </div>
                    <p class="education-school">{% eduItem.university %}</p>
                    {% for item in eduItem.content %}
                        <p class="education-details">{% item %}</p>
                    {% /for %}
                  </div>
               {% /for %}
            </section>
        {% /if %}

        <!-- 证书与荣誉 -->
        {% if (info.certificate.size != 0) %}
            <section class="section certificates sidebar-section">
              <h3 class="section-title">证书与荣誉</h3>

              <ul class="certificates-list">
                {% for item in info.certificate %}
                    <li class="certificate-item">
                      <i class="fa fa-trophy" aria-hidden="true"></i>
                      <span>{% item.name %}</span>
                    </li>
                {% /for %}
              </ul>
            </section>
        {% /if %}
      </div>

      <!-- 右侧主内容 -->
      <div class="main-content">
        <!-- 工作经验 -->
        {% if (info.workExperience.size != 0) %}
            <section class="section experience">
              <h3 class="section-title">工作经验</h3>

              <div class="experience-list">
                <!-- 最近工作 -->
                {% for workItem in info.workExperience %}
                    <div class="experience-item">
                      <div class="experience-header">
                        <div>
                          <h4 class="experience-position">{% workItem.positionTitle %}</h4>
                          <p class="experience-company">{% workItem.company %}</p>
                        </div>
                        <span class="experience-date">{% workItem.time %}</span>
                      </div>

                      <ul class="experience-details">
                        {% for item in workItem.content %}
                            <li>
                              <i class="fa fa-angle-right" aria-hidden="true"></i>
                              <span>{% item %}</span>
                            </li>
                        {% /for %}
                      </ul>
                    </div>
                {% /for %}
              </div>
            </section>
        {% /if %}

        <!-- 项目经验 -->
        {% if (info.projectExperience.size != 0) %}
        <section class="section projects">
          <h3 class="section-title">项目经验</h3>

          <div class="projects-list">
            {% for projectItem in info.projectExperience %}
            <div class="project-card">
              <div class="project-header">
                <div>
                  <h4 class="project-title">{% projectItem.projectName %}</h4>
                  <p class="project-role">{% projectItem.role %} | {% projectItem.time %}</p>
                </div>
              </div>

              <p class="project-description">
                {% projectItem.desc %}
              </p>

              <ul class="project-achievements">
                {% for item in projectItem.content %}
                <li>
                  <i class="fa fa-check-circle" aria-hidden="true"></i>
                  <span>{% item %}</span>
                </li>
                {% /for %}
              </ul>
            </div>
            {% /for %}
        </section>
        {% /if %}

        <!-- 开源贡献 -->
        {% if (info.openSource.size != 0) %}
        <section class="section open-source">
          <h3 class="section-title">开源贡献</h3>

          <div class="open-source-list">
            {% for item in info.openSource %}
                <div class="open-source-item">
                  <div class="open-source-icon">
                    <i class="fa fa-github" aria-hidden="true"></i>
                  </div>
                  <div class="open-source-info">
                    <h4 class="open-source-title">{% item.projectName %}</h4>
                    <p class="open-source-meta">表单验证库 | 2.5k+ Star</p>
                    <p class="open-source-description">
                      一个轻量级的React表单验证库，支持自定义验证规则和异步验证，简化表单验证逻辑。
                      负责核心功能开发和文档编写，维护活跃的issue讨论区。
                    </p>
                  </div>
                </div>
            {% /for %}

            <div class="open-source-item">
              <div class="open-source-icon">
                <i class="fa fa-github" aria-hidden="true"></i>
              </div>
              <div class="open-source-info">
                <h4 class="open-source-title">vue-table-component</h4>
                <p class="open-source-meta">Vue表格组件 | 1.2k+ Star</p>
                <p class="open-source-description">
                  高性能Vue表格组件，支持排序、筛选、分页和自定义列。
                  贡献了虚拟滚动功能和国际化支持，解决了大数据量渲染性能问题。
                </p>
              </div>
            </div>
          </div>
        </section>
        {% /if %}
      </div>
    </main>
  </div>

  <!-- JavaScript -->
  <script>
    // 滚动显示动画
    document.addEventListener('DOMContentLoaded', function() {
      const sections = document.querySelectorAll('.section');

      const observerOptions = {
        root: null,
        rootMargin: '0px',
        threshold: 0.1
      };

      const observer = new IntersectionObserver(function(entries, observer) {
        entries.forEach(entry => {
          if (entry.isIntersecting) {
            entry.target.classList.add('section-visible');
            observer.unobserve(entry.target);
          }
        });
      }, observerOptions);

      sections.forEach(section => {
        observer.observe(section);
      });

      // 手动触发一次检查，确保可见区域的元素正确显示
      setTimeout(() => {
        sections.forEach(section => {
          const rect = section.getBoundingClientRect();
          if (rect.top < window.innerHeight && rect.bottom >= 0) {
            section.classList.add('section-visible');
          }
        });
      }, 100);
    });
  </script>
</body>
</html>
    '''
}
/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.ui.html

import magic.dsl.*
import magic.prelude.*
import std.collection.enumerate


@jsonable
public class Food {
    @field["菜的名称"]
    let name: String
    @field["准备时间，如'5分钟'"]
    let preTime: String
    @field["烹饪时间，如'5分钟'"]
    let cookingTime: String
    @field["难度，如'简单'"]
    let difficulty: String
    @field["分量，如'两人份'"]
    let personPortion: String
    @field["食材，明确具体的重量或数量"]
    let ingredients: Array<String>
    @field["烹饪步骤"]
    let steps: Array<String>
}

@ui[
    description: '''
    功能类型：食谱 UI・烹饪步骤展示型,
    使用场景：展示美食制作相关信息，如家常菜谱步骤、烘焙食谱教程、减脂餐制作流程、特色菜烹饪方法（含食材清单 / 步骤说明 / 烹饪时长）,
    交互特性：信息展示及操作交互型，通过翻页展示食谱内容；附带互动小游戏,
    风格属性：复杂型，仅适合展示单个UI，不适合与其他UI进行组合
    ''',
    parameters: {
        info: "菜品信息列表"
    },
    kind: "display"
]
public func recipeUI(info: Array<Food>) {
    '''
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>美味食谱 - 烹饪步骤排序版</title>
    <style>
        /* 全局样式重置 */
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
            font-family: 'Arial', sans-serif;
        }

        body {
            background-color: hsl(30, 20%, 95%);
            color: hsl(210, 15%, 20%);
            line-height: 1.6;
            padding: 1rem 0; /* 移动端减少上下内边距 */
            overflow-x: hidden;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 0 1rem;
        }

        /* 头部样式 - 响应式调整 */
        header {
            text-align: center;
            margin-bottom: 2rem; /* 移动端减少底部间距 */
            padding-bottom: 1rem;
            border-bottom: 2px solid hsl(30, 80%, 70%);
        }

        h1 {
            color: hsl(30, 80%, 50%);
            font-size: clamp(1.8rem, 5vw, 2.5rem); /* 响应式字体大小 */
            margin-bottom: 0.5rem;
            line-height: 1.2;
        }

        .subtitle {
            color: hsl(30, 60%, 40%);
            font-size: clamp(1rem, 2vw, 1.2rem); /* 响应式字体大小 */
            font-style: italic;
        }

        /* 食谱卡片容器 */
        .recipe-container {
            position: relative;
            width: 100%;
            height: auto;
            margin-bottom: 2rem;
            border-radius: 12px;
            box-shadow: 0 8px 24px hsla(30, 30%, 20%, 0.15);
        }

        /* 食谱卡片样式 - 增强响应式内边距 */
        .recipe-card {
            width: 100%;
            background-color: hsl(0, 0%, 100%);
            border-radius: 12px;
            padding: clamp(1rem, 3vw, 2rem); /* 响应式内边距 */
            transition: transform 0.5s ease-in-out;
            display: none;
        }

        .recipe-card.active {
            display: block;
            transform: translateX(0);
        }

        .recipe-card.next, .recipe-card.prev {
            display: none;
        }

        /* 食谱图片区域 - 优化移动端布局 */
        .recipe-images {
            display: flex;
            gap: 1rem;
            margin-bottom: 1.5rem;
            flex-direction: column; /* 默认垂直排列，桌面端横向排列 */
        }

        /* 桌面端图片横向排列 */
        @media (min-width: 768px) {
            .recipe-images {
                flex-direction: row;
            }
        }

        .main-image {
            flex: 1; /* 移动端占满宽度 */
            height: clamp(150px, 30vw, 300px); /* 响应式高度 */
            border-radius: 8px;
            overflow: hidden;
        }

        /* 桌面端主图占比调整 */
        @media (min-width: 768px) {
            .main-image {
                flex: 3;
            }
        }

        .recipe-image {
            width: 100%;
            height: 100%;
            object-fit: cover;
        }

        .recipe-title {
            color: hsl(210, 80%, 40%);
            font-size: clamp(1.3rem, 3vw, 1.8rem); /* 响应式字体大小 */
            margin-bottom: 1rem;
            line-height: 1.3;
        }

        /* 食谱信息区域 - 优化移动端换行 */
        .recipe-info {
            display: flex;
            gap: 1rem;
            margin-bottom: 1.5rem;
            flex-wrap: wrap;
            row-gap: 0.8rem; /* 行间距优化 */
        }

        .info-item {
            display: flex;
            align-items: center;
            gap: 0.5rem;
            color: hsl(210, 15%, 35%);
            font-size: clamp(0.9rem, 1.5vw, 1rem); /* 响应式字体大小 */
            flex: 1 1 calc(50% - 0.5rem); /* 移动端每行2个 */
        }

        /* 桌面端每行4个 */
        @media (min-width: 768px) {
            .info-item {
                flex: none;
            }
        }

        .info-icon {
            color: hsl(30, 80%, 50%);
            font-size: 1.1em;
        }

        /* 食材和步骤区域 - 响应式调整 */
        .recipe-ingredients, .recipe-instructions {
            margin-top: 1.5rem;
        }

        .recipe-ingredients h3, .recipe-instructions h3 {
            color: hsl(30, 80%, 50%);
            margin-bottom: 0.8rem;
            font-size: clamp(1.1rem, 2vw, 1.2rem); /* 响应式字体大小 */
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }

        .ingredients-list {
            list-style-position: inside;
            columns: 1; /* 移动端单列 */
            gap: 1rem;
            margin-left: 0.5rem;
            font-size: clamp(0.9rem, 1.5vw, 1rem); /* 响应式字体大小 */
        }

        /* 平板及以上双列 */
        @media (min-width: 640px) {
            .ingredients-list {
                columns: 2;
                gap: 1.5rem;
            }
        }

        .ingredients-list li {
            margin-bottom: 0.3rem;
            padding: 0.3rem;
            border-radius: 4px;
            transition: background-color 0.2s ease;
        }

        .ingredients-list li:hover {
            background-color: hsl(30, 20%, 90%);
        }

        .instructions-list {
            list-style-position: inside;
            margin-left: 0.5rem;
            font-size: clamp(0.9rem, 1.5vw, 1rem); /* 响应式字体大小 */
        }

        .instructions-list li {
            margin-bottom: 0.8rem;
            line-height: 1.7;
            padding: 0.5rem;
            border-radius: 4px;
            cursor: pointer;
            transition: all 0.2s ease;
        }

        .instructions-list li:hover {
            background-color: hsl(30, 20%, 90%);
        }

        .instructions-list li.highlighted {
            background-color: hsl(30, 30%, 85%);
            border-left: 3px solid hsl(30, 80%, 50%);
        }

        /* 游戏区域 - 增强响应式适配 */
        .game-section {
            margin-top: 1.5rem; /* 减少顶部间距 */
            padding: clamp(1rem, 2vw, 1.5rem); /* 响应式内边距 */
            background-color: hsl(30, 10%, 98%);
            border-radius: 8px;
            border: 1px solid hsl(30, 20%, 85%);
            margin-bottom: 1.5rem; /* 减少底部间距 */
        }

        .game-title {
            color: hsl(210, 80%, 40%);
            font-size: clamp(1.1rem, 2vw, 1.2rem); /* 响应式字体大小 */
            margin-bottom: 0.8rem;
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }

        .game-description {
            color: hsl(210, 15%, 35%);
            margin-bottom: 1rem; /* 减少底部间距 */
            line-height: 1.6;
            font-size: clamp(0.9rem, 1.5vw, 1rem); /* 响应式字体大小 */
        }

        /* 排序游戏容器 - 移动端垂直排列 */
        .sort-game {
            display: flex;
            flex-direction: column;
            gap: 1rem;
            margin-bottom: 1rem; /* 减少底部间距 */
        }

        /* 平板及以上横向排列 */
        @media (min-width: 640px) {
            .sort-game {
                flex-direction: row;
                gap: 1.5rem;
            }
        }

        .sort-source, .sort-target {
            flex: 1;
            min-width: 0; /* 解决flex元素最小宽度问题 */
            padding: clamp(0.8rem, 1.5vw, 1rem); /* 响应式内边距 */
            border-radius: 8px;
            /* 触摸设备优化：增加底部内边距，避免拖动时被输入法遮挡 */
            padding-bottom: clamp(1.5rem, 3vw, 2rem);
            min-height: 200px; /* 确保拖放区域有足够高度 */
        }

        .sort-source {
            background-color: hsl(210, 10%, 95%);
            border: 2px dashed hsl(30, 30%, 70%);
        }

        .sort-target {
            background-color: hsl(120, 10%, 95%);
            border: 2px dashed hsl(120, 30%, 70%);
        }

        .sort-title {
            font-size: clamp(0.9rem, 1.5vw, 1rem); /* 响应式字体大小 */
            color: hsl(210, 15%, 35%);
            margin-bottom: 0.8rem;
            text-align: center;
            font-weight: bold;
        }

        /* 步骤卡片 - 响应式调整 + 触摸优化 */
        .step-card {
            padding: clamp(0.8rem, 1.5vw, 1rem); /* 增大触摸区域 */
            margin-bottom: 0.8rem; /* 增加间距，避免误触 */
            background-color: hsl(30, 80%, 50%);
            color: white;
            border-radius: 8px;
            cursor: grab;
            transition: all 0.2s ease;
            user-select: none;
            font-size: clamp(0.9rem, 1.5vw, 1rem); /* 响应式字体大小 */
            /* 触摸优化：增加阴影提升层次感，方便识别可拖动元素 */
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            /* 防止文字换行导致卡片过高 */
            white-space: normal;
            word-wrap: break-word;
            min-height: 60px; /* 增大触摸区域最小高度 */
            display: flex;
            align-items: center;
            position: relative;
            z-index: 1;
        }

        /* 触摸设备上的按压效果 */
        .step-card:active {
            cursor: grabbing;
            transform: scale(0.98);
            box-shadow: 0 1px 2px rgba(0,0,0,0.1);
        }

        .step-card:hover {
            background-color: hsl(30, 80%, 40%);
            transform: translateY(-2px);
            box-shadow: 0 4px 8px rgba(0,0,0,0.15);
        }

        .step-card.dragging {
            opacity: 0.9;
            transform: scale(1.05);
            box-shadow: 0 6px 12px rgba(0,0,0,0.25);
            z-index: 1000; /* 确保拖动时在最上层 */
            pointer-events: none;
        }

        .step-card.correct {
            background-color: hsl(120, 60%, 40%);
            border: 2px solid hsl(120, 80%, 30%);
        }

        .step-card.wrong {
            background-color: hsl(0, 60%, 40%);
            border: 2px solid hsl(0, 80%, 30%);
        }

        /* 游戏控制区域 - 优化移动端布局 */
        .game-controls {
            display: flex;
            flex-direction: column; /* 移动端垂直排列 */
            gap: 1rem;
            margin-top: 1rem;
            align-items: flex-start;
        }

        /* 平板及以上横向排列 */
        @media (min-width: 640px) {
            .game-controls {
                flex-direction: row;
                justify-content: space-between;
                align-items: center;
            }
        }

        .game-status {
            color: hsl(210, 15%, 35%);
            font-weight: 500;
            font-size: clamp(0.9rem, 1.5vw, 1rem); /* 响应式字体大小 */
            width: 100%;
            padding: 0.5rem 0;
        }

        .game-controls > div {
            display: flex;
            gap: 0.8rem; /* 按钮间距 */
            width: 100%;
            justify-content: flex-end;
        }

        /* 平板及以上按钮容器宽度自适应 */
        @media (min-width: 640px) {
            .game-controls > div {
                width: auto;
            }
        }

        .game-btn {
            background-color: hsl(30, 80%, 50%);
            color: white;
            border: none;
            padding: clamp(0.6rem, 1.5vw, 0.8rem) clamp(1.2rem, 3vw, 1.6rem); /* 增大触摸区域 */
            border-radius: 8px;
            cursor: pointer;
            transition: background-color 0.2s ease;
            font-size: clamp(1rem, 2vw, 1.1rem); /* 响应式字体大小 */
            flex: 1; /* 移动端按钮平均分配宽度 */
            min-height: 48px; /* 符合移动端触摸标准 */
            display: flex;
            align-items: center;
            justify-content: center;
        }

        /* 触摸设备按钮按压效果 */
        .game-btn:active {
            transform: scale(0.95);
        }

        /* 平板及以上按钮宽度自适应 */
        @media (min-width: 640px) {
            .game-btn {
                flex: none;
            }
        }

        .game-btn:hover {
            background-color: hsl(30, 80%, 40%);
        }

        .game-btn.check-btn {
            background-color: hsl(210, 80%, 40%);
        }

        .game-btn.check-btn:hover {
            background-color: hsl(210, 80%, 30%);
        }

        /* 翻页控制 - 响应式调整 */
        .pagination {
            display: flex;
            justify-content: center;
            align-items: center;
            gap: clamp(1rem, 2vw, 2rem); /* 响应式间距 */
            margin: clamp(2rem, 4vw, 3rem) auto; /* 响应式边距 */
            padding-bottom: clamp(1.5rem, 3vw, 2rem); /* 响应式底部预留空间 */
        }

        .page-btn {
            background-color: hsl(30, 80%, 50%);
            color: white;
            border: none;
            border-radius: 50%;
            width: clamp(50px, 10vw, 60px); /* 增大触摸区域 */
            height: clamp(50px, 10vw, 60px); /* 增大触摸区域 */
            font-size: clamp(1.5rem, 4vw, 1.8rem); /* 响应式字体大小 */
            cursor: pointer;
            transition: background-color 0.3s ease;
            display: flex;
            justify-content: center;
            align-items: center;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }

        .page-btn:active {
            transform: scale(0.95);
        }

        .page-btn:disabled {
            background-color: hsl(30, 30%, 70%);
            cursor: not-allowed;
        }

        .page-btn:hover:not(:disabled) {
            background-color: hsl(30, 80%, 40%);
            box-shadow: 0 4px 8px rgba(0,0,0,0.15);
        }

        .page-indicator {
            color: hsl(210, 15%, 35%);
            font-size: clamp(1rem, 2vw, 1.2rem); /* 响应式字体大小 */
            font-weight: bold;
        }

        /* 额外响应式优化：超小屏设备（320px以下） */
        @media (max-width: 320px) {
            .info-item {
                flex: 1 1 100%; /* 超小屏每行1个 */
            }

            .ingredients-list {
                columns: 1; /* 确保单列 */
            }

            .game-controls > div {
                flex-direction: column; /* 超小屏按钮垂直排列 */
                gap: 0.5rem;
            }

            .step-card {
                padding: 0.7rem;
                min-height: 55px;
            }
        }

        /* 拖动辅助：触摸时显示拖动提示 */
        @media (max-width: 768px) {
            .sort-title::after {
                content: "（长按拖动）";
                font-size: 0.8rem;
                margin-left: 0.5rem;
                color: hsl(210, 15%, 50%);
            }
        }

        /* 拖放区域高亮 */
        .drop-active {
            background-color: rgba(255, 165, 0, 0.1);
            border-color: hsl(30, 80%, 50%);
        }

        /* 防止拖动时选择文本 */
        * {
            -webkit-touch-callout: none;
            -webkit-user-select: none;
            -khtml-user-select: none;
            -moz-user-select: none;
            -ms-user-select: none;
            user-select: none;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>美味食谱集</h1>
            <p class="subtitle">探索舌尖上的美味，体验烹饪步骤排序乐趣</p>
        </header>

        <!-- 食谱卡片容器 -->
        <div class="recipe-container" id="recipeContainer">
            <!-- 食谱1：番茄炒蛋 -->
            {% for (index, foodItem) in enumerate(info) %}
            <div class="recipe-card active" data-page={% index %}>
                <!-- 多图展示区域 -->
                <div class="recipe-images">
                    <div class="main-image" id="mainImage1">
                        <img src="https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80" class="recipe-image">
                    </div>
                </div>

                <h2 class="recipe-title">{% foodItem.name %}</h2>
                <div class="recipe-info">
                    <div class="info-item">
                        <span class="info-icon">⏱️</span>
                        <span>准备时间：{% foodItem.preTime %}</span>
                    </div>
                    <div class="info-item">
                        <span class="info-icon">🍳</span>
                        <span>烹饪时间：{% foodItem.cookingTime %}</span>
                    </div>
                    <div class="info-item">
                        <span class="info-icon">👨‍🍳</span>
                        <span>难度：{% foodItem.difficulty %}</span>
                    </div>
                    <div class="info-item">
                        <span class="info-icon">🍽️</span>
                        <span>份量：{% foodItem.personPortion %}</span>
                    </div>
                </div>

                <div class="recipe-ingredients">
                    <h3>🥗 食材准备</h3>
                    <ul class="ingredients-list" id="ingredientsList1">
                        {% for ingredient in foodItem.ingredients %}
                        <li>{% ingredient %}</li>
                        {% /for %}
                    </ul>
                </div>

                <div class="recipe-instructions">
                    <h3>👩‍🍳 烹饪步骤</h3>
                    <ol class="instructions-list" onclick="highlightStep(event)">
                        {% for step in foodItem.steps %}
                        <li>{% step %}</li>
                        {% /for %}
                    </ol>
                </div>

                <!-- 烹饪步骤排序小游戏 -->
                <div class="game-section">
                    <h3 class="game-title">👨‍🍳 烹饪步骤排序游戏</h3>
                    <p class="game-description">将左侧打乱的烹饪步骤拖拽到右侧区域，按照正确的做菜顺序排列，看看你是否掌握了番茄炒蛋的正确做法！（手机端长按拖动，电脑端鼠标拖拽）</p>

                    <div class="sort-game" id="sortGame1">
                        <div class="sort-source" id="source1">
                            <div class="sort-title">待排序步骤</div>
                            <!-- 步骤卡片由JS生成 -->
                        </div>
                        <div class="sort-target" id="target1" ondrop="drop(event, 0)" ondragover="allowDrop(event)">
                            <div class="sort-title">正确顺序</div>
                        </div>
                    </div>

                    <div class="game-controls">
                        <span class="game-status" id="gameStatus1">点击开始游戏开始排序</span>
                        <div>
                            <button class="game-btn" onclick="initSortGame(0)">开始游戏</button>
                            <button class="game-btn check-btn" onclick="checkSortResult(0)">检查答案</button>
                        </div>
                    </div>
                </div>
            </div>
            {% /for %}
        </div>

        <!-- 翻页控制 -->
        <div class="pagination">
            <button class="page-btn" id="prevBtn" disabled>←</button>
            <div class="page-indicator" id="pageIndicator">1 / 3</div>
            <button class="page-btn" id="nextBtn">→</button>
        </div>
    </div>

    <script>
        // 基础翻页功能（修改currentPage从0开始）
        const prevBtn = document.getElementById('prevBtn');
        const nextBtn = document.getElementById('nextBtn');
        const pageIndicator = document.getElementById('pageIndicator');
        const recipeCards = document.querySelectorAll('.recipe-card');
        const totalPages = recipeCards.length; // 总页数保持不变（3页）
        let currentPage = 0; // 从0开始计数

        function updatePagination() {
            // 页码显示转换为用户友好的1-based（1/3 而不是 0/2）
            pageIndicator.textContent = `\${currentPage + 1} / \${totalPages}`;

            // 禁用/启用按钮逻辑调整
            prevBtn.disabled = currentPage === 0; // 第一页（index 0）时禁用上一页
            nextBtn.disabled = currentPage === totalPages - 1; // 最后一页（index totalPages-1）时禁用下一页

            // 更新卡片显示状态
            recipeCards.forEach(card => {
                const page = parseInt(card.dataset.page); // 现在data-page从0开始
                if (page === currentPage) {
                    card.classList.add('active');
                    card.classList.remove('prev', 'next');
                } else {
                    card.classList.remove('active');
                    if (page < currentPage) {
                        card.classList.add('prev');
                    } else {
                        card.classList.add('next');
                    }
                }
            });

            // 翻页后自动滚动到页面顶部
            window.scrollTo({
                top: 0,
                behavior: 'smooth'
            });
        }

        // 下一页逻辑调整
        nextBtn.addEventListener('click', () => {
            if (currentPage < totalPages - 1) { // 最大index是totalPages-1
                currentPage++;
                updatePagination();
            }
        });

        // 上一页逻辑调整
        prevBtn.addEventListener('click', () => {
            if (currentPage > 0) { // 最小index是0
                currentPage--;
                updatePagination();
            }
        });

        // 键盘导航逻辑调整
        document.addEventListener('keydown', (e) => {
            if (e.key === 'ArrowRight' && currentPage < totalPages - 1) nextBtn.click();
            else if (e.key === 'ArrowLeft' && currentPage > 0) prevBtn.click();
        });

        // 切换主图功能（保持不变）
        function changeMainImage(mainImageId, newSrc) {
            const mainImage = document.getElementById(mainImageId);
            const img = mainImage.querySelector('img');
            img.src = newSrc;
        }

        // 步骤高亮功能（保持不变）
        function highlightStep(event) {
            if (event.target.tagName === 'LI') {
                const allSteps = event.currentTarget.querySelectorAll('li');
                allSteps.forEach(step => step.classList.remove('highlighted'));
                event.target.classList.add('highlighted');
            }
        }

        // 烹饪步骤排序游戏核心功能 - 优化触摸支持
        let correctSteps = {};
        let draggedElement = null; // 存储当前拖动的元素
        let touchStartX = 0; // 触摸起始X坐标
        let touchStartY = 0; // 触摸起始Y坐标
        let isDragging = false; // 是否正在拖动
        const dragThreshold = 8; // 减小拖动触发阈值
        let lastTouchTime = 0; // 用于防止快速连续触摸

        // 允许拖放（鼠标和触摸）
        function allowDrop(ev) {
            ev.preventDefault();
            // 触摸设备上添加拖放区域高亮
            if (ev.type === 'touchmove' && isDragging) {
                // 找到实际的拖放容器
                let target = ev.target;
                while (target && !target.classList.contains('sort-source') && !target.classList.contains('sort-target') && !target.classList.contains('step-card') && !target.classList.contains('sort-title')) {
                    target = target.parentNode;
                }
                if (target) {
                    // 高亮容器而非子元素
                    if (target.classList.contains('step-card')) {
                        target.parentNode.classList.add('drop-active');
                    } else if (target.classList.contains('sort-title')) {
                        target.parentNode.classList.add('drop-active');
                    } else {
                        target.classList.add('drop-active');
                    }
                }
            }
        }

        // 鼠标拖动开始
        function drag(ev) {
            ev.dataTransfer.setData("text", ev.target.id);
            ev.target.classList.add('dragging');
            draggedElement = ev.target;
        }

        // 鼠标放下元素
        function drop(ev, recipeNum) {
            ev.preventDefault();

            // 移除所有拖放区域高亮
            document.querySelectorAll('.drop-active').forEach(el => el.classList.remove('drop-active'));

            if (draggedElement) {
                // 鼠标拖放逻辑
                if (ev.dataTransfer) {
                    const data = ev.dataTransfer.getData("text");
                    draggedElement = document.getElementById(data);
                }

                draggedElement.classList.remove('dragging');

                // 确定放置位置
                let dropContainer = null;
                let insertBeforeElement = null;

                if (ev.target.classList.contains('sort-title')) {
                    dropContainer = ev.target.parentNode;
                } else if (ev.target.id === `target\${recipeNum + 1}` || ev.target.id === `source\${recipeNum + 1}`) {
                    // 注意：target和source的ID还是用1,2,3命名的，需要+1转换
                    dropContainer = ev.target;
                } else if (ev.target.classList.contains('step-card')) {
                    dropContainer = ev.target.parentNode;
                    insertBeforeElement = ev.target;
                } else {
                    // 查找最近的容器
                    let target = ev.target;
                    while (target && !target.classList.contains('sort-source') && !target.classList.contains('sort-target')) {
                        target = target.parentNode;
                    }
                    dropContainer = target || draggedElement.parentNode;
                }

                // 执行放置
                if (dropContainer) {
                    if (insertBeforeElement && dropContainer === insertBeforeElement.parentNode) {
                        insertBeforeElement.before(draggedElement);
                    } else {
                        dropContainer.appendChild(draggedElement);
                    }
                }

                // 更新状态
                const targetContainer = document.getElementById(`target\${recipeNum + 1}`); // ID转换
                document.getElementById(`gameStatus\${recipeNum + 1}`).textContent =
                    `已放置\${targetContainer.querySelectorAll('.step-card').length}个步骤，继续排序...`;

                // 重置拖动状态
                draggedElement = null;
                isDragging = false;
            }
        }

        // 触摸事件处理 - 开始触摸（优化长按检测）
        function handleTouchStart(ev, element, recipeNum) {
            // 防止快速连续触摸
            const currentTime = new Date().getTime();
            if (currentTime - lastTouchTime < 200) {
                lastTouchTime = currentTime;
                return;
            }
            lastTouchTime = currentTime;

            const touch = ev.touches[0];
            touchStartX = touch.clientX;
            touchStartY = touch.clientY;
            draggedElement = element;
            isDragging = false;

            // 记录初始位置，用于后续计算
            element.dataset.initialParent = element.parentNode.id;

            // 长按延迟触发（缩短延迟时间）
            setTimeout(() => {
                // 检查是否仍在同一元素上触摸且未移动
                if (draggedElement === element) {
                    const currentTouch = document.elementFromPoint(touch.clientX, touch.clientY);
                    if (currentTouch === element || currentTouch === element.firstChild) {
                        element.classList.add('dragging');
                        isDragging = true;
                        // 禁止页面滚动和缩放
                        document.body.style.overflow = 'hidden';
                        document.body.style.touchAction = 'none';
                    }
                }
            }, 120); // 缩短长按延迟到120ms
        }

        // 触摸移动（优化定位和性能）
        function handleTouchMove(ev, recipeNum) {
            if (!isDragging || !draggedElement) return;

            ev.preventDefault(); // 阻止页面滚动和缩放
            const touch = ev.touches[0];
            const dx = touch.clientX - touchStartX;
            const dy = touch.clientY - touchStartY;

            // 超过阈值开始拖动
            if (Math.abs(dx) > dragThreshold || Math.abs(dy) > dragThreshold) {
                // 计算拖动元素的位置（优化定位精度）
                const rect = draggedElement.getBoundingClientRect();
                const offsetX = touch.clientX - rect.width / 2;
                const offsetY = touch.clientY - rect.height / 2;

                // 使用fixed定位确保拖动流畅
                draggedElement.style.position = 'fixed';
                draggedElement.style.left = `\${offsetX}px`;
                draggedElement.style.top = `\${offsetY}px`;
                draggedElement.style.opacity = '0.9';

                // 移除之前的高亮
                document.querySelectorAll('.drop-active').forEach(el => el.classList.remove('drop-active'));

                // 查找当前触摸位置的拖放容器
                const targetElement = document.elementFromPoint(touch.clientX, touch.clientY);
                if (targetElement) {
                    let dropContainer = null;
                    if (targetElement.id === `target\${recipeNum + 1}` || targetElement.id === `source\${recipeNum + 1}`) {
                        dropContainer = targetElement;
                    } else if (targetElement.classList.contains('sort-title')) {
                        dropContainer = targetElement.parentNode;
                    } else if (targetElement.classList.contains('step-card')) {
                        dropContainer = targetElement.parentNode;
                    } else {
                        // 向上查找容器
                        let parent = targetElement.parentNode;
                        while (parent && !parent.classList.contains('sort-source') && !parent.classList.contains('sort-target')) {
                            parent = parent.parentNode;
                        }
                        dropContainer = parent;
                    }

                    // 高亮找到的容器
                    if (dropContainer) {
                        dropContainer.classList.add('drop-active');
                    }
                }
            }
        }

        // 触摸结束（优化放置逻辑）
        function handleTouchEnd(ev, recipeNum) {
            // 记录触摸结束时间
            lastTouchTime = new Date().getTime();

            if (!isDragging || !draggedElement) {
                // 未触发拖动，重置
                if (draggedElement) {
                    draggedElement.classList.remove('dragging');
                }
                draggedElement = null;
                document.body.style.overflow = '';
                document.body.style.touchAction = '';
                return;
            }

            ev.preventDefault();

            // 恢复元素样式
            draggedElement.style.position = '';
            draggedElement.style.left = '';
            draggedElement.style.top = '';
            draggedElement.style.opacity = '';
            draggedElement.classList.remove('dragging');

            // 移除所有拖放区域高亮
            document.querySelectorAll('.drop-active').forEach(el => el.classList.remove('drop-active'));

            // 查找最终触摸位置的元素
            const touch = ev.changedTouches[0];
            let targetElement = null;

            try {
                // 尝试获取触摸位置的元素（可能会抛出异常）
                targetElement = document.elementFromPoint(touch.clientX, touch.clientY);
            } catch (e) {
                targetElement = null;
            }

            // 确定放置容器和位置
            let dropContainer = null;
            let insertBeforeElement = null;

            if (targetElement) {
                // 检查是否点击在步骤卡片上
                if (targetElement.classList.contains('step-card')) {
                    dropContainer = targetElement.parentNode;
                    insertBeforeElement = targetElement;
                }
                // 检查是否点击在标题上
                else if (targetElement.classList.contains('sort-title')) {
                    dropContainer = targetElement.parentNode;
                }
                // 检查是否点击在容器上
                else if (targetElement.classList.contains('sort-source') || targetElement.classList.contains('sort-target')) {
                    dropContainer = targetElement;
                }
                // 向上查找容器
                else {
                    let parent = targetElement.parentNode;
                    while (parent && !parent.classList.contains('sort-source') && !parent.classList.contains('sort-target')) {
                        parent = parent.parentNode;
                    }
                    dropContainer = parent;
                }
            }

            // 如果没有找到容器，放回原位置
            if (!dropContainer) {
                const initialParentId = draggedElement.dataset.initialParent;
                dropContainer = document.getElementById(initialParentId) || draggedElement.parentNode;
            }

            // 执行放置
            if (dropContainer) {
                if (insertBeforeElement && dropContainer === insertBeforeElement.parentNode) {
                    // 插入到目标卡片前面
                    insertBeforeElement.before(draggedElement);
                } else {
                    // 添加到容器末尾
                    dropContainer.appendChild(draggedElement);
                }
            }

            // 更新状态
            const targetContainer = document.getElementById(`target\${recipeNum + 1}`); // ID转换
            const stepCount = targetContainer.querySelectorAll('.step-card').length;
            document.getElementById(`gameStatus\${recipeNum + 1}`).textContent =
                `已放置\${stepCount}个步骤，继续排序...`;

            // 清理
            delete draggedElement.dataset.initialParent;
            draggedElement = null;
            isDragging = false;
            document.body.style.overflow = ''; // 恢复页面滚动
            document.body.style.touchAction = ''; // 恢复触摸行为
        }

        // 触摸取消处理（完善异常情况）
        function handleTouchCancel(element) {
            if (element.classList.contains('dragging')) {
                element.classList.remove('dragging');
            }
            // 移除所有拖放区域高亮
            document.querySelectorAll('.drop-active').forEach(el => el.classList.remove('drop-active'));
            draggedElement = null;
            isDragging = false;
            document.body.style.overflow = '';
            document.body.style.touchAction = '';
        }

        // 初始化排序游戏（优化触摸事件绑定）
        function initSortGame(recipeNum) {
            const sourceContainer = document.getElementById(`source\${recipeNum + 1}`); // ID转换
            const targetContainer = document.getElementById(`target\${recipeNum + 1}`); // ID转换
            const gameStatus = document.getElementById(`gameStatus\${recipeNum + 1}`); // ID转换

            // 清空容器
            sourceContainer.innerHTML = `<div class="sort-title">待排序步骤</div>`;
            targetContainer.innerHTML = `<div class="sort-title">正确顺序</div>`;

            // 获取正确步骤（根据recipeNum获取对应的食谱卡片）
            const recipeCard = document.querySelector(`.recipe-card[data-page="\${recipeNum}"]`);
            const instructionsList = recipeCard.querySelectorAll('.instructions-list li');
            const steps = Array.from(instructionsList).map(li => li.textContent);
            correctSteps[recipeNum] = [...steps];

            // 改进的打乱算法，避免过于接近原顺序
            const shuffledSteps = [...steps];
            for (let i = shuffledSteps.length - 1; i > 0; i--) {
                const j = Math.floor(Math.random() * (i + 1));
                [shuffledSteps[i], shuffledSteps[j]] = [shuffledSteps[j], shuffledSteps[i]];
            }
            // 确保至少有一个元素不在原位置
            let isShuffled = false;
            for (let i = 0; i < steps.length; i++) {
                if (shuffledSteps[i] !== steps[i]) {
                    isShuffled = true;
                    break;
                }
            }
            if (!isShuffled && steps.length > 1) {
                [shuffledSteps[0], shuffledSteps[1]] = [shuffledSteps[1], shuffledSteps[0]];
            }

            // 创建步骤卡片（优化触摸事件绑定）
            shuffledSteps.forEach((step, index) => {
                const card = document.createElement('div');
                card.className = 'step-card';
                card.id = `step-\${recipeNum}-\${index}`;
                card.draggable = true; // 支持鼠标拖放
                card.textContent = step;
                card.dataset.stepIndex = index; // 存储步骤索引

                // 添加鼠标事件
                card.addEventListener('dragstart', drag);
                card.addEventListener('dragend', () => {
                    if (card.classList.contains('dragging')) {
                        card.classList.remove('dragging');
                    }
                });

                // 添加触摸事件（优化绑定）
                card.addEventListener('touchstart', (ev) => {
                    // 只处理单指触摸
                    if (ev.touches.length === 1) {
                        handleTouchStart(ev, card, recipeNum);
                    }
                }, { passive: false });

                card.addEventListener('touchmove', (ev) => {
                    if (ev.touches.length === 1) {
                        handleTouchMove(ev, recipeNum);
                    }
                }, { passive: false });

                card.addEventListener('touchend', (ev) => {
                    if (ev.changedTouches.length === 1) {
                        handleTouchEnd(ev, recipeNum);
                    }
                }, { passive: false });

                card.addEventListener('touchcancel', () => {
                    handleTouchCancel(card);
                });

                sourceContainer.appendChild(card);
            });

            // 添加拖放区域的事件
            [sourceContainer, targetContainer].forEach(container => {
                // 鼠标事件
                container.addEventListener('dragover', allowDrop);
                container.addEventListener('dragleave', (ev) => {
                    ev.target.classList.remove('drop-active');
                });

                // 触摸事件
                container.addEventListener('touchmove', allowDrop, { passive: false });
                container.addEventListener('touchend', (ev) => {
                    if (isDragging) {
                        drop(ev, recipeNum);
                    }
                }, { passive: false });

                // 防止点击事件冒泡
                container.addEventListener('click', (ev) => {
                    ev.stopPropagation();
                });
            });

            // 更新游戏状态
            gameStatus.textContent = `游戏开始！请将左侧\${steps.length}个步骤拖拽到右侧正确位置`;
            gameStatus.style.color = 'hsl(210, 15%, 35%)';
        }

        // 检查排序结果（保持原有逻辑，调整ID转换）
        function checkSortResult(recipeNum) {
            const targetContainer = document.getElementById(`target\${recipeNum + 1}`); // ID转换
            const gameStatus = document.getElementById(`gameStatus\${recipeNum + 1}`); // ID转换
            const stepCards = targetContainer.querySelectorAll('.step-card');

            if (stepCards.length !== correctSteps[recipeNum].length) {
                gameStatus.textContent = `❌ 还有\${correctSteps[recipeNum].length - stepCards.length}个步骤未排序，请继续完成！`;
                gameStatus.style.color = 'hsl(0, 60%, 40%)';
                return;
            }

            const currentSteps = Array.from(stepCards).map(card => card.textContent);
            let isCorrect = true;
            let wrongIndices = [];

            // 验证顺序
            currentSteps.forEach((step, index) => {
                if (step !== correctSteps[recipeNum][index]) {
                    isCorrect = false;
                    wrongIndices.push(index);
                }
            });

            // 标记结果
            stepCards.forEach((card, index) => {
                card.classList.remove('correct', 'wrong');
                if (wrongIndices.includes(index)) {
                    card.classList.add('wrong');
                } else {
                    card.classList.add('correct');
                }
            });

            // 更新状态
            if (isCorrect) {
                gameStatus.textContent = `🎉 恭喜！步骤排序完全正确，你掌握了正确的做菜顺序！`;
                gameStatus.style.color = 'hsl(120, 60%, 40%)';
            } else {
                gameStatus.textContent = `❌ 有\${wrongIndices.length}个步骤顺序错误（红色标记），请重新调整！`;
                gameStatus.style.color = 'hsl(0, 60%, 40%)';
            }
        }

        // 全局事件：点击非拖放区域取消拖动
        document.addEventListener('click', (ev) => {
            if (draggedElement && !ev.target.classList.contains('step-card') && !ev.target.classList.contains('sort-title') && !ev.target.id.includes('target') && !ev.target.id.includes('source')) {
                draggedElement.classList.remove('dragging');
                draggedElement = null;
                isDragging = false;
                document.body.style.overflow = '';
                document.body.style.touchAction = '';
                document.querySelectorAll('.drop-active').forEach(el => el.classList.remove('drop-active'));
            }
        });

        // 全局触摸事件：防止页面滚动干扰
        document.addEventListener('touchmove', (ev) => {
            if (isDragging) {
                ev.preventDefault();
            }
        }, { passive: false });

        // 初始化（保持不变）
        updatePagination();

        // 修复iOS上的触摸问题
        if (/iPhone|iPad|iPod/i.test(navigator.userAgent)) {
            // 禁用iOS的双击缩放
            document.addEventListener('dblclick', (ev) => {
                ev.preventDefault();
            });

            // 调整触摸行为
            document.body.style.touchAction = 'manipulation';
        }
    </script>
</body>
</html>
    '''
}
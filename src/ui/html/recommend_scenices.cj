/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.ui.html

import magic.dsl.*
import magic.prelude.*
import std.collection.enumerate

@jsonable
public class Position {
	@field["名称"]
    let name: String
    @field["距离，单位是公里0，如5.5km"]
    let distance: Float64
    @field["票价"]
    let price: Int64
    @field["开放时间"]
    let openTime: String
    @field["评分，5分满分"]
    let rating: Float64
    @field["评分人数"]
    let reviews: Int64
    @field["景点类型（自然景观，历史古迹，主题公园，城市地标，文化广场，美食街区）"]
    let types: String
    @field["描述，详细介绍，30字以上"]
    let description: String
    @field["图片链接"]
    let img: String
    @field["标签"]
    let tags: Array<String>
}

public func formatStringArray(arr: Array<String>): String {
  if(arr.size == 0) {
    return "[]"
  }

  var res = '['
  for (i in 0..arr.size) {
    res = res + "\"" + arr[i] + "\""
    if (i != arr.size - 1) {
      res = res + ' ,'
    }
  }
  res = res + ']'
  return res
}

@ui[
    description: '''
    功能类型：地点推荐 UI,
    使用场景：展示各类生活场景地点信息（含名称 / 类型 / 评分 / 地址 / 人均 / 营业时间），如旅游景点推荐、美食店推荐、民宿酒店推荐、休闲娱乐场所推荐,
    交互特性：筛选过滤型，支持点击查看地点详情；支持按评分 / 距离筛选排序,
    风格属性：复杂型，适合与map UI进行组合
    ''',
    kind: "display"
]
public func recommendScenices(info: Array<Position>) {
    '''
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>附近景点探索</title>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
  <style>
    /* 基础样式重置 */
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    }

    body {
      background-color: hsl(210, 30%, 95%);
      color: hsl(210, 20%, 20%);
      line-height: 1.6;
    }

    .container {
      max-width: 1200px;
      margin: 0 auto;
      padding: 20px;
    }

    /* 头部样式 */
    header {
      text-align: center;
      margin-bottom: 30px;
      padding: 20px 0;
      border-bottom: 1px solid hsl(210, 20%, 85%);
    }

    h1 {
      color: hsl(210, 70%, 50%);
      margin-bottom: 10px;
      font-size: 2.2rem;
    }

    .header-subtitle {
      color: hsl(210, 20%, 50%);
      font-size: 1.1rem;
    }

    /* 筛选区域样式 */
    .filters {
      background-color: hsl(0, 0%, 100%);
      border-radius: 12px;
      padding: 20px;
      margin-bottom: 30px;
      box-shadow: 0 4px 12px hsl(210, 20%, 85%);
      display: flex;
      flex-wrap: wrap;
      gap: 20px;
      align-items: center;
    }

    .filter-group {
      flex: 1;
      min-width: 200px;
    }

    .filter-label {
      display: block;
      margin-bottom: 8px;
      font-weight: 600;
      color: hsl(210, 20%, 30%);
    }

    .filter-select, .filter-input {
      width: 100%;
      padding: 12px 15px;
      border: 1px solid hsl(210, 20%, 80%);
      border-radius: 8px;
      background-color: hsl(0, 0%, 100%);
      color: hsl(210, 20%, 20%);
      font-size: 1rem;
      transition: all 0.3s ease;
    }

    .filter-select:focus, .filter-input:focus {
      outline: none;
      border-color: hsl(210, 70%, 50%);
      box-shadow: 0 0 0 3px hsl(210, 70%, 80%);
    }

    .search-btn {
      background-color: hsl(210, 70%, 50%);
      color: white;
      border: none;
      border-radius: 8px;
      padding: 12px 24px;
      font-size: 1rem;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.3s ease;
      margin-top: 24px;
    }

    .search-btn:hover {
      background-color: hsl(210, 70%, 40%);
      transform: translateY(-2px);
      box-shadow: 0 4px 8px hsl(210, 70%, 30%, 0.2);
    }

    /* 景点列表样式 */
    .attractions {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
      gap: 24px;
      margin-bottom: 40px;
    }

    .attraction-card {
      background-color: white;
      border-radius: 12px;
      overflow: hidden;
      box-shadow: 0 4px 12px hsl(210, 20%, 85%);
      transition: all 0.3s ease;
      cursor: pointer;
    }

    .attraction-card:hover {
      transform: translateY(-5px);
      box-shadow: 0 8px 20px hsl(210, 20%, 70%);
    }

    .card-img {
      width: 100%;
      height: 200px;
      object-fit: cover;
    }

    .card-content {
      padding: 20px;
    }

    .card-title {
      font-size: 1.3rem;
      color: hsl(210, 20%, 20%);
      margin-bottom: 8px;
    }

    .card-meta {
      display: flex;
      gap: 15px;
      margin-bottom: 12px;
      font-size: 0.9rem;
      color: hsl(210, 20%, 50%);
    }

    .meta-item {
      display: flex;
      align-items: center;
      gap: 5px;
    }

    .card-rating {
      display: flex;
      align-items: center;
      gap: 5px;
      margin-bottom: 12px;
    }

    .rating-stars {
      color: hsl(45, 100%, 50%);
    }

    .rating-score {
      font-weight: 600;
      color: hsl(210, 20%, 30%);
    }

    .card-desc {
      color: hsl(210, 20%, 40%);
      font-size: 0.95rem;
      line-height: 1.5;
      margin-bottom: 15px;
      display: -webkit-box;
      -webkit-line-clamp: 3;
      -webkit-box-orient: vertical;
      overflow: hidden;
    }

    .card-tags {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
    }

    .tag {
      background-color: hsl(210, 70%, 90%);
      color: hsl(210, 70%, 50%);
      padding: 4px 10px;
      border-radius: 20px;
      font-size: 0.8rem;
      font-weight: 500;
    }

    /* 模态框样式 */
    .modal-overlay {
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background-color: hsl(0, 0%, 0%, 0.5);
      display: flex;
      align-items: center;
      justify-content: center;
      z-index: 1000;
      opacity: 0;
      visibility: hidden;
      transition: all 0.3s ease;
    }

    .modal-overlay.active {
      opacity: 1;
      visibility: visible;
    }

    .modal {
      background-color: white;
      border-radius: 12px;
      width: 90%;
      max-width: 800px;
      max-height: 90vh;
      overflow-y: auto;
      box-shadow: 0 10px 30px hsl(0, 0%, 0%, 0.3);
      transform: translateY(20px);
      transition: all 0.3s ease;
    }

    .modal-overlay.active .modal {
      transform: translateY(0);
    }

    .modal-header {
      padding: 20px;
      border-bottom: 1px solid hsl(210, 20%, 85%);
      display: flex;
      justify-content: space-between;
      align-items: center;
    }

    .modal-title {
      font-size: 1.8rem;
      color: hsl(210, 20%, 20%);
    }

    .modal-close {
      background: none;
      border: none;
      font-size: 1.5rem;
      color: hsl(210, 20%, 50%);
      cursor: pointer;
      transition: all 0.2s ease;
    }

    .modal-close:hover {
      color: hsl(0, 70%, 50%);
    }

    .modal-body {
      padding: 20px;
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 20px;
    }

    @media (max-width: 768px) {
      .modal-body {
        grid-template-columns: 1fr;
      }
    }

    .modal-img {
      width: 100%;
      height: 300px;
      object-fit: cover;
      border-radius: 8px;
    }

    .modal-content {
      display: flex;
      flex-direction: column;
      gap: 15px;
    }

    .modal-meta {
      display: flex;
      flex-wrap: wrap;
      gap: 20px;
      margin-bottom: 10px;
      font-size: 1rem;
    }

    .modal-rating {
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 1.2rem;
    }

    .modal-desc {
      line-height: 1.8;
      color: hsl(210, 20%, 40%);
    }

    .modal-actions {
      display: flex;
      gap: 15px;
      margin-top: 20px;
    }

    .modal-btn {
      padding: 10px 20px;
      border-radius: 8px;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.3s ease;
      border: none;
    }

    .btn-primary {
      background-color: hsl(210, 70%, 50%);
      color: white;
    }

    .btn-primary:hover {
      background-color: hsl(210, 70%, 40%);
    }

    .btn-secondary {
      background-color: hsl(210, 20%, 85%);
      color: hsl(210, 20%, 30%);
    }

    .btn-secondary:hover {
      background-color: hsl(210, 20%, 75%);
    }

    /* 无结果样式 */
    .no-results {
      text-align: center;
      padding: 60px 20px;
      color: hsl(210, 20%, 50%);
    }

    .no-results i {
      font-size: 3rem;
      margin-bottom: 20px;
      color: hsl(210, 20%, 70%);
    }

    .no-results h3 {
      font-size: 1.5rem;
      margin-bottom: 10px;
      color: hsl(210, 20%, 30%);
    }

    /* 加载动画 */
    .loader {
      display: none;
      justify-content: center;
      padding: 40px;
    }

    .loader.active {
      display: flex;
    }

    .spinner {
      width: 50px;
      height: 50px;
      border: 5px solid hsl(210, 20%, 85%);
      border-top: 5px solid hsl(210, 70%, 50%);
      border-radius: 50%;
      animation: spin 1s linear infinite;
    }

    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }

    /* 响应式调整 */
    @media (max-width: 768px) {
      .attractions {
        grid-template-columns: 1fr;
      }

      .filters {
        flex-direction: column;
        align-items: stretch;
      }

      .search-btn {
        margin-top: 10px;
      }

      h1 {
        font-size: 1.8rem;
      }

      .card-img {
        height: 180px;
      }
    }

    @media (max-width: 480px) {
      .container {
        padding: 15px;
      }

      .card-content {
        padding: 15px;
      }

      .modal-body {
        padding: 15px;
      }

      .modal-title {
        font-size: 1.5rem;
      }
    }
  </style>
</head>
<body>
  <div class="container">
    <!-- 筛选区域 -->
    <section class="filters">
      <div class="filter-group">
        <label class="filter-label" for="distance">距离范围</label>
        <select id="distance" class="filter-select">
          <option value="5">5公里以内</option>
          <option value="10" selected>10公里以内</option>
          <option value="20">20公里以内</option>
          <option value="50">50公里以内</option>
          <option value="100">100公里以内</option>
        </select>
      </div>

      <div class="filter-group">
        <label class="filter-label" for="rating">最低评分</label>
        <select id="rating" class="filter-select">
          <option value="0" selected>不限</option>
          <option value="3">3.0分及以上</option>
          <option value="3.5">3.5分及以上</option>
          <option value="4">4.0分及以上</option>
          <option value="4.5">4.5分及以上</option>
        </select>
      </div>

      <div class="filter-group">
        <label class="filter-label" for="type">景点类型</label>
        <select id="type" class="filter-select">
          <option value="all" selected>全部类型</option>
          <option value="自然景观">自然景观</option>
          <option value="历史古迹">历史古迹</option>
          <option value="主题公园">主题公园</option>
          <option value="城市地标">城市地标</option>
          <option value="文化场馆">文化场馆</option>
          <option value="美食街区">美食街区</option>
        </select>
      </div>

      <div class="filter-group">
        <label class="filter-label" for="price">价格范围</label>
        <select id="price" class="filter-select">
          <option value="all" selected>不限</option>
          <option value="free">免费</option>
          <option value="cheap">经济型 (≤100元)</option>
          <option value="mid">中端型 (100-300元)</option>
          <option value="high">高端型 (>300元)</option>
        </select>
      </div>

      <button class="search-btn" id="filter-btn">
        <i class="fa fa-search"></i> 筛选景点
      </button>
    </section>

    <!-- 加载动画 -->
    <div class="loader" id="loader">
      <div class="spinner"></div>
    </div>

    <!-- 无结果提示 -->
    <div class="no-results" id="no-results" style="display: none;">
      <i class="fa fa-map-marker"></i>
      <h3>未找到符合条件的景点</h3>
      <p>尝试调整筛选条件，探索更多可能性</p>
    </div>

    <!-- 景点列表 -->
    <section class="attractions" id="attractions-list">
      <!-- 景点卡片将通过JS动态生成 -->
    </section>
  </div>

  <!-- 景点详情模态框 -->
  <div class="modal-overlay" id="modal">
    <div class="modal">
      <div class="modal-header">
        <h2 class="modal-title" id="modal-title"></h2>
        <button class="modal-close" id="modal-close">
          <i class="fa fa-times"></i>
        </button>
      </div>
      <div class="modal-body">
        <img src="" alt="" class="modal-img" id="modal-img">
        <div class="modal-content">
          <div class="modal-rating" id="modal-rating">
            <div class="rating-stars">
              <i class="fa fa-star"></i>
              <i class="fa fa-star"></i>
              <i class="fa fa-star"></i>
              <i class="fa fa-star"></i>
              <i class="fa fa-star-half-o"></i>
            </div>
            <span class="rating-score">4.5</span>
            <span>(1200条评价)</span>
          </div>
          <div class="modal-meta" id="modal-meta">
            <div class="meta-item">
              <i class="fa fa-map-marker"></i>
              <span>距离 3.2 公里</span>
            </div>
            <div class="meta-item">
              <i class="fa fa-ticket"></i>
              <span>门票: ¥80/人</span>
            </div>
            <div class="meta-item">
              <i class="fa fa-clock-o"></i>
              <span>开放时间: 8:00-18:00</span>
            </div>
          </div>
          <p class="modal-desc" id="modal-desc"></p>
          <div class="modal-actions">
          </div>
        </div>
      </div>
    </div>
  </div>

  <script>
    // 景点数据
    const attractionsData = [
      {% for (index, positionItem) in enumerate(info) %}
      {
        id: {% index %},
        name: '{% positionItem.name %}',
        image: '{% positionItem.img %}',
        distance: {% positionItem.distance %},
        rating: {% positionItem.rating %},
        reviews: {% positionItem.reviews %},
        type: '{% positionItem.types %}',
        price: {% positionItem.price %},
        openTime: '{% positionItem.openTime %}',
        tags: {% formatStringArray(positionItem.tags) %},
        description: '{% positionItem.description %}',
      },
      {% /for %}
    ];

    // DOM元素
    const attractionsList = document.getElementById('attractions-list');
    const filterBtn = document.getElementById('filter-btn');
    const loader = document.getElementById('loader');
    const noResults = document.getElementById('no-results');
    const modal = document.getElementById('modal');
    const modalClose = document.getElementById('modal-close');
    const modalTitle = document.getElementById('modal-title');
    const modalImg = document.getElementById('modal-img');
    const modalRating = document.getElementById('modal-rating');
    const modalMeta = document.getElementById('modal-meta');
    const modalDesc = document.getElementById('modal-desc');

    // 初始化页面：渲染所有景点
    document.addEventListener('DOMContentLoaded', () => {
      renderAttractions(attractionsData);
    });

    // 渲染景点列表
    function renderAttractions(attractions) {
      attractionsList.innerHTML = '';

      if (attractions.length === 0) {
        noResults.style.display = 'block';
        return;
      }

      noResults.style.display = 'none';

      attractions.forEach(attraction => {
        const card = document.createElement('div');
        card.className = 'attraction-card';
        card.dataset.id = attraction.id;

        // 生成星级评分HTML
        const starsHtml = generateStars(attraction.rating);

        // 价格显示处理
        const priceDisplay = attraction.price === 0 ? '免费' : `¥\${attraction.price}/人`;

        card.innerHTML = `
          <img src="\${attraction.image}" alt="\${attraction.name}" class="card-img">
          <div class="card-content">
            <h3 class="card-title">\${attraction.name}</h3>
            <div class="card-meta">
              <div class="meta-item">
                <i class="fa fa-map-marker"></i>
                <span>\${attraction.distance} 公里</span>
              </div>
              <div class="meta-item">
                <i class="fa fa-ticket"></i>
                <span>\${priceDisplay}</span>
              </div>
              <div class="meta-item">
                <i class="fa fa-clock-o"></i>
                <span>\${attraction.openTime}</span>
              </div>
            </div>
            <div class="card-rating">
              <div class="rating-stars">\${starsHtml}</div>
              <span class="rating-score">\${attraction.rating}</span>
              <span>(\${attraction.reviews}条)</span>
            </div>
            <p class="card-desc">\${attraction.description}</p>
            <div class="card-tags">
              \${attraction.tags.map(tag => `<span class="tag">\${tag}</span>`).join('')}
            </div>
          </div>
        `;

        // 点击卡片打开模态框
        card.addEventListener('click', () => {
          openModal(attraction);
        });

        attractionsList.appendChild(card);
      });
    }

    // 生成星级评分HTML
    function generateStars(rating) {
      const fullStars = Math.floor(rating);
      const hasHalfStar = rating % 1 >= 0.5;
      const emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);

      let starsHtml = '';

      // 满星
      for (let i = 0; i < fullStars; i++) {
        starsHtml += '<i class="fa fa-star"></i>';
      }

      // 半星
      if (hasHalfStar) {
        starsHtml += '<i class="fa fa-star-half-o"></i>';
      }

      // 空星
      for (let i = 0; i < emptyStars; i++) {
        starsHtml += '<i class="fa fa-star-o"></i>';
      }

      return starsHtml;
    }

    // 筛选景点
    filterBtn.addEventListener('click', () => {
      // 显示加载动画
      loader.classList.add('active');
      attractionsList.style.display = 'none';
      noResults.style.display = 'none';

      // 模拟加载延迟
      setTimeout(() => {
        // 获取筛选条件
        const distance = parseInt(document.getElementById('distance').value);
        const minRating = parseFloat(document.getElementById('rating').value);
        const type = document.getElementById('type').value;
        const priceLevel = document.getElementById('price').value;

        // 筛选景点
        const filteredAttractions = attractionsData.filter(attraction => {
          // 距离筛选
          const distanceMatch = attraction.distance <= distance;

          // 评分筛选
          const ratingMatch = minRating === 0 || attraction.rating >= minRating;

          // 类型筛选
          const typeMatch = type === 'all' || attraction.type === type;

          // 价格筛选
          let priceMatch = true;
          if (priceLevel !== 'all') {
            if (priceLevel === 'free') {
              priceMatch = attraction.price === 0;
            } else if (priceLevel === 'cheap') {
              priceMatch = attraction.price > 0 && attraction.price <= 100;
            } else if (priceLevel === 'mid') {
              priceMatch = attraction.price > 100 && attraction.price <= 300;
            } else if (priceLevel === 'high') {
              priceMatch = attraction.price > 300;
            }
          }

          return distanceMatch && ratingMatch && typeMatch && priceMatch;
        });

        // 渲染筛选结果
        renderAttractions(filteredAttractions);
        attractionsList.style.display = 'grid';
        loader.classList.remove('active');
      }, 800);
    });

    // 打开模态框
    function openModal(attraction) {
      modalTitle.textContent = attraction.name;
      modalImg.src = attraction.image;
      modalImg.alt = attraction.name;

      // 更新星级评分
      const starsHtml = generateStars(attraction.rating);
      modalRating.innerHTML = `
        <div class="rating-stars">\${starsHtml}</div>
        <span class="rating-score">\${attraction.rating}</span>
        <span>(\${attraction.reviews}条评价)</span>
      `;

      // 更新元数据
      const priceDisplay = attraction.price === 0 ? '免费' : `¥\${attraction.price}/人`;
      modalMeta.innerHTML = `
        <div class="meta-item">
          <i class="fa fa-map-marker"></i>
          <span>距离 \${attraction.distance} 公里</span>
        </div>
        <div class="meta-item">
          <i class="fa fa-ticket"></i>
          <span>门票: \${priceDisplay}</span>
        </div>
        <div class="meta-item">
          <i class="fa fa-clock-o"></i>
          <span>开放时间: \${attraction.openTime}</span>
        </div>
      `;

      // 更新描述
      modalDesc.textContent = attraction.description;

      // 显示模态框
      modal.classList.add('active');
      document.body.style.overflow = 'hidden';
    }

    // 关闭模态框
    modalClose.addEventListener('click', () => {
      modal.classList.remove('active');
      document.body.style.overflow = '';
    });

    // 点击模态框外部关闭
    modal.addEventListener('click', (e) => {
      if (e.target === modal) {
        modal.classList.remove('active');
        document.body.style.overflow = '';
      }
    });

    // 键盘ESC关闭模态框
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && modal.classList.contains('active')) {
        modal.classList.remove('active');
        document.body.style.overflow = '';
      }
    });
  </script>
</body>
</html>
    '''
}
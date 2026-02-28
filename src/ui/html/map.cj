/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.ui.html

import magic.dsl.*
import magic.prelude.*

@jsonable
public class Location {
	@field["名称"]
    let name: String
    @field["经度"]
    let longitude: Float64
    @field["维度"]
    let latitude: Float64
    @field["分类"]
    let category: String
    @field["描述"]
    let description: String
}

@jsonable
public class MyLocation {
    @field["经度"]
    let longitude: Float64
    @field["维度"]
    let latitude: Float64
    @field["其他需要标记的地点"]
    let location: Array<Location>
}

@ui[
    description: '''
    功能类型：地图 UI・地点定位展示型,
    使用场景：展示地理相关信息，景点位置标注,
    交互特性：数据可视化型，支持地图缩放 / 平移操作；支持定位当前位置,
    风格属性：简约型，仅适合特定场景
    ''',
    kind: "display"
]
public func mapUI(info: MyLocation) {
    '''
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>交互式景点地图（高德地图版）</title>
  <!-- 引入Font Awesome -->
  <link href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css" rel="stylesheet">

  <style>
    /* 基础样式重置 */
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
      font-family: 'Inter', system-ui, -apple-system, sans-serif;
    }

    body {
      background-color: hsl(220, 10%, 95%);
      color: hsl(220, 20%, 10%);
      line-height: 1.5;
    }

    /* 颜色变量（HSL格式） */
    :root {
      --primary: hsl(220, 80%, 55%);
      --primary-light: hsl(220, 80%, 65%);
      --primary-dark: hsl(220, 80%, 45%);
      --primary-opacity-10: hsl(220, 80%, 55%, 0.1);
      --primary-opacity-50: hsl(220, 80%, 55%, 0.5);

      --secondary: hsl(177, 70%, 45%);
      --accent: hsl(25, 100%, 55%);
      --dark: hsl(220, 20%, 10%);
      --light: hsl(220, 10%, 95%);

      --gray-100: hsl(220, 10%, 90%);
      --gray-200: hsl(220, 10%, 80%);
      --gray-300: hsl(220, 10%, 70%);
      --gray-400: hsl(220, 10%, 60%);
      --gray-500: hsl(220, 10%, 50%);
      --gray-600: hsl(220, 10%, 40%);
      --gray-700: hsl(220, 10%, 30%);
      --gray-800: hsl(220, 10%, 20%);

      /* 景点类型颜色 */
      --nature: hsl(140, 70%, 40%);
      --heritage: hsl(25, 90%, 50%);
      --landmark: hsl(0, 80%, 55%);
      --food: hsl(280, 70%, 55%);
      --leisure: hsl(220, 80%, 55%);
      --other: hsl(220, 10%, 50%);
    }

    /* 工具类 */
    .content-auto {
      content-visibility: auto;
    }

    .map-height {
      height: calc(100vh - 64px);
      min-height: 400px;
      width: 100%;
      z-index: 10;
      border: none;
    }

    .card-shadow {
      box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.05);
    }

    .marker-pulse {
      animation: pulse 2s infinite;
    }

    @keyframes pulse {
      0% { transform: scale(0.95); box-shadow: 0 0 0 0 var(--primary-opacity-50); }
      70% { transform: scale(1); box-shadow: 0 0 0 10px var(--primary-opacity-10); }
      100% { transform: scale(0.95); box-shadow: 0 0 0 0 var(--primary-opacity-10); }
    }

    /* 导航栏样式 */
    header {
      background-color: white;
      box-shadow: 0 2px 10px rgba(0, 0, 0, 0.05);
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      z-index: 50;
      transition: all 0.3s ease;
    }

    .header-container {
      max-width: 1200px;
      margin: 0 auto;
      padding: 0 16px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      height: 64px;
    }

    .logo {
      display: flex;
      align-items: center;
      gap: 8px;
    }

    .logo i {
      color: var(--primary);
      font-size: 24px;
    }

    .logo h1 {
      font-size: 18px;
      font-weight: 600;
      color: var(--primary);
    }

    .desktop-menu {
      display: flex;
      align-items: center;
      gap: 24px;
    }

    .menu-btn {
      display: flex;
      align-items: center;
      gap: 4px;
      background: none;
      border: none;
      font-size: 14px;
      cursor: pointer;
      transition: color 0.2s ease;
      padding: 6px 8px;
      border-radius: 4px;
    }

    .menu-btn.primary {
      color: var(--primary);
    }

    .menu-btn.primary:hover {
      color: var(--primary-dark);
      background-color: var(--primary-opacity-10);
    }

    .menu-btn.default {
      color: var(--gray-600);
    }

    .menu-btn.default:hover {
      color: var(--gray-800);
      background-color: var(--gray-100);
    }

    .mobile-menu-btn {
      display: none;
      background: none;
      border: none;
      color: var(--gray-600);
      font-size: 20px;
      cursor: pointer;
      transition: color 0.2s ease;
    }

    .mobile-menu-btn:hover {
      color: var(--primary);
    }

    .mobile-menu {
      display: none;
      background-color: white;
      border-top: 1px solid var(--gray-100);
    }

    .mobile-menu-container {
      max-width: 1200px;
      margin: 0 auto;
      padding: 8px 16px;
      display: flex;
      flex-direction: column;
      gap: 8px;
    }

    .mobile-menu .menu-btn {
      padding: 10px 8px;
      justify-content: flex-start;
    }

    /* 主内容区 */
    main {
      padding-top: 64px;
    }

    /* 表单样式 */
    .marker-form {
      position: fixed;
      bottom: 24px;
      left: 50%;
      transform: translateX(-50%);
      background-color: white;
      border-radius: 8px;
      padding: 16px;
      width: 90%;
      max-width: 400px;
      box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.05);
      z-index: 40;
      display: none;
      transition: all 0.3s ease;
    }

    .form-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 16px;
    }

    .form-header h3 {
      font-size: 18px;
      font-weight: 600;
      color: var(--primary);
    }

    .close-btn {
      background: none;
      border: none;
      color: var(--gray-400);
      font-size: 18px;
      cursor: pointer;
      transition: color 0.2s ease;
    }

    .close-btn:hover {
      color: var(--gray-600);
    }

    .form-group {
      margin-bottom: 16px;
    }

    .form-group label {
      display: block;
      font-size: 14px;
      font-weight: 500;
      color: var(--gray-700);
      margin-bottom: 4px;
    }

    .form-control {
      width: 100%;
      padding: 10px 12px;
      border: 1px solid var(--gray-300);
      border-radius: 6px;
      font-size: 14px;
      transition: all 0.2s ease;
    }

    .form-control:focus {
      outline: none;
      border-color: var(--primary);
      box-shadow: 0 0 0 3px var(--primary-opacity-10);
    }

    textarea.form-control {
      min-height: 70px;
      resize: vertical;
    }

    .form-actions {
      display: flex;
      gap: 12px;
      margin-top: 20px;
    }

    .btn {
      flex: 1;
      padding: 10px;
      border-radius: 6px;
      font-size: 14px;
      font-weight: 500;
      cursor: pointer;
      transition: all 0.2s ease;
      border: none;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 6px;
    }

    .btn-primary {
      background-color: var(--primary);
      color: white;
    }

    .btn-primary:hover {
      background-color: var(--primary-dark);
    }

    .btn-default {
      background-color: var(--gray-100);
      color: var(--gray-700);
    }

    .btn-default:hover {
      background-color: var(--gray-200);
    }

    /* 页脚样式 */
    footer {
      background-color: white;
      padding: 12px 0;
      text-align: center;
      color: var(--gray-500);
      font-size: 13px;
    }

    /* 提示框样式 */
    .toast {
      position: fixed;
      top: 80px;
      left: 50%;
      transform: translateX(-50%);
      background-color: var(--primary);
      color: white;
      padding: 8px 16px;
      border-radius: 6px;
      z-index: 50;
      font-size: 14px;
    }

    /* 高德地图样式优化 */
    .amap-info-window {
      border-radius: 8px !important;
      box-shadow: 0 4px 16px rgba(0,0,0,0.15) !important;
      border: none !important;
    }

    .amap-info-content {
      padding: 0 !important;
      margin: 0 !important;
    }

    .amap-copyright {
      opacity: 0.8 !important;
      z-index: 10 !important;
    }

    .amap-zoomcontrol {
      border-radius: 4px !important;
      overflow: hidden !important;
      box-shadow: 0 2px 8px rgba(0,0,0,0.15) !important;
    }

    .amap-zoomcontrol a {
      width: 36px !important;
      height: 36px !important;
      line-height: 36px !important;
      font-size: 20px !important;
    }

    /* 信息窗口内容样式 */
    .info-window-content {
      padding: 12px;
      width: 280px;
    }

    .info-window-content h3 {
      font-size: 18px;
      font-weight: 600;
      color: var(--primary);
      margin-bottom: 6px;
    }

    .info-window-content .category {
      font-size: 13px;
      color: var(--gray-600);
      margin-bottom: 8px;
      display: flex;
      align-items: center;
      gap: 4px;
    }

    .info-window-content .description {
      font-size: 14px;
      color: var(--gray-700);
      margin-bottom: 8px;
      line-height: 1.5;
    }

    .info-window-content .location {
      font-size: 12px;
      color: var(--gray-500);
      display: flex;
      align-items: center;
      gap: 4px;
    }

    /* 响应式样式 */
    @media (max-width: 768px) {
      .desktop-menu {
        display: none;
      }

      .mobile-menu-btn {
        display: block;
      }

      .mobile-menu.active {
        display: block;
      }

      .info-window-content {
        width: 240px;
      }
    }
  </style>
</head>
<body>
  <!-- 顶部导航栏 -->
  <header>
    <div class="header-container">
      <div class="logo">
        <i class="fa fa-map-marker"></i>
        <h1>景点地图探索</h1>
      </div>

      <div class="desktop-menu">
        <button id="addMarkerBtn" class="menu-btn primary">
          <i class="fa fa-plus-circle"></i>
          <span>添加景点</span>
        </button>
        <button id="clearMarkersBtn" class="menu-btn default">
          <i class="fa fa-trash"></i>
          <span>清除标记</span>
        </button>
      </div>

      <!-- 移动端菜单按钮 -->
      <button id="mobileMenuBtn" class="mobile-menu-btn">
        <i class="fa fa-bars"></i>
      </button>
    </div>

    <!-- 移动端菜单 -->
    <div id="mobileMenu" class="mobile-menu">
      <div class="mobile-menu-container">
        <button id="mobileAddMarkerBtn" class="menu-btn primary">
          <i class="fa fa-plus-circle"></i>
          <span>添加景点</span>
        </button>
        <button id="mobileClearMarkersBtn" class="menu-btn default">
          <i class="fa fa-trash"></i>
          <span>清除标记</span>
        </button>
      </div>
    </div>
  </header>

  <!-- 主内容区 -->
  <main>
    <!-- 地图容器 -->
    <div id="map" class="map-height"></div>

    <!-- 景点信息表单 (默认隐藏) -->
    <div id="markerForm" class="marker-form">
      <div class="form-header">
        <h3>添加景点信息</h3>
        <button id="closeFormBtn" class="close-btn">
          <i class="fa fa-times"></i>
        </button>
      </div>

      <form id="pointOfInterestForm">
        <div class="form-group">
          <label for="poiName">景点名称</label>
          <input type="text" id="poiName" name="poiName" required class="form-control">
        </div>

        <div class="form-group">
          <label for="poiDescription">景点描述</label>
          <textarea id="poiDescription" name="poiDescription" rows="2" class="form-control"></textarea>
        </div>

        <div class="form-group">
          <label for="poiCategory">景点类型</label>
          <select id="poiCategory" name="poiCategory" class="form-control">
            <option value="自然景观">自然景观</option>
            <option value="人文古迹">人文古迹</option>
            <option value="城市地标">城市地标</option>
            <option value="美食推荐">美食推荐</option>
            <option value="娱乐休闲">娱乐休闲</option>
            <option value="其他">其他</option>
          </select>
        </div>

        <div class="form-actions">
          <button type="submit" class="btn btn-primary">
            <i class="fa fa-save"></i>
            <span>保存景点</span>
          </button>
          <button type="button" id="cancelFormBtn" class="btn btn-default">
            取消
          </button>
        </div>
      </form>
    </div>
  </main>

  <!-- 底部信息 -->
  <footer>
    <p>© 2025 景点地图探索 | 点击地图添加景点标记</p>
  </footer>
  <!-- 引入高德地图API -->
  <script type="text/javascript" src="https://webapi.amap.com/maps?v=2.0&key=85201fe2df04d100f944b5e6cfcb619f"></script>
  <script>
    // 等待DOM完全加载后初始化地图
    document.addEventListener('DOMContentLoaded', function() {
      try {
        // 检查高德地图API是否加载成功
        if (typeof AMap === 'undefined') {
          throw new Error('高德地图API加载失败');
        }

        // 初始化高德地图 - 默认定位到北京
        const map = new AMap.Map('map', {
          zoom: 12,
          center: [{% info.longitude %}, {% info.latitude %}], // 高德地图使用 [lng, lat] 格式
          resizeEnable: true,
          zoomControl: true,
          scaleControl: true
        });

        // 存储标记和相关数据
        let markers = [];
        let currentMarker = null;
        let isAddingMarker = false;

        // DOM元素
        const mapElement = document.getElementById('map');
        const markerForm = document.getElementById('markerForm');
        const pointOfInterestForm = document.getElementById('pointOfInterestForm');
        const addMarkerBtn = document.getElementById('addMarkerBtn');
        const clearMarkersBtn = document.getElementById('clearMarkersBtn');
        const closeFormBtn = document.getElementById('closeFormBtn');
        const cancelFormBtn = document.getElementById('cancelFormBtn');
        const mobileMenuBtn = document.getElementById('mobileMenuBtn');
        const mobileMenu = document.getElementById('mobileMenu');
        const mobileAddMarkerBtn = document.getElementById('mobileAddMarkerBtn');
        const mobileClearMarkersBtn = document.getElementById('mobileClearMarkersBtn');

        // 移动端菜单切换
        mobileMenuBtn.addEventListener('click', () => {
          mobileMenu.classList.toggle('active');
        });

        // 根据景点类型获取对应的图标配置
        function getCategoryIconOptions(category) {
          const iconOptions = {
            '自然景观': {
              color: 'hsl(140, 70%, 40%)',
              icon: 'fa-tree',
              textColor: 'hsl(140, 70%, 40%)'
            },
            '人文古迹': {
              color: 'hsl(25, 90%, 50%)',
              icon: 'fa-university',
              textColor: 'hsl(25, 90%, 50%)'
            },
            '城市地标': {
              color: 'hsl(0, 80%, 55%)',
              icon: 'fa-building',
              textColor: 'hsl(0, 80%, 55%)'
            },
            '美食推荐': {
              color: 'hsl(280, 70%, 55%)',
              icon: 'fa-cutlery',
              textColor: 'hsl(280, 70%, 55%)'
            },
            '娱乐休闲': {
              color: 'hsl(220, 80%, 55%)',
              icon: 'fa-futbol-o',
              textColor: 'hsl(220, 80%, 55%)'
            },
            '其他': {
              color: 'hsl(220, 10%, 50%)',
              icon: 'fa-map-marker',
              textColor: 'hsl(220, 10%, 50%)'
            }
          };

          return iconOptions[category] || {
            color: 'hsl(220, 10%, 50%)',
            icon: 'fa-map-marker',
            textColor: 'hsl(220, 10%, 50%)'
          };
        }

        // 创建自定义标记图标
        function createCustomMarkerIcon(options) {
          const { color, icon } = options;
          return new AMap.Icon(`
            <div class="marker-pulse flex items-center justify-center w-10 h-10" style="background-color: \${color}; border-radius: 50%;">
              <i class="fa \${icon} text-white text-xl"></i>
            </div>
          `, {
            size: new AMap.Size(40, 40),
            anchor: new AMap.Pixel(20, 40),
            imageSize: new AMap.Size(40, 40)
          });
        }

        // 添加景点标记
        function addPoiMarker(lnglat, name, description, category) {
          try {
            const iconOptions = getCategoryIconOptions(category);
            const markerIcon = createCustomMarkerIcon(iconOptions);

            // 创建标记
            const marker = new AMap.Marker({
              position: lnglat,
              icon: markerIcon,
              anchor: 'bottom-center',
              animation: 'AMAP_ANIMATION_DROP',
              zoom: 12
            });

            marker.setMap(map);

            // 创建信息窗口内容
            const infoWindowContent = `
              <div class="info-window-content">
                <h3>\${name}</h3>
                <div class="category">
                  <i class="fa \${iconOptions.icon}" style="color: \${iconOptions.textColor};"></i>
                  \${category}
                </div>
                \${description ? `<p class="description">\${description}</p>` : ''}
                <div class="location">
                  <i class="fa fa-map-pin"></i>
                  \${lnglat[1].toFixed(6)}, \${lnglat[0].toFixed(6)}
                </div>
              </div>
            `;

            // 创建信息窗口
            const infoWindow = new AMap.InfoWindow({
              content: infoWindowContent,
              size: new AMap.Size(300, 0),
              autoMove: true,
              closeWhenClickMap: true
            });

            // 绑定信息窗口到标记
            marker.on('click', function() {
              infoWindow.open(map, marker.getPosition());
            });

            // 存储标记数据
            marker.poiData = {
              lnglat: lnglat,
              name: name,
              description: description,
              category: category,
              infoWindow: infoWindow
            };

            markers.push(marker);

            // 打开信息窗口
            infoWindow.open(map, marker.getPosition());

            return marker;
          } catch (error) {
            console.error('添加标记失败:', error);
            alert('添加景点标记失败，请重试');
          }
        }

        // 地图点击事件 - 添加临时标记
        map.on('click', (e) => {
          if (isAddingMarker) {
            // 移除之前的临时标记
            if (currentMarker) {
              currentMarker.remove();
            }

            // 创建临时标记图标
            const tempIcon = new AMap.Icon(`
              <div class="marker-pulse flex items-center justify-center w-10 h-10" style="background-color: hsl(220, 80%, 55%, 0.9); border-radius: 50%;">
                <i class="fa fa-map-marker text-white text-xl"></i>
              </div>
            `, {
              size: new AMap.Size(40, 40),
              anchor: new AMap.Pixel(20, 40),
              imageSize: new AMap.Size(40, 40)
            });

            // 创建临时标记
            currentMarker = new AMap.Marker({
              position: [e.lnglat.getLng(), e.lnglat.getLat()],
              icon: tempIcon,
              anchor: 'bottom-center',
              animation: 'AMAP_ANIMATION_BOUNCE'
            });

            currentMarker.setMap(map);
            currentMarker.temp = true;

            // 显示表单
            markerForm.style.display = 'block';

            // 滚动到表单（移动端）
            if (window.innerWidth < 768) {
              markerForm.scrollIntoView({ behavior: 'smooth', block: 'center' });
            }
          }
        });

        // 表单提交事件
        pointOfInterestForm.addEventListener('submit', (e) => {
          e.preventDefault();

          if (currentMarker && currentMarker.temp) {
            const name = document.getElementById('poiName').value;
            const description = document.getElementById('poiDescription').value;
            const category = document.getElementById('poiCategory').value;
            const lnglat = currentMarker.getPosition();

            // 移除临时标记
            currentMarker.remove();

            // 添加正式标记
            addPoiMarker(lnglat, name, description, category);

            // 重置表单和状态
            pointOfInterestForm.reset();
            markerForm.style.display = 'none';
            currentMarker = null;
            isAddingMarker = false;

            // 更改按钮状态
            toggleAddMarkerButton(false);
          }
        });

        // 关闭表单事件
        function closeForm() {
          if (currentMarker && currentMarker.temp) {
            currentMarker.remove();
            currentMarker = null;
          }

          pointOfInterestForm.reset();
          markerForm.style.display = 'none';
          isAddingMarker = false;

          // 更改按钮状态
          toggleAddMarkerButton(false);
        }

        closeFormBtn.addEventListener('click', closeForm);
        cancelFormBtn.addEventListener('click', closeForm);

        // 切换添加标记按钮状态
        function toggleAddMarkerButton(active) {
          if (active) {
            // 桌面端按钮
            addMarkerBtn.classList.add('bg-primary-opacity-10');
            addMarkerBtn.innerHTML = '<i class="fa fa-map-marker"></i><span>点击地图添加</span>';

            // 移动端按钮
            mobileAddMarkerBtn.classList.add('bg-primary-opacity-10');
            mobileAddMarkerBtn.innerHTML = '<i class="fa fa-map-marker"></i><span>点击地图添加</span>';

            // 显示提示
            showToast('请点击地图上的位置添加景点标记');
          } else {
            // 桌面端按钮
            addMarkerBtn.classList.remove('bg-primary-opacity-10');
            addMarkerBtn.innerHTML = '<i class="fa fa-plus-circle"></i><span>添加景点</span>';

            // 移动端按钮
            mobileAddMarkerBtn.classList.remove('bg-primary-opacity-10');
            mobileAddMarkerBtn.innerHTML = '<i class="fa fa-plus-circle"></i><span>添加景点</span>';
          }
        }

        // 显示提示框
        function showToast(message) {
          const toast = document.createElement('div');
          toast.className = 'toast';
          toast.textContent = message;
          document.body.appendChild(toast);

          setTimeout(() => {
            toast.remove();
          }, 3000);
        }

        // 添加标记按钮事件
        function handleAddMarkerClick() {
          isAddingMarker = !isAddingMarker;
          toggleAddMarkerButton(isAddingMarker);

          // 如果取消添加，关闭表单
          if (!isAddingMarker) {
            closeForm();
          }
        }

        addMarkerBtn.addEventListener('click', handleAddMarkerClick);
        mobileAddMarkerBtn.addEventListener('click', () => {
          mobileMenu.classList.remove('active');
          handleAddMarkerClick();
        });

        // 清除所有标记按钮事件
        function clearAllMarkers() {
          if (markers.length === 0) {
            alert('当前没有景点标记');
            return;
          }

          if (confirm('确定要清除所有景点标记吗？此操作不可撤销。')) {
            markers.forEach(marker => {
              try {
                // 关闭信息窗口
                if (marker.poiData && marker.poiData.infoWindow) {
                  marker.poiData.infoWindow.close();
                }
                // 移除标记
                marker.remove();
              } catch (error) {
                console.error('移除标记失败:', error);
              }
            });
            markers = [];

            // 如果有临时标记也移除
            if (currentMarker && currentMarker.temp) {
              currentMarker.remove();
              currentMarker = null;
            }

            // 关闭表单
            markerForm.style.display = 'none';
            isAddingMarker = false;
            toggleAddMarkerButton(false);
          }
        }

        clearMarkersBtn.addEventListener('click', clearAllMarkers);
        mobileClearMarkersBtn.addEventListener('click', () => {
          mobileMenu.classList.remove('active');
          clearAllMarkers();
        });

        // 示例景点数据 - 高德地图使用 [lng, lat] 格式
        const samplePoiData = [
          {% for loc in info.location %}
          {
            lnglat: [{% loc.longitude %}, {% loc.latitude %}],
            name: '{% loc.name %}',
            description: '{% loc.description %}',
            category: '{% loc.category %}'
          },
          {% /for %}
        ];

        // 延迟添加示例景点，确保地图完全加载
        setTimeout(() => {
          samplePoiData.forEach(poi => {
            addPoiMarker(poi.lnglat, poi.name, poi.description, poi.category);
          });
        }, 1000);

        // 窗口大小变化时调整地图
        window.addEventListener('resize', () => {
          setTimeout(() => {
            map.resize();
          }, 100);
        });
      } catch (error) {
        console.error('地图初始化失败:', error);
        // 显示错误提示
        const mapElement = document.getElementById('map');
        mapElement.innerHTML = `
          <div style="display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100%; text-align: center; padding: 20px;">
            <i class="fa fa-map-o" style="color: hsl(220, 10%, 70%); font-size: 64px; margin-bottom: 16px;"></i>
            <h3 style="font-size: 20px; font-weight: 600; color: hsl(220, 10%, 30%); margin-bottom: 8px;">地图加载失败</h3>
            <p style="color: hsl(220, 10%, 50%); margin-bottom: 8px;">\${error.message}</p>
            <p style="color: hsl(220, 10%, 50%); margin-bottom: 24px;">请检查API密钥是否有效或网络连接是否正常</p>
            <button id="retryMapBtn" style="background-color: hsl(220, 80%, 55%); color: white; border: none; padding: 10px 20px; border-radius: 6px; font-size: 14px; font-weight: 500; cursor: pointer; transition: background-color 0.2s ease;">
              重试加载
            </button>
          </div>
        `;

        // 重试按钮事件
        document.getElementById('retryMapBtn').addEventListener('click', () => {
          window.location.reload();
        });
      }
    });
  </script>
</body>
</html>
    '''
}
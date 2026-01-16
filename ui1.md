# Lumos Stock UI改造计划

## 📊 项目现状分析

### 当前技术栈
- **框架**: Vue 3.5.17 (Composition API)
- **主UI库**: Naive UI 2.43.2
- **辅助UI库**: TDesign Vue Next 0.4.5 (AI聊天模块)
- **图表库**: ECharts 5.6.0
- **构建工具**: Vite 7.2.4
- **桌面框架**: Wails (Go + Web)
- **样式方案**: 原生CSS + 内联样式

### 应用类型
跨平台桌面应用（Windows/macOS/Linux）- 股票AI分析工具

---

## 🔍 当前UI存在的主要问题

### 1. **设计系统不统一** ⚠️

#### 问题描述
- 混合使用两套UI库（Naive UI + TDesign），导致视觉风格不一致
- 缺乏统一的设计语言和设计令牌（Design Tokens）
- 颜色、间距、字体等硬编码在各组件中

#### 具体表现
```javascript
// stock.vue:83-86 - 硬编码颜色
const upColor = '#ec0000';      // 涨（红色）
const downColor = '#00da3c';    // 跌（绿色）

// App.vue:698 - 内联样式颜色
style: { "color": "#f67979" }   // 红色新闻
style: { "color": "#F98C24" }   // lumos新闻
style: { "color": "#549EC8" }   // 其他新闻
```

#### 影响
- 维护成本高，修改颜色需要全局搜索替换
- 主题切换困难，深浅色主题一致性差
- 视觉体验割裂

---

### 2. **信息架构混乱** 📐

#### 问题描述
- 主组件stock.vue代码量过大（2462行），违反单一职责原则
- 布局结构不清晰，缺乏明确的视觉层级
- 导航菜单层级过深（市场行情下有12个子菜单）

#### 具体表现
```vue
<!-- App.vue:132-397 - 菜单结构过于复杂 -->
{
  key: 'market',
  children: [
    { label: '市场快讯' },
    { label: '全球股指' },
    { label: '重大指数' },
    { label: '行业排名' },
    { label: '个股资金流向' },
    { label: '龙虎榜' },
    { label: '个股研报' },
    { label: '公司公告' },
    { label: '行业研究' },
    { label: '当前热门' },
    { label: '指标选股' },
    { label: '名站优选' }
  ]
}
```

#### 影响
- 用户认知负担重，难以快速找到功能
- 学习曲线陡峭
- 代码可维护性差

---

### 3. **视觉层级不明确** 👁️

#### 问题描述
- 缺乏明确的主次信息区分
- 数据展示过于密集，缺乏呼吸感
- 缺乏视觉引导和焦点设计

#### 具体表现
- 股票列表、K线图、AI分析结果并列展示，缺乏优先级
- 新闻滚动条占据顶部空间，干扰主要内容
- 弹幕功能可能与重要信息冲突

#### 影响
- 关键信息不突出
- 用户注意力分散
- 决策效率降低

---

### 4. **交互体验不足** 🖱️

#### 问题描述
- 缺乏加载状态和过渡动画
- 错误处理和反馈机制不完善
- 缺乏微交互和动效

#### 具体表现
```javascript
// stock.vue:342 - 简单的loading提示
message.loading("刷新股票基础数据...")
// 缺乏骨架屏、进度指示器等
```

#### 影响
- 应用感觉"卡顿"
- 用户不清楚系统状态
- 缺乏专业感

---

### 5. **响应式设计缺失** 📱

#### 问题描述
- 固定布局，缺乏对不同屏幕尺寸的适配
- 虽然使用Naive UI的栅格系统，但未充分利用
- 桌面应用在小型笔记本屏幕上体验差

#### 具体表现
```javascript
// market.vue:44 - 固定高度计算
const panelHeight = ref(window.innerHeight - 240)
// 硬编码的偏移值，缺乏响应式
```

#### 影响
- 不同分辨率下显示不一致
- 小屏幕上内容可能被遮挡
- 窗口缩放时布局错乱

---

### 6. **可访问性（a11y）不足** ♿

#### 问题描述
- 缺乏键盘导航支持
- 色彩对比度可能不足
- 缺乏ARIA标签和语义化HTML

#### 具体表现
- 红绿色彩仅用颜色区分涨跌，对色盲用户不友好
- 复杂的菜单结构难以用键盘导航
- 缺乏焦点管理

#### 影响
- 部分用户无法使用
- 不符合无障碍标准
- 用户群体受限

---

### 7. **性能优化空间** ⚡

#### 问题描述
- 大量实时数据更新可能导致性能问题
- 图表渲染可能占用大量资源
- 缺乏虚拟滚动和懒加载

#### 具体表现
```javascript
// stock.vue:125 - 3秒定时刷新股票价格
// 可能导致频繁重渲染
EventsOn("stock_price", (data) => {
  updateData(data)  // 每次更新全量数据
})
```

#### 影响
- 应用可能卡顿
- CPU/内存占用高
- 电池消耗快（笔记本）

---

## 🎯 改造目标

### 参考设计风格

#### 1. **Shadcn UI设计系统原则**
- ✅ **组件即代码** - 完全控制组件实现
- ✅ **可访问性优先** - 基于Radix UI无障碍原语
- ✅ **主题定制** - CSS变量实现深浅色主题
- ✅ **设计令牌** - 统一的颜色、间距、字体系统
- ✅ **渐进增强** - 基础功能到高级特性

#### 2. **欧易交易所（OKX）设计特点**
- ✅ **专业简洁** - 信息密度适中，清晰易读
- ✅ **深色主题优先** - 适合长时间使用
- ✅ **数据可视化** - 图表与数据完美结合
- ✅ **多栏布局** - 高效利用空间
- ✅ **快速操作** - 常用功能一键触达

---

## 📋 改造计划

### 阶段一：设计系统重构（Foundation）⏱️ 2周

#### 1.1 建立设计令牌系统

**目标**: 统一颜色、间距、字体、阴影等设计变量

**实施步骤**:

```css
/* frontend/src/styles/design-tokens.css */

/* ===== 颜色系统 ===== */
:root {
  /* 品牌色 - 参考OKX蓝色系 */
  --color-brand-50: #eff6ff;
  --color-brand-100: #dbeafe;
  --color-brand-200: #bfdbfe;
  --color-brand-300: #93c5fd;
  --color-brand-400: #60a5fa;
  --color-brand-500: #3b82f6;  /* 主品牌色 */
  --color-brand-600: #2563eb;
  --color-brand-700: #1d4ed8;
  --color-brand-800: #1e40af;
  --color-brand-900: #1e3a8a;

  /* 股票涨跌色 - 符合中国习惯 */
  --color-up: #ef4444;        /* 涨 - 红色 */
  --color-up-light: #fca5a5;
  --color-up-dark: #b91c1c;

  --color-down: #22c55e;      /* 跌 - 绿色 */
  --color-down-light: #86efac;
  --color-down-dark: #15803d;

  /* 中性色 - 参考shadcn/ui */
  --color-bg-primary: #ffffff;
  --color-bg-secondary: #f8fafc;
  --color-bg-tertiary: #f1f5f9;

  --color-text-primary: #0f172a;
  --color-text-secondary: #475569;
  --color-text-tertiary: #94a3b8;
  --color-text-disabled: #cbd5e1;

  /* 语义色 */
  --color-success: #22c55e;
  --color-warning: #f59e0b;
  --color-error: #ef4444;
  --color-info: #3b82f6;
}

/* 深色主题 */
[data-theme="dark"] {
  --color-brand-500: #60a5fa;

  --color-bg-primary: #0f172a;
  --color-bg-secondary: #1e293b;
  --color-bg-tertiary: #334155;

  --color-text-primary: #f8fafc;
  --color-text-secondary: #cbd5e1;
  --color-text-tertiary: #64748b;
  --color-text-disabled: #475569;
}

/* ===== 间距系统 - 4px基准 ===== */
--spacing-0: 0;
--spacing-1: 0.25rem;  /* 4px */
--spacing-2: 0.5rem;   /* 8px */
--spacing-3: 0.75rem;  /* 12px */
--spacing-4: 1rem;     /* 16px */
--spacing-5: 1.25rem;  /* 20px */
--spacing-6: 1.5rem;   /* 24px */
--spacing-8: 2rem;     /* 32px */
--spacing-10: 2.5rem;  /* 40px */
--spacing-12: 3rem;    /* 48px */

/* ===== 字体系统 ===== */
--font-family-base: "Nunito", -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
--font-family-mono: "SF Mono", "Monaco", "Cascadia Code", monospace;

--font-size-xs: 0.75rem;    /* 12px */
--font-size-sm: 0.875rem;   /* 14px */
--font-size-base: 1rem;     /* 16px */
--font-size-lg: 1.125rem;   /* 18px */
--font-size-xl: 1.25rem;    /* 20px */
--font-size-2xl: 1.5rem;    /* 24px */
--font-size-3xl: 1.875rem;  /* 30px */
--font-size-4xl: 2.25rem;   /* 36px */

--font-weight-normal: 400;
--font-weight-medium: 500;
--font-weight-semibold: 600;
--font-weight-bold: 700;

--line-height-tight: 1.25;
--line-height-normal: 1.5;
--line-height-relaxed: 1.75;

/* ===== 圆角系统 ===== */
--radius-sm: 0.25rem;   /* 4px */
--radius-md: 0.375rem;  /* 6px */
--radius-lg: 0.5rem;    /* 8px */
--radius-xl: 0.75rem;   /* 12px */
--radius-2xl: 1rem;     /* 16px */
--radius-full: 9999px;

/* ===== 阴影系统 ===== */
--shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);
--shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1);
--shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1);
--shadow-xl: 0 20px 25px -5px rgb(0 0 0 / 0.1);

/* ===== 动画 ===== */
--transition-fast: 150ms cubic-bezier(0.4, 0, 0.2, 1);
--transition-base: 200ms cubic-bezier(0.4, 0, 0.2, 1);
--transition-slow: 300ms cubic-bezier(0.4, 0, 0.2, 1);

/* ===== Z-index系统 ===== */
--z-index-dropdown: 1000;
--z-index-sticky: 1020;
--z-index-fixed: 1030;
--z-index-modal-backdrop: 1040;
--z-index-modal: 1050;
--z-index-popover: 1060;
--z-index-tooltip: 1070;
```

**替换硬编码颜色**:
```javascript
// 修改前
const upColor = '#ec0000';
const downColor = '#00da3c';

// 修改后
const upColor = 'var(--color-up)';
const downColor = 'var(--color-down)';
```

---

#### 1.2 迁移到Tailwind CSS（可选）

**目标**: 使用Tailwind替代原生CSS，提高开发效率

**理由**:
- shadcn/ui基于Tailwind CSS
- 更快的开发速度
- 更小最终体积（purge）
- 响应式设计更简单

**实施方案**:
```bash
npm install -D tailwindcss@3 postcss@8 autoprefixer@10
npx tailwindcss init -p
```

```javascript
// tailwind.config.js
module.exports = {
  content: [
    "./index.html",
    "./src/**/*.{vue,js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        // 使用设计令牌
        brand: {
          50: 'var(--color-brand-50)',
          500: 'var(--color-brand-500)',
          // ...
        },
        up: {
          DEFAULT: 'var(--color-up)',
          light: 'var(--color-up-light)',
          dark: 'var(--color-up-dark)',
        },
        down: {
          DEFAULT: 'var(--color-down)',
          light: 'var(--color-down-light)',
          dark: 'var(--color-down-dark)',
        }
      }
    },
  },
  plugins: [],
}
```

---

#### 1.3 统一组件库

**目标**: 逐步迁移到单一UI库方案

**决策**: 继续使用Naive UI，但进行主题定制

**理由**:
- Naive UI专为Vue设计，迁移成本高
- 可以通过主题定制达到shadcn/ui的视觉效果
- TDesign仅保留AI聊天模块使用

**Naive UI主题定制**:
```javascript
// frontend/src/composables/useNaiveUITheme.js
import { darkTheme, lightTheme } from 'naive-ui'

const themeOverrides = {
  common: {
    primaryColor: '#3b82f6',
    primaryColorHover: '#60a5fa',
    primaryColorPressed: '#2563eb',
    primaryColorSuppl: '#3b82f6',
  },
  Button: {
    borderRadiusMedium: '8px',
    fontWeightMedium: '500',
  },
  Card: {
    borderRadius: '12px',
  },
  // ... 更多组件覆盖
}

export function useCustomTheme() {
  const isDark = ref(false)

  const theme = computed(() =>
    isDark.value ? darkTheme : lightTheme
  )

  return {
    theme,
    themeOverrides,
    isDark
  }
}
```

---

### 阶段二：信息架构重构（IA）⏱️ 1.5周

#### 2.1 扁平化导航结构

**当前问题**: 市场行情下12个子菜单过于复杂

**改造方案**:

```
修改前:
├── 股票自选
│   ├── 全部
│   ├── 自定义分组1
│   └── 自定义分组2
├── 市场行情 (12个子菜单 ❌)
├── 基金自选
├── AI智能体
├── 设置
└── 关于

修改后:
├── 首页 (股票自选)
│   ├── 全部
│   ├── 自定义分组
├── 市场 (重组为3个Tab)
│   ├── 快讯 (市场快讯 + 个股研报)
│   ├── 行情 (全球股指 + 重大指数 + 行业排名)
│   └── 发现 (龙虎榜 + 热门股票 + 主题投资)
├── 分析 (新增整合页)
│   ├── K线图
│   ├── 资金流向
│   └── AI分析
├── AI助手
├── 设置
└── 关于
```

#### 2.2 页面布局重组

**参考OKX多栏布局**:

```
┌────────────────────────────────────────────────────┐
│ 顶部导航栏 (高度: 56px)                            │
│ Logo | 搜索 | 快速操作 | 用户                      │
├─────────┬──────────────────────────┬───────────────┤
│         │                          │               │
│ 侧边栏  │     主内容区             │  信息面板     │
│ (宽度:  │     (弹性)               │  (宽度:       │
│ 200px)  │                          │  320px)       │
│         │  ┌────────────────────┐  │               │
│ ├─首页  │  │                    │  │ ┌───────────┐│
│ ├─市场  │  │   K线图/列表       │  │ │   实时    ││
│ ├─分析  │  │   (主视图)         │  │ │   概况    ││
│ ├─AI    │  │                    │  │ │           ││
│ └─设置  │  └────────────────────┘  │ ├───────────┤│
│         │                          │ │   自选股  ││
│         │  ┌────────────────────┐  │ │   监控    ││
│         │  │   AI分析结果       │  │ ├───────────┤│
│         │  │   (可折叠)         │  │ │   新闻    ││
│         │  └────────────────────┘  │ └───────────┘│
└─────────┴──────────────────────────┴───────────────┘
```

#### 2.3 组件拆分

**目标**: 将stock.vue（2462行）拆分为可维护的小组件

```
frontend/src/components/stock/
├── StockList.vue          # 股票列表
├── StockCard.vue          # 单个股票卡片
├── StockDetailPanel.vue   # 股票详情面板
├── KLineChart.vue         # K线图 (已存在)
├── StockTable.vue         # 数据表格
├── FilterBar.vue          # 筛选栏
├── GroupTabs.vue          # 分组标签
└── index.vue              # 组合组件
```

---

### 阶段三：视觉设计优化（Visual）⏱️ 2周

#### 3.1 颜色可访问性增强

**问题**: 仅用颜色区分涨跌，对色盲用户不友好

**解决方案**:

```vue
<!-- 添加图标辅助 -->
<template>
  <div class="stock-change" :class="changeClass">
    <!-- 使用箭头图标 + 颜色 -->
    <CaretUp v-if="isUp" class="icon-up" />
    <CaretDown v-if="isDown" class="icon-down" />
    <span>{{ changePercent }}</span>
  </div>
</template>

<style scoped>
.stock-change {
  display: flex;
  align-items: center;
  gap: var(--spacing-1);
}

.stock-change.up {
  color: var(--color-up);
}

.stock-change.down {
  color: var(--color-down);
}

/* 色盲友好的纹理模式 */
.stock-change.up::before {
  content: '';
  background: repeating-linear-gradient(
    45deg,
    transparent,
    transparent 2px,
    var(--color-up) 2px,
    var(--color-up) 4px
  );
}

.stock-change.down::before {
  content: '';
  background: repeating-linear-gradient(
    -45deg,
    transparent,
    transparent 2px,
    var(--color-down) 2px,
    var(--color-down) 4px
  );
}
</style>
```

#### 3.2 卡片式设计

**参考shadcn/ui Card组件**:

```vue
<!-- frontend/src/components/base/BaseCard.vue -->
<template>
  <div class="base-card" :class="[variant, size]">
    <div v-if="$slots.header" class="card-header">
      <slot name="header" />
    </div>
    <div class="card-body">
      <slot />
    </div>
    <div v-if="$slots.footer" class="card-footer">
      <slot name="footer" />
    </div>
  </div>
</template>

<script setup>
defineProps({
  variant: {
    type: String,
    default: 'default',
    validator: (value) => ['default', 'outlined', 'elevated'].includes(value)
  },
  size: {
    type: String,
    default: 'md',
    validator: (value) => ['sm', 'md', 'lg'].includes(value)
  }
})
</script>

<style scoped>
.base-card {
  background: var(--color-bg-primary);
  border-radius: var(--radius-lg);
  border: 1px solid var(--color-border);
  transition: all var(--transition-base);
}

.base-card.elevated {
  box-shadow: var(--shadow-md);
}

.base-card.elevated:hover {
  box-shadow: var(--shadow-lg);
  transform: translateY(-2px);
}

.card-header {
  padding: var(--spacing-6);
  border-bottom: 1px solid var(--color-border);
}

.card-body {
  padding: var(--spacing-6);
}

.card-footer {
  padding: var(--spacing-6);
  border-top: 1px solid var(--color-border);
}
</style>
```

#### 3.3 数据可视化优化

**ECharts主题定制**:

```javascript
// frontend/src/composables/useEChartsTheme.js
export const echartsLightTheme = {
  color: [
    '#3b82f6', '#ef4444', '#22c55e', '#f59e0b',
    '#8b5cf6', '#ec4899', '#14b8a6', '#f97316'
  ],
  backgroundColor: 'transparent',
  textStyle: {
    fontFamily: 'var(--font-family-base)',
    fontSize: 12,
    color: 'var(--color-text-primary)'
  },
  grid: {
    left: '3%',
    right: '4%',
    bottom: '3%',
    containLabel: true
  },
  // K线图颜色
  candlestick: {
    itemStyle: {
      color: 'var(--color-up)',
      color0: 'var(--color-down)',
      borderColor: 'var(--color-up-dark)',
      borderColor0: 'var(--color-down-dark)'
    }
  }
}

export const echartsDarkTheme = {
  // ... 深色主题配置
}
```

#### 3.4 深色模式优化

**参考OKX深色主题**:

```css
/* 优先使用深色主题作为默认 */
[data-theme="dark"] {
  /* 背景色 - 深蓝灰色系 */
  --color-bg-primary: #0B0E11;  /* OKX风格 */
  --color-bg-secondary: #151A21;
  --color-bg-tertiary: #1E2329;

  /* 文本色 - 高对比度 */
  --color-text-primary: #EAECEF;
  --color-text-secondary: #848E9C;
  --color-text-tertiary: #5E6673;

  /* 边框色 - 微妙 */
  --color-border: #2B3139;

  /* 品牌色 - 适合深色 */
  --color-brand-500: #FCD535;  /* OKX黄色 */
  --color-brand-600: #E5C02D;

  /* 股票涨跌 - 稍微调亮以提高可见性 */
  --color-up: #F6465D;       /* OKX红 */
  --color-down: #0ECB81;     /* OKX绿 */
}
```

---

### 阶段四：交互体验提升（Interaction）⏱️ 1.5周

#### 4.1 加载状态优化

**骨架屏组件**:

```vue
<!-- frontend/src/components/base/SkeletonLoader.vue -->
<template>
  <div class="skeleton-loader">
    <div v-for="i in rows" :key="i" class="skeleton-item" :style="{ width: getWidth(i) }">
      <div class="skeleton-animation"></div>
    </div>
  </div>
</template>

<script setup>
defineProps({
  rows: { type: Number, default: 5 }
})

function getWidth(index) {
  // 模拟真实内容的长度变化
  const widths = ['90%', '70%', '95%', '80%', '85%']
  return widths[index % widths.length]
}
</script>

<style scoped>
.skeleton-item {
  height: 16px;
  margin-bottom: 12px;
  background: var(--color-bg-tertiary);
  border-radius: var(--radius-sm);
  position: relative;
  overflow: hidden;
}

.skeleton-animation {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: linear-gradient(
    90deg,
    transparent,
    rgba(255, 255, 255, 0.1),
    transparent
  );
  animation: skeleton-loading 1.5s infinite;
}

@keyframes skeleton-loading {
  0% { transform: translateX(-100%); }
  100% { transform: translateX(100%); }
}
</style>
```

#### 4.2 过渡动画

**页面切换动画**:

```css
/* frontend/src/styles/transitions.css */

/* 淡入淡出 */
.fade-enter-active,
.fade-leave-active {
  transition: opacity var(--transition-base);
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

/* 滑动 */
.slide-enter-active,
.slide-leave-active {
  transition: transform var(--transition-base);
}

.slide-enter-from {
  transform: translateX(100%);
}

.slide-leave-to {
  transform: translateX(-100%);
}

/* 缩放 */
.scale-enter-active,
.scale-leave-active {
  transition: all var(--transition-base);
}

.scale-enter-from,
.scale-leave-to {
  opacity: 0;
  transform: scale(0.95);
}
```

**Vue Router集成**:
```javascript
// router/index.js
const routes = [
  {
    path: '/',
    component: StockView,
    meta: { transition: 'fade' }
  }
]
```

```vue
<!-- App.vue -->
<template>
  <router-view v-slot="{ Component, route }">
    <transition :name="route.meta.transition || 'fade'">
      <component :is="Component" :key="route.path" />
    </transition>
  </router-view>
</template>
```

#### 4.3 微交互

**按钮反馈**:

```vue
<!-- frontend/src/components/base/BaseButton.vue -->
<template>
  <button
    class="base-button"
    :class="[variant, size, { 'loading': loading, 'disabled': disabled }]"
    :disabled="disabled || loading"
    @click="handleClick"
  >
    <span v-if="loading" class="button-spinner"></span>
    <slot />
  </button>
</template>

<style scoped>
.base-button {
  position: relative;
  overflow: hidden;
  transition: all var(--transition-fast);
}

.base-button:hover:not(.disabled) {
  transform: translateY(-1px);
  box-shadow: var(--shadow-md);
}

.base-button:active:not(.disabled) {
  transform: translateY(0);
  box-shadow: var(--shadow-sm);
}

/* 涟漪效果 */
.base-button::after {
  content: '';
  position: absolute;
  top: 50%;
  left: 50%;
  width: 0;
  height: 0;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.3);
  transform: translate(-50%, -50%);
  transition: width 0.6s, height 0.6s;
}

.base-button:active::after {
  width: 300px;
  height: 300px;
}
</style>
```

#### 4.4 虚拟滚动

**优化大列表性能**:

```vue
<!-- frontend/src/components/base/VirtualList.vue -->
<template>
  <div
    ref="containerRef"
    class="virtual-list"
    :style="{ height: containerHeight }"
    @scroll="handleScroll"
  >
    <div
      class="virtual-list-spacer"
      :style="{ height: totalHeight + 'px' }"
    ></div>
    <div
      class="virtual-list-content"
      :style="{ transform: `translateY(${offset}px)` }"
    >
      <div
        v-for="item in visibleItems"
        :key="item.id"
        class="virtual-list-item"
        :style="{ height: itemHeight + 'px' }"
      >
        <slot :item="item" />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'

const props = defineProps({
  items: { type: Array, required: true },
  itemHeight: { type: Number, default: 60 },
  containerHeight: { type: String, default: '400px' }
})

const containerRef = ref(null)
const scrollTop = ref(0)

const totalHeight = computed(() => props.items.length * props.itemHeight)
const startIndex = computed(() => Math.floor(scrollTop.value / props.itemHeight))
const endIndex = computed(() =>
  Math.min(
    startIndex.value + Math.ceil(parseInt(props.containerHeight) / props.itemHeight) + 1,
    props.items.length
  )
)
const visibleItems = computed(() =>
  props.items.slice(startIndex.value, endIndex.value)
)
const offset = computed(() => startIndex.value * props.itemHeight)

function handleScroll(e) {
  scrollTop.value = e.target.scrollTop
}
</script>
```

---

### 阶段五：性能优化（Performance）⏱️ 1周

#### 5.1 数据更新优化

**问题**: 每次股票更新都全量刷新

**解决方案**:

```javascript
// 使用Vue的响应式系统优化
// 修改前
EventsOn("stock_price", (data) => {
  updateData(data)  // 全量更新
})

// 修改后
const stockMap = ref(new Map())

EventsOn("stock_price", (data) => {
  // 只更新变化的股票
  for (const stock of data) {
    stockMap.value.set(stock.code, {
      ...stockMap.value.get(stock.code),
      ...stock
    })
  }
  // Vue会自动只重新渲染变化的部分
})
```

#### 5.2 图表懒加载

```vue
<template>
  <div ref="chartContainerRef" v-observe-visibility="handleVisibilityChange">
    <div v-if="isVisible" ref="chartRef" :style="{ height: height }"></div>
    <SkeletonLoader v-else />
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useIntersectionObserver } from '@vueuse/core'

const chartRef = ref(null)
const chartContainerRef = ref(null)
const isVisible = ref(false)
const chartInstance = ref(null)

const { stop } = useIntersectionObserver(
  chartContainerRef,
  ([{ isIntersecting }]) => {
    if (isIntersecting && !chartInstance.value) {
      isVisible.value = true
      nextTick(() => {
        initChart()
      })
      stop()
    }
  }
)

function initChart() {
  if (!chartRef.value) return

  chartInstance.value = echarts.init(chartRef.value)
  // ... 配置图表

  // 组件卸载时销毁图表
  onBeforeUnmount(() => {
    chartInstance.value?.dispose()
  })
}
</script>
```

#### 5.3 防抖与节流

```javascript
// frontend/src/utils/performance.js
import { debounce, throttle } from 'lodash-es'

// 搜索输入防抖
export const useSearchDebounce = (callback, delay = 300) => {
  return debounce(callback, delay)
}

// 滚动事件节流
export const useScrollThrottle = (callback, delay = 100) => {
  return throttle(callback, delay)
}

// 使用
const searchStocks = useSearchDebounce((query) => {
  // API调用
}, 300)

const handleScroll = useScrollThrottle((e) => {
  // 滚动处理
}, 100)
```

#### 5.4 代码分割

```javascript
// router/index.js
const routes = [
  {
    path: '/market',
    component: () => import(/* webpackChunkName: "market" */ '@/components/market.vue')
  },
  {
    path: '/agent',
    component: () => import(/* webpackChunkName: "agent" */ '@/components/agent-chat.vue')
  }
]
```

---

### 阶段六：响应式与适配（Responsive）⏱️ 1周

#### 6.1 断点系统

```css
/* frontend/src/styles/breakpoints.css */

:root {
  /* 断点定义 */
  --breakpoint-xs: 375px;   /* 小型手机 */
  --breakpoint-sm: 640px;   /* 手机 */
  --breakpoint-md: 768px;   /* 平板 */
  --breakpoint-lg: 1024px;  /* 桌面 */
  --breakpoint-xl: 1280px;  /* 大屏 */
  --breakpoint-2xl: 1536px; /* 超大屏 */
}

/* 媒体查询混入（需要CSS预处理器或Tailwind） */
@media (min-width: 768px) {
  /* 平板及以上 */
}

@media (min-width: 1024px) {
  /* 桌面及以上 */
}
```

#### 6.2 弹性布局

```vue
<!-- 响应式网格布局 -->
<template>
  <div class="responsive-grid">
    <div class="grid-item" v-for="item in items" :key="item.id">
      {{ item }}
    </div>
  </div>
</template>

<style scoped>
.responsive-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: var(--spacing-4);
}

@media (max-width: 768px) {
  .responsive-grid {
    grid-template-columns: repeat(auto-fill, minmax(100%, 1fr));
    gap: var(--spacing-2);
  }
}
</style>
```

#### 6.3 窗口大小监听

```javascript
// frontend/src/composables/useBreakpoint.js
import { ref, onMounted, onUnmounted } from 'vue'

export function useBreakpoint() {
  const windowWidth = ref(window.innerWidth)
  const windowHeight = ref(window.innerHeight)

  const breakpoint = computed(() => {
    if (windowWidth.value < 640) return 'xs'
    if (windowWidth.value < 768) return 'sm'
    if (windowWidth.value < 1024) return 'md'
    if (windowWidth.value < 1280) return 'lg'
    return 'xl'
  })

  function handleResize() {
    windowWidth.value = window.innerWidth
    windowHeight.value = window.innerHeight
  }

  onMounted(() => {
    window.addEventListener('resize', handleResize)
  })

  onUnmounted(() => {
    window.removeEventListener('resize', handleResize)
  })

  return {
    windowWidth,
    windowHeight,
    breakpoint,
    isMobile: computed(() => ['xs', 'sm'].includes(breakpoint.value)),
    isTablet: computed(() => breakpoint.value === 'md'),
    isDesktop: computed(() => ['lg', 'xl'].includes(breakpoint.value))
  }
}
```

---

### 阶段七：可访问性改进（Accessibility）⏱️ 1周

#### 7.1 键盘导航

```vue
<!-- 可键盘操作的股票列表 -->
<template>
  <ul
    ref="listRef"
    class="stock-list"
    role="listbox"
    @keydown="handleKeydown"
  >
    <li
      v-for="(stock, index) in stocks"
      :key="stock.code"
      :ref="el => setItemRef(el, index)"
      class="stock-item"
      :class="{ 'focused': focusedIndex === index }"
      role="option"
      :aria-selected="focusedIndex === index"
      :tabindex="focusedIndex === index ? 0 : -1"
      @click="selectStock(stock)"
    >
      {{ stock.name }}
    </li>
  </ul>
</template>

<script setup>
const focusedIndex = ref(0)
const itemRefs = ref([])

function setItemRef(el, index) {
  if (el) itemRefs.value[index] = el
}

function handleKeydown(e) {
  switch (e.key) {
    case 'ArrowDown':
      e.preventDefault()
      focusedIndex.value = Math.min(focusedIndex.value + 1, stocks.value.length - 1)
      itemRefs.value[focusedIndex.value]?.focus()
      break
    case 'ArrowUp':
      e.preventDefault()
      focusedIndex.value = Math.max(focusedIndex.value - 1, 0)
      itemRefs.value[focusedIndex.value]?.focus()
      break
    case 'Enter':
      e.preventDefault()
      selectStock(stocks.value[focusedIndex.value])
      break
  }
}
</script>
```

#### 7.2 ARIA标签

```vue
<!-- 带ARIA标签的股票卡片 -->
<template>
  <article
    class="stock-card"
    :aria-label="`股票 ${stock.name} 代码 ${stock.code}`"
  >
    <header class="card-header">
      <h3>{{ stock.name }}</h3>
      <span class="stock-code" aria-label="股票代码">{{ stock.code }}</span>
    </header>

    <div class="card-body">
      <div class="price" aria-live="polite">
        <span class="label">当前价格</span>
        <span class="value">{{ stock.price }}</span>
      </div>

      <div
        class="change"
        :class="{ 'up': stock.change > 0, 'down': stock.change < 0 }"
        :aria-label="stock.change > 0 ? '上涨' : '下跌'"
      >
        <span class="label">涨跌幅</span>
        <span class="value">{{ stock.changePercent }}%</span>
      </div>
    </div>
  </article>
</template>
```

#### 7.3 焦点管理

```javascript
// frontend/src/composables/useFocusTrap.js
import { ref, watch, onMounted } from 'vue'

export function useFocusTrap(containerRef) {
  const focusableElements = ref([])
  const firstElement = ref(null)
  const lastElement = ref(null)

  function updateFocusableElements() {
    if (!containerRef.value) return

    const selector = [
      'a[href]',
      'button:not([disabled])',
      'textarea:not([disabled])',
      'input:not([disabled])',
      'select:not([disabled])',
      '[tabindex]:not([tabindex="-1"])'
    ].join(', ')

    focusableElements.value = Array.from(
      containerRef.value.querySelectorAll(selector)
    )

    firstElement.value = focusableElements.value[0]
    lastElement.value = focusableElements.value[focusableElements.value.length - 1]
  }

  function handleKeydown(e) {
    if (e.key !== 'Tab') return

    if (e.shiftKey) {
      // Shift + Tab
      if (document.activeElement === firstElement.value) {
        e.preventDefault()
        lastElement.value?.focus()
      }
    } else {
      // Tab
      if (document.activeElement === lastElement.value) {
        e.preventDefault()
        firstElement.value?.focus()
      }
    }
  }

  onMounted(() => {
    updateFocusableElements()
    containerRef.value?.addEventListener('keydown', handleKeydown)
  })

  return {
    focusableElements,
    updateFocusableElements
  }
}
```

---

### 阶段八：测试与优化（Testing）⏱️ 1周

#### 8.1 视觉回归测试

使用工具: Percy或Chromatic

```bash
npm install -D @percy/cli @percly/playwright
```

```javascript
// e2e/visual-regs.spec.js
import { test, expect } from '@playwright/test'

test('股票列表视觉回归', async ({ page }) => {
  await page.goto('http://localhost:5173')
  await page.waitForSelector('.stock-list')

  // 截图并与基线对比
  await expect(page).toHaveScreenshot('stock-list.png')
})
```

#### 8.2 性能测试

```javascript
// e2e/performance.spec.js
import { test, expect } from '@playwright/test'

test('页面加载性能', async ({ page }) => {
  const startTime = Date.now()

  await page.goto('http://localhost:5173')

  // 等待页面完全加载
  await page.waitForLoadState('networkidle')

  const loadTime = Date.now() - startTime

  // 首屏加载时间应小于2秒
  expect(loadTime).toBeLessThan(2000)

  // Web Vitals检查
  const metrics = await page.evaluate(() => {
    return new Promise((resolve) => {
      new PerformanceObserver((list) => {
        const entries = list.getEntries()
        const lcp = entries.find(entry => entry.entryType === 'largest-contentful-paint')
        resolve({ lcp: lcp?.renderTime || 0 })
      }).observe({ entryTypes: ['largest-contentful-paint'] })
    })
  })

  // LCP应小于2.5秒
  expect(metrics.lcp).toBeLessThan(2500)
})
```

#### 8.3 可访问性测试

```javascript
// e2e/accessibility.spec.js
import { test, expect } from '@playwright/test'
import AxeBuilder from '@axe-core/playwright'

test('可访问性检查', async ({ page }) => {
  await page.goto('http://localhost:5173')

  const accessibilityScanResults = await new AxeBuilder({ page })
    .include('.stock-list')
    .withTags(['wcag2a', 'wcag2aa', 'wcag21aa'])
    .analyze()

  expect(accessibilityScanResults.violations).toEqual([])
})
```

---

## 📦 实施路线图

### 总时间: 10周

```
Week 1-2:  阶段一 - 设计系统重构
           ├─ 建立设计令牌系统
           ├─ 配置Tailwind CSS（可选）
           └─ 统一组件库主题

Week 3-4:  阶段二 - 信息架构重构 + 阶段三（第1周）
           ├─ 扁平化导航结构
           ├─ 页面布局重组
           └─ 组件拆分

Week 5-6:  阶段三 - 视觉设计优化
           ├─ 颜色可访问性
           ├─ 卡片式设计
           ├─ 数据可视化
           └─ 深色模式

Week 7:    阶段四 - 交互体验提升
           ├─ 加载状态
           ├─ 过渡动画
           ├─ 微交互
           └─ 虚拟滚动

Week 8:    阶段五 - 性能优化
           ├─ 数据更新优化
           ├─ 图表懒加载
           ├─ 防抖节流
           └─ 代码分割

Week 9:    阶段六 - 响应式与适配
           ├─ 断点系统
           ├─ 弹性布局
           └─ 窗口监听

Week 10:   阶段七 - 可访问性改进 + 阶段八 - 测试
           ├─ 键盘导航
           ├─ ARIA标签
           ├─ 焦点管理
           └─ 全面测试
```

---

## 🎨 设计规范示例

### 组件库结构

```
frontend/src/components/
├── base/                    # 基础组件
│   ├── BaseButton.vue
│   ├── BaseCard.vue
│   ├── BaseInput.vue
│   ├── BaseModal.vue
│   ├── BaseTable.vue
│   └── SkeletonLoader.vue
├── layout/                  # 布局组件
│   ├── AppHeader.vue
│   ├── AppSidebar.vue
│   ├── AppFooter.vue
│   └── InfoPanel.vue
├── stock/                   # 股票相关
│   ├── StockList.vue
│   ├── StockCard.vue
│   ├── StockDetailPanel.vue
│   ├── KLineChart.vue
│   └── index.vue
├── market/                  # 市场相关
│   ├── NewsList.vue
│   ├── RankTable.vue
│   └── ...
└── shared/                  # 共享组件
    ├── SearchBar.vue
    ├── FilterBar.vue
    └── Tabs.vue
```

---

## 📊 成功指标

### 定量指标
- [ ] 首屏加载时间 < 2秒
- [ ] 交互响应时间 < 100ms
- [ ] Lighthouse性能分数 > 90
- [ ] 可访问性评分 > 95
- [ ] 代码重复率降低 30%
- [ ] 组件平均行数 < 300行

### 定性指标
- [ ] 视觉风格统一
- [ ] 信息层次清晰
- [ ] 交互反馈及时
- [ ] 学习曲线降低
- [ ] 用户满意度提升

---

## 🚀 下一步行动

1. **评审本计划** - 与团队讨论确认改造方向
2. **创建设计系统仓库** - 独立管理设计令牌和基础组件
3. **设置Storybook** - 组件文档和展示
4. **建立Figma设计系统** - 设计与开发同步
5. **开始阶段一实施** - 设计令牌系统搭建

---

## 📝 附录

### A. 参考资源

- **shadcn/ui**: https://ui.shadcn.com/
- **Naive UI**: https://www.naiveui.com/
- **OKX官网**: https://www.okx.com/
- **Web无障碍指南**: https://www.w3.org/WAI/WCAG21/quickref/
- **Vue性能优化**: https://vuejs.org/guide/best-practices/performance.html

### B. 工具推荐

- **设计**: Figma, Sketch
- **原型**: Figma, Adobe XD
- **图标**: Iconify, Lucide Icons
- **颜色**: Coolors, Adobe Color
- **测试**: Playwright, Vitest
- **性能**: Lighthouse, WebPageTest
- **可访问性**: axe DevTools, WAVE

### C. 迁移检查清单

#### 阶段一检查清单
- [ ] 创建design-tokens.css
- [ ] 定义所有颜色变量
- [ ] 定义所有间距变量
- [ ] 定义字体系统
- [ ] 替换硬编码颜色
- [ ] 配置Naive UI主题
- [ ] 创建基础Button组件
- [ ] 创建基础Card组件

#### 阶段二检查清单
- [ ] 重组导航菜单
- [ ] 创建三栏布局
- [ ] 拆分stock.vue组件
- [ ] 创建StockList组件
- [ ] 创建StockCard组件
- [ ] 创建StockDetailPanel组件

#### 阶段三检查清单
- [ ] 实现涨跌图标辅助
- [ ] 添加色盲友好模式
- [ ] 创建卡片样式
- [ ] 定制ECharts主题
- [ ] 优化深色主题
- [ ] 测试颜色对比度

#### 阶段四检查清单
- [ ] 创建骨架屏组件
- [ ] 添加页面过渡动画
- [ ] 实现按钮涟漪效果
- [ ] 添加加载状态
- [ ] 实现虚拟滚动

#### 阶段五检查清单
- [ ] 优化数据更新逻辑
- [ ] 实现图表懒加载
- [ ] 添加防抖节流
- [ ] 配置代码分割
- [ ] 性能测试

#### 阶段六检查清单
- [ ] 定义断点系统
- [ ] 实现弹性网格
- [ ] 添加窗口监听
- [ ] 响应式测试

#### 阶段七检查清单
- [ ] 实现键盘导航
- [ ] 添加ARIA标签
- [ ] 实现焦点陷阱
- [ ] 可访问性测试

#### 阶段八检查清单
- [ ] 设置视觉回归测试
- [ ] 性能测试
- [ ] 可访问性自动化测试
- [ ] 用户验收测试

---

**文档版本**: v1.0
**创建日期**: 2025-01-17
**最后更新**: 2025-01-17
**作者**: Claude AI
**项目**: Lumos Stock UI改造计划

---

## 💡 关键设计原则总结

1. **一致性优先** - 统一的设计语言和组件
2. **性能为王** - 快速响应和流畅体验
3. **可访问性必备** - 所有人都能使用
4. **渐进增强** - 基础功能到高级特性
5. **数据驱动** - 股票数据清晰展示
6. **专业可信** - 交易所级别的设计质量
7. **响应式设计** - 适配各种屏幕尺寸
8. **持续迭代** - 小步快跑，快速验证

---

*本计划书为Lumos Stock项目的UI/UX改造提供全面的技术路线和实施方案。建议分阶段执行，每个阶段完成后进行评估和调整。*

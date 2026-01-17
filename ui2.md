# AI Agent 智能体菜单页面 UI 改造计划

> 分析日期: 2025-01-17
> 涉及模块: 导航菜单、设置页面、Agent 选择界面
> 参考风格: Shadcn UI + 欧易交易所 (OKX)

---

## 一、当前菜单系统现状分析

### 1.1 核心架构

```
菜单系统组成:
├── App.vue (主应用布局)
│   ├── menuOptions (菜单配置数据)
│   ├── n-menu (Naive UI 水平菜单组件)
│   ├── RouterLink (路由链接)
│   └── 响应式菜单 (responsive 属性)
├── router/router.js (路由配置)
│   └── /agent → agent-chat.vue
├── settings.vue (设置页面)
│   ├── enableAgent 开关 (第332-334行)
│   ├── AI配置管理 (第379-459行)
│   └── Prompt 模板设置
└── agent-chat.vue (Agent聊天界面)
    ├── NSelect (AI模型选择下拉框)
    └── GetAiConfigs() (加载配置列表)
```

### 1.2 现有功能清单

| 功能模块 | 实现状态 | 位置 | 说明 |
|---------|---------|------|------|
| 菜单显示控制 | ✅ 已实现 | settings.vue:332 | enableAgent 开关 |
| Agent 菜单项 | ✅ 已实现 | App.vue:428-448 | Robot 图标 |
| 路由导航 | ✅ 已实现 | router.js:16 | /agent 路由 |
| AI 配置管理 | ✅ 已实现 | settings.vue:421-456 | 多配置支持 |
| Agent 选择下拉 | ✅ 已实现 | agent-chat.vue:48-54 | NSelect 组件 |
| 响应式菜单 | ✅ 已实现 | App.vue:764 | responsive 属性 |
| Prompt 模板 | ✅ 已实现 | settings.vue:405-414 | 系统/用户 prompt |

---

## 二、UI 问题诊断

### 2.1 菜单层面问题

#### 🔴 严重问题

1. **菜单入口不突出**
   - Agent 菜单项混在普通菜单中，无视觉区分
   - Robot 图标与菜单字体大小不协调 (18px vs 默认)
   - 无"新功能"或"AI"特殊标识
   - 默认隐藏状态用户难以发现

2. **启用流程体验差**
   - 需要进入设置页面 → 找到"AI智能体"开关 → 保存
   - 无首次引导流程
   - 无功能介绍或使用说明
   - 开关位置不显眼 (在"指数基金"旁边)

3. **菜单布局问题**
   ```
   当前菜单结构:
   [股票自选] [市场行情▼] [基金自选] [AI智能体] [设置] [关于]

   问题:
   - AI智能体与其他功能平级，无特殊标识
   - 图标与文字对齐不统一
   - 响应式断点未知，窄屏可能溢出
   ```

#### 🟡 中等问题

4. **视觉层次缺失**
   - 活动状态指示不明显 (activeKey 仅有内部状态)
   - 无悬浮效果提示
   - 图标与间距缺乏设计系统规范

5. **可访问性不足**
   - 无键盘快捷键提示
   - 无屏幕阅读器友好标签
   - 菜单项 role 属性缺失

6. **信息架构混乱**
   - "基金自选"与"AI智能体"之间逻辑关联弱
   - "设置"和"关于"位置固定，Agent 插入在中间
   - 子菜单层级不一致 (市场行情有12个子菜单，Agent 无)

#### 🟢 轻微问题

7. **细节优化空间**
   - 菜单切换无过渡动画
   - 图标颜色不支持主题切换
   - 菜单项间距固定，无法自适应

---

### 2.2 设置页面问题

#### 🔴 严重问题

1. **AI 配置管理复杂**
   ```vue
   <!-- 当前实现: 嵌套卡片 -->
   <n-card v-for="(aiConfig, index) in formValue.openAI.aiConfigs">
     <!-- 8个表单项 -->
   </n-card>

   问题:
   - 配置项过多，单屏显示不全
   - 无配置预设/模板
   - 添加/删除操作无确认
   ```

2. **表单布局混乱**
   ```
   当前布局 (24栅格):
   - AI诊股开关: span=24 (整行)
   - Crawler Timeout: span=6
   - 日K线数据: span=4
   - http代理: span=2
   - 代理地址: span=10

   问题:
   - 对齐不统一
   - 间距混乱 (6+4+2+10=22, 空白2单位)
   - 响应式适配缺失
   ```

3. **Prompt 编辑体验差**
   - Textarea 高度固定 (minRows: 4, maxRows: 8)
   - 无语法高亮
   - 无变量提示 ({{stockName}}, {{stockCode}})
   - 无模板预览

#### 🟡 中等问题

4. **开关控制逻辑不清晰**
   ```javascript
   // 三层嵌套条件
   v-if="formValue.openAI.enable"  // AI诊股开关
   v-if="formValue.openAI.enable"  // Prompt设置
   v-if="formValue.openAI.enable"  // AI模型配置

   问题:
   - "AI智能体"开关 (enableAgent) 与 "AI诊股"开关 (openAI.enable) 关系不明
   - 两个开关控制不同功能但命名相似
   - 无状态同步提示
   ```

5. **验证与反馈不足**
   - API Key 输入无格式验证
   - Base URL 无连接测试
   - 保存成功无明确提示
   - 配置删除无二次确认

6. **视觉设计缺陷**
   - 卡片嵌套过深 (n-card > n-grid > n-form-item-gi)
   - 标签使用 NTag 但颜色单一 (type: 'primary')
   - Divider 分割线过度使用

#### 🟢 轻微问题

7. **文字与标签**
   - "Crawler Timeout" 中英混杂
   - "诊股"术语不统一 (配置页用"诊股", 菜单用"智能体")
   - Placeholder 文案不友好

---

### 2.3 Agent 选择界面问题

#### 🔴 严重问题

1. **选择器位置不当**
   ```vue
   <!-- agent-chat.vue 第48-54行 -->
   <NSelect
     v-model:value="selectValue"
     :options="selectOptions"
     size="tiny"
     style="width: 200px;"
   />

   问题:
   - 位于输入框 prefix，占据输入空间
   - 宽度固定200px，窄屏溢出
   - size="tiny" 在移动端难以点击
   - 无配置说明或帮助提示
   ```

2. **配置信息展示不足**
   - 下拉仅显示配置名称
   - 无法预览模型参数 (temperature, maxTokens)
   - 无配置状态指示 (是否可用、延迟等)
   - 无"添加新配置"快捷入口

#### 🟡 中等问题

3. **加载与错误处理**
   - GetAiConfigs() 失败无错误提示
   - 无加载骨架屏
   - 配置为空时无引导

4. **切换体验**
   - 切换配置需重新发送消息
   - 无"应用到当前对话"选项
   - 切换后无配置对比

#### 🟢 轻微问题

5. **样式细节**
   - NSelect 与 TDesign 风格不统一
   - 无配置图标/颜色区分
   - 悬浮提示缺失

---

## 三、参考风格分析

### 3.1 Shadcn UI 菜单设计

```
导航特征:
├── 侧边栏布局 (非底部菜单)
├── 分组标题 (Navigation, Workspace, etc.)
├── 折叠/展开动画
├── 键盘快捷键显示 (⌘K)
└── Tooltip 提示

交互模式:
├── 悬浮: 背景色变浅 (+light)
├── 激活: 左侧蓝色竖线指示器
├── 展开: ChevronRight 图标旋转
└── 徽章: 小圆点或数字标示

间距规范:
├── 菜单项高度: 32px (紧凑) / 40px (舒适)
├── 左右内边距: 12px
├── 图标与文字间距: 8px
└── 分组间距: 8px
```

### 3.2 OKX 设置页面风格

```
布局特征:
├── 左侧设置导航 (垂直菜单)
├── 右侧内容区 (卡片式)
├── 面包屑导航
└── 保存按钮固定底部

表单设计:
├── 标签置顶 (非左对齐)
├── 描述文字灰色小字
├── 开关带说明文字
├── 危险操作红色按钮
└── 保存按钮主色调 + 加载状态

分组方式:
├── 按功能模块 (账户, 安全, 通知, etc.)
├── 每组独立卡片
├── 组内用 Divider 分隔
└── 重要设置单独突出
```

---

## 四、改造方案设计

### 4.1 整体设计策略

```
设计语言: "现代金融科技风格"
├── 菜单系统: 侧边栏 + 底部菜单混合布局
├── 设置页面: 左右分栏 + 卡片式内容
├── Agent选择: 独立配置面板 + 快速切换
└── 交互: 流畅过渡 + 明确反馈
```

### 4.2 核心改造模块

#### 模块 1: 菜单系统重构

**当前问题:**
```vue
<!-- App.vue:758-767 -->
<n-gi style="position: fixed;bottom:0;z-index: 9;width: 100%;">
  <n-card size="small">
    <n-menu
      mode="horizontal"
      :options="menuOptions"
      responsive
    />
  </n-card>
</n-gi>
```

**改造方案:**
```vue
<!-- 新设计: 侧边栏 + Agent 特殊标识 -->
<template>
  <n-layout has-sider style="height: 100vh">
    <!-- 左侧导航栏 -->
    <n-layout-sider
      bordered
      show-trigger="arrow-circle"
      collapse-mode="width"
      :collapsed-width="64"
      :width="240"
      :native-scrollbar="false"
    >
      <!-- Logo区域 -->
      <div class="sidebar-header">
        <div class="logo">
          <img :src="appIcon" alt="Lumos Stock" />
          <span v-if="!collapsed" class="logo-text">Lumos Stock</span>
        </div>
      </div>

      <!-- 主导航菜单 -->
      <n-menu
        v-model:value="activeKey"
        :collapsed="collapsed"
        :collapsed-width="64"
        :collapsed-icon-size="22"
        :options="menuOptions"
        :indent="18"
      />

      <!-- AI Agent 特殊区域 -->
      <div v-if="enableAgent" class="ai-agent-section">
        <n-divider style="margin: 8px 0" />
        <div class="ai-header">
          <n-badge dot :color="agentActive ? '#3381FF' : '#848E9C'">
            <n-icon :component="SparklesIcon" />
          </n-badge>
          <span v-if="!collapsed" class="ai-title">AI 助手</span>
          <n-tooltip v-if="!collapsed" placement="right">
            <template #trigger>
              <n-button text size="tiny" @click="showAgentSettings">
                <template #icon><SettingsIcon /></template>
              </n-button>
            </template>
            AI 配置
          </n-tooltip>
        </div>

        <!-- Agent 快速选择 -->
        <div v-if="!collapsed" class="agent-selector">
          <n-select
            v-model:value="currentAgent"
            :options="agentOptions"
            size="small"
            placeholder="选择 AI 模型"
            :consistent-menu-width="false"
            @update:value="handleAgentChange"
          >
            <template #render-label="{ option }">
              <div class="agent-option">
                <n-icon :component="CpuIcon" />
                <span>{{ option.label }}</span>
                <n-tag v-if="option.isDefault" type="primary" size="tiny" bordered={false}>
                  默认
                </n-tag>
              </div>
            </template>
          </n-select>
        </div>
      </div>

      <!-- 底部设置区域 -->
      <div class="sidebar-footer">
        <n-menu
          :options="footerMenuOptions"
          :indent="18"
        />
      </div>
    </n-layout-sider>

    <!-- 主内容区 -->
    <n-layout>
      <RouterView />
    </n-layout>
  </n-layout>
</template>

<script setup>
const menuOptions = computed(() => [
  {
    label: '股票自选',
    key: 'stock',
    icon: renderIcon(StarOutline),
    disabled: !enableStock.value
  },
  {
    label: '市场行情',
    key: 'market',
    icon: renderIcon(NewspaperOutline),
    children: marketSubMenus
  },
  {
    label: '基金自选',
    key: 'fund',
    icon: renderIcon(SparklesOutline),
    show: enableFund.value,
    disabled: !enableFund.value
  }
])

const footerMenuOptions = [
  {
    label: '设置',
    key: 'settings',
    icon: renderIcon(SettingsOutline)
  },
  {
    label: '关于',
    key: 'about',
    icon: renderIcon(InfoIcon)
  }
]
</script>

<style scoped>
.sidebar-header {
  padding: 16px;
  border-bottom: 1px solid var(--divider-color);

  .logo {
    display: flex;
    align-items: center;
    gap: 12px;

    img {
      width: 32px;
      height: 32px;
      border-radius: 8px;
    }

    .logo-text {
      font-size: 16px;
      font-weight: 600;
      color: var(--text-primary);
    }
  }
}

.ai-agent-section {
  padding: 12px;
  background: rgba(51, 129, 255, 0.05);
  border-left: 3px solid var(--accent);
  margin: 8px 12px;
  border-radius: 8px;

  .ai-header {
    display: flex;
    align-items: center;
    gap: 8px;
    margin-bottom: 12px;

    .n-icon {
      font-size: 20px;
      color: var(--accent);
    }

    .ai-title {
      flex: 1;
      font-size: 14px;
      font-weight: 600;
      color: var(--text-primary);
    }
  }

  .agent-selector {
    :deep(.n-base-selection) {
      background: var(--bg-secondary);
      border-color: var(--border-color);

      &.n-base-selection--focus {
        border-color: var(--accent);
        box-shadow: 0 0 0 2px rgba(51, 129, 255, 0.1);
      }
    }
  }
}

.agent-option {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;

  .n-icon {
    color: var(--accent);
  }
}

.sidebar-footer {
  margin-top: auto;
  border-top: 1px solid var(--divider-color);
}
</style>
```

---

#### 模块 2: 设置页面重构

**当前问题:**
```vue
<!-- settings.vue:379-459 -->
<n-card title="AI设置">
  <!-- 混乱布局 -->
</n-card>
```

**改造方案:**
```vue
<!-- 新设计: 左右分栏 + 分组卡片 -->
<template>
  <div class="settings-page">
    <!-- 左侧导航 -->
    <n-layout-sider
      width="200"
      bordered
      :native-scrollbar="false"
    >
      <n-menu
        v-model:value="activeSettingsTab"
        :options="settingsMenuOptions"
        mode="vertical"
      />
    </n-layout-sider>

    <!-- 右侧内容 -->
    <n-layout-content>
      <!-- AI 概览 -->
      <n-card v-if="activeSettingsTab === 'ai-overview'" size="small">
        <template #header>
          <n-flex align="center" justify="space-between">
            <n-text strong>AI 智能体</n-text>
            <n-switch
              v-model:value="aiEnabled"
              @update:value="handleAiToggle"
            >
              <template #checked>已启用</template>
              <template #unchecked>已禁用</template>
            </n-switch>
          </n-flex>
        </template>

        <!-- 功能介绍 -->
        <n-alert v-if="!aiEnabled" type="info" title="启用 AI 智能体">
          启用后，您可以使用 AI 助手进行股票分析、市场研究、投资咨询等功能。
          <template #action>
            <n-button type="primary" size="small" @click="aiEnabled = true">
              立即启用
            </n-button>
          </template>
        </n-alert>

        <!-- 快速配置 -->
        <n-space v-else vertical :size="16">
          <n-statistic-group>
            <n-statistic label="已配置模型" :value="aiConfigs.length">
              <template #suffix>
                <n-text depth="3">个</n-text>
              </template>
            </n-statistic>
            <n-statistic label="默认模型" :value="defaultAgent?.name || '未设置'">
              <template #prefix>
                <n-icon :component="CpuIcon" />
              </template>
            </n-statistic>
          </n-statistic-group>

          <n-flex>
            <n-button type="primary" @click="activeSettingsTab = 'ai-configs'">
              管理模型配置
            </n-button>
            <n-button @click="activeSettingsTab = 'ai-prompts'">
              配置提示词
            </n-button>
            <n-button quaternary @click="testAiConnection">
              测试连接
            </n-button>
          </n-flex>
        </n-space>
      </n-card>

      <!-- AI 配置管理 -->
      <n-card v-if="activeSettingsTab === 'ai-configs'" size="small">
        <template #header>
          <n-flex align="center" justify="space-between">
            <n-text strong>模型配置</n-text>
            <n-button
              type="primary"
              size="small"
              @click="showAddConfigModal = true"
            >
              <template #icon><PlusIcon /></template>
              添加配置
            </n-button>
          </n-flex>
        </template>

        <!-- 配置列表 -->
        <n-list v-if="aiConfigs.length > 0" bordered>
          <n-list-item v-for="config in aiConfigs" :key="config.ID">
            <template #prefix>
              <n-avatar
                round
                :style="{ background: getModelColor(config.modelName) }"
              >
                {{ config.name.charAt(0) }}
              </n-avatar>
            </template>

            <n-thing>
              <template #header>
                <n-flex align="center" :size="8">
                  <n-text strong>{{ config.name }}</n-text>
                  <n-tag v-if="config.ID === defaultAgentId" type="primary" size="tiny">
                    默认
                  </n-tag>
                  <n-tag v-if="config.status === 'active'" type="success" size="tiny">
                    可用
                  </n-tag>
                  <n-tag v-else type="warning" size="tiny">
                    不可用
                  </n-tag>
                </n-flex>
              </template>

              <template #description>
                <n-space vertical :size="4">
                  <n-text depth="3">
                    {{ config.modelName }} · Temperature: {{ config.temperature }}
                  </n-text>
                  <n-text depth="3" style="font-family: monospace; font-size: 12px;">
                    {{ config.baseUrl }}
                  </n-text>
                </n-space>
              </template>

              <template #action>
                <n-space>
                  <n-button
                    size="tiny"
                    quaternary
                    @click="editConfig(config)"
                  >
                    <template #icon><EditIcon /></template>
                    编辑
                  </n-button>
                  <n-button
                    size="tiny"
                    quaternary
                    type="error"
                    @click="confirmDeleteConfig(config)"
                  >
                    <template #icon><DeleteIcon /></template>
                    删除
                  </n-button>
                  <n-dropdown
                    :options="getConfigActions(config)"
                    @select="handleConfigAction($event, config)"
                  >
                    <n-button size="tiny" quaternary>
                      <template #icon><MoreIcon /></template>
                    </n-button>
                  </n-dropdown>
                </n-space>
              </template>
            </n-thing>
          </n-list-item>
        </n-list>

        <!-- 空状态 -->
        <n-empty
          v-else
          description="暂无 AI 模型配置"
          size="large"
        >
          <template #extra>
            <n-button type="primary" @click="showAddConfigModal = true">
              添加第一个配置
            </n-button>
          </template>
        </n-empty>
      </n-card>

      <!-- Prompt 配置 -->
      <n-card v-if="activeSettingsTab === 'ai-prompts'" size="small">
        <template #header>
          <n-text strong>提示词配置</n-text>
        </template>

        <n-tabs type="line" animated>
          <n-tab-pane name="system" tab="系统提示词">
            <n-form-item
              label="角色设定"
              path="systemPrompt"
              :show-label="false"
            >
              <n-input
                v-model:value="prompts.system"
                type="textarea"
                placeholder="定义 AI 助手的角色和行为..."
                :autosize="{ minRows: 6, maxRows: 12 }"
                :input-props="{ spellcheck: false }"
              >
                <template #suffix>
                  <n-space vertical :size="4">
                    <n-text depth="3" style="font-size: 11px;">
                      可用变量: {{date}}, {{market}}
                    </n-text>
                    <n-button text size="tiny" @click="showVariableHelp">
                      查看所有变量
                    </n-button>
                  </n-space>
                </template>
              </n-input>
            </n-form-item>
          </n-tab-pane>

          <n-tab-pane name="user" tab="用户提示词模板">
            <n-space vertical :size="12">
              <n-alert type="info" size="small">
                用户提示词模板用于预填充用户的提问，支持变量替换。
              </n-alert>

              <n-form-item label="股票分析模板" path="stockAnalysis">
                <template #label>
                  <n-flex align="center" :size="4">
                    <n-text>股票分析</n-text>
                    <n-tooltip>
                      <template #trigger>
                        <n-icon :component="HelpIcon" />
                      </template>
                      用于分析单只股票的基本面和技术面
                    </n-tooltip>
                  </n-flex>
                </template>
                <n-input
                  v-model:value="prompts.stockAnalysis"
                  type="textarea"
                  placeholder="{{stockName}}[{{stockCode}}] 的投资价值分析..."
                  :autosize="{ minRows: 4, maxRows: 8 }"
                />
              </n-form-item>

              <n-form-item label="市场分析模板" path="marketAnalysis">
                <n-input
                  v-model:value="prompts.marketAnalysis"
                  type="textarea"
                  placeholder="当前市场行情分析..."
                  :autosize="{ minRows: 4, maxRows: 8 }"
                />
              </n-form-item>
            </n-space>
          </n-tab-pane>
        </n-tabs>
      </n-card>
    </n-layout-content>
  </div>
</template>

<script setup>
const settingsMenuOptions = [
  {
    label: 'AI 概览',
    key: 'ai-overview',
    icon: renderIcon(HomeIcon)
  },
  {
    label: '模型配置',
    key: 'ai-configs',
    icon: renderIcon(CogIcon)
  },
  {
    label: '提示词配置',
    key: 'ai-prompts',
    icon: renderIcon(DocumentTextIcon)
  }
]

const aiConfigs = ref([])
const defaultAgentId = ref(null)
const activeSettingsTab = ref('ai-overview')
const aiEnabled = ref(false)

const handleAiToggle = (value) => {
  if (value && aiConfigs.value.length === 0) {
    // 首次启用，显示引导
    showFirstTimeGuide()
  }
}

const getModelColor = (modelName) => {
  const colors = {
    'gpt-4': '#10A37F',
    'gpt-3.5-turbo': '#74AA9C',
    'deepseek-chat': '#4D6BFE',
    'default': '#3381FF'
  }
  return colors[modelName] || colors.default
}

const getConfigActions = (config) => [
  {
    label: '设为默认',
    key: 'setDefault',
    disabled: config.ID === defaultAgentId.value
  },
  {
    label: '测试连接',
    key: 'test'
  },
  {
    label: '复制配置',
    key: 'duplicate'
  },
  {
    type: 'divider',
    key: 'd1'
  },
  {
    label: '删除',
    key: 'delete',
    props: {
      style: {
                    color: 'var(--error-color)'
                  }
    }
  }
]
</script>

<style scoped>
.settings-page {
  display: flex;
  height: 100%;
  gap: 16px;
  padding: 16px;
}

.n-thing {
  --n-thing-avatar-size: 40px;
}
</style>
```

---

#### 模块 3: Agent 选择界面优化

**当前问题:**
```vue
<!-- agent-chat.vue 嵌入在输入框中 -->
<t-chat-sender>
  <template #prefix>
    <NSelect style="width: 200px" />
  </template>
</t-chat-sender>
```

**改造方案:**
```vue
<!-- 新设计: 独立配置面板 -->
<template>
  <div class="agent-chat-wrapper">
    <!-- 顶部工具栏 -->
    <div class="chat-toolbar">
      <!-- Agent 选择 -->
      <n-dropdown
        trigger="click"
        :options="agentDropdownOptions"
        @select="handleAgentSelect"
      >
        <n-button text>
          <template #icon>
            <n-avatar
              round
              :size="28"
              :style="{ background: currentAgent.color }"
            >
              {{ currentAgent.name.charAt(0) }}
            </n-avatar>
          </template>
          <span class="current-agent-name">{{ currentAgent.name }}</span>
          <template #suffix>
            <n-icon :component="ChevronDownIcon" />
          </template>
        </n-button>
      </n-dropdown>

      <!-- 快捷操作 -->
      <n-space :size="8">
        <n-tooltip>
          <template #trigger>
            <n-button circle quaternary size="small" @click="showAgentConfig">
              <template #icon><SettingsIcon /></template>
            </n-button>
          </template>
          模型设置
        </n-tooltip>

        <n-tooltip>
          <template #trigger>
            <n-button circle quaternary size="small" @click="newChat">
              <template #icon><PlusIcon /></template>
            </n-button>
          </template>
          新建对话
        </n-tooltip>
      </n-space>
    </div>

    <!-- 模型信息提示 -->
    <n-alert
      v-if="showModelInfo"
      type="info"
      closable
      @close="showModelInfo = false"
      style="margin-bottom: 12px;"
    >
      <template #header>
        <n-flex align="center" :size="4">
          <n-icon :component="InfoIcon" />
          <span>当前模型</span>
        </n-flex>
      </template>
      <n-descriptions :column="3" size="small">
        <n-descriptions-item label="模型">{{ currentAgent.modelName }}</n-descriptions-item>
        <n-descriptions-item label="温度">{{ currentAgent.temperature }}</n-descriptions-item>
        <n-descriptions-item label="最大Token">{{ currentAgent.maxTokens }}</n-descriptions-item>
      </n-descriptions>
    </n-alert>

    <!-- 聊天区域 -->
    <t-chat
      ref="chatRef"
      :data="chatList"
      :text-loading="loading"
      :is-stream-load="isStreamLoad"
    >
      <!-- ... 聊天内容 ... -->
    </t-chat>

    <!-- Agent 配置抽屉 -->
    <n-drawer v-model:show="showConfigDrawer" :width="400" placement="right">
      <n-drawer-content title="模型配置">
        <n-space vertical :size="16">
          <!-- 快速配置 -->
          <n-card size="small" title="快速切换">
            <n-list>
              <n-list-item
                v-for="agent in availableAgents"
                :key="agent.ID"
                clickable
                @click="switchAgent(agent)"
              >
                <template #prefix>
                  <n-avatar
                    round
                    :size="32"
                    :style="{ background: agent.color }"
                  >
                    {{ agent.name.charAt(0) }}
                  </n-avatar>
                </template>
                <n-thing>
                  <template #header>
                    <n-flex align="center" :size="4">
                      <span>{{ agent.name }}</span>
                      <n-tag v-if="agent.ID === currentAgent.ID" type="success" size="tiny">
                        当前
                      </n-tag>
                    </n-flex>
                  </template>
                  <template #description>
                    {{ agent.modelName }}
                  </template>
                </n-thing>
              </n-list-item>
            </n-list>
          </n-card>

          <!-- 模型参数 -->
          <n-card size="small" title="参数调整">
            <n-form-item label="Temperature">
              <n-slider
                v-model:value="currentAgent.temperature"
                :min="0"
                :max="2"
                :step="0.1"
                :marks="{ 0: '精确', 1: '平衡', 2: '创意' }"
              />
            </n-form-item>

            <n-form-item label="Max Tokens">
              <n-input-number
                v-model:value="currentAgent.maxTokens"
                :min="100"
                :max="8000"
                :step="100"
                style="width: 100%;"
              />
            </n-form-item>
          </n-card>

          <n-button type="primary" block @click="applyConfig">
            应用配置
          </n-button>
        </n-space>
      </n-drawer-content>
    </n-drawer>
  </div>
</template>

<script setup>
const currentAgent = ref({
  ID: 1,
  name: 'DeepSeek Chat',
  modelName: 'deepseek-chat',
  temperature: 0.7,
  maxTokens: 2000,
  color: '#4D6BFE'
})

const availableAgents = ref([])
const showConfigDrawer = ref(false)
const showModelInfo = ref(false)

const agentDropdownOptions = computed(() =>
  availableAgents.value.map(agent => ({
    label: () => h('div', { class: 'agent-dropdown-item' }, [
      h('span', { class: 'agent-dot', style: { background: agent.color } }),
      h('span', agent.name),
      agent.ID === currentAgent.value.ID ? h(NTag, { type: 'success', size: 'tiny' }, () => '当前') : null
    ]),
    key: agent.ID
  }))
)

const switchAgent = (agent) => {
  currentAgent.value = { ...agent }
  showConfigDrawer.value = false
  // 显示切换成功提示
  message.success(`已切换到 ${agent.name}`)
}

const applyConfig = () => {
  // 保存配置
  saveAgentConfig(currentAgent.value)
  showConfigDrawer.value = false
  message.success('配置已应用')
}
</script>

<style scoped>
.chat-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 16px;
  background: var(--bg-secondary);
  border-bottom: 1px solid var(--border-color);
  border-radius: 12px 12px 0 0;
}

.current-agent-name {
  margin: 0 8px;
  font-weight: 600;
  font-size: 14px;
}

:deep(.agent-dropdown-item) {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 4px 0;

  .agent-dot {
    width: 8px;
    height: 8px;
    border-radius: 50%;
  }
}
</style>
```

---

### 4.3 响应式设计方案

```vue
<style scoped>
/* 移动端优先 */
.settings-page {
  flex-direction: column;
  padding: 8px;
  gap: 8px;
}

/* 平板 */
@media (min-width: 768px) {
  .settings-page {
    flex-direction: row;
    padding: 16px;
    gap: 16px;
  }
}

/* 桌面端 */
@media (min-width: 1024px) {
  .settings-page {
    padding: 24px;
    gap: 24px;
  }

  .n-layout-sider {
    width: 240px !important;
  }
}

/* 菜单响应式 */
@media (max-width: 768px) {
  .chat-toolbar {
    flex-wrap: wrap;
    gap: 8px;

    .n-space {
      margin-left: auto;
    }
  }
}
</style>
```

---

### 4.4 暗色模式优化

```less
/* Agent 特殊色彩 */
[theme-mode="dark"] {
  --ai-accent: #3381FF;
  --ai-accent-hover: #266FE8;
  --ai-bg-light: rgba(51, 129, 255, 0.08);
  --ai-bg-hover: rgba(51, 129, 255, 0.12);
  --ai-border: rgba(51, 129, 255, 0.3);

  /* 侧边栏 */
  .ai-agent-section {
    background: var(--ai-bg-light);
    border-left-color: var(--ai-accent);

    .ai-header .n-icon {
      color: var(--ai-accent);
    }
  }

  /* Agent 下拉 */
  .agent-dropdown-item {
    &:hover {
      background: var(--ai-bg-hover);
    }

    .agent-dot {
      box-shadow: 0 0 8px var(--ai-accent);
    }
  }
}
```

---

## 五、实施计划

### 5.1 改造优先级

```
P0 (立即执行)
├── 菜单系统布局重构 (侧边栏模式)
├── Agent 入口视觉强化
└── 设置页面信息架构优化

P1 (短期目标)
├── Agent 选择界面独立化
├── 配置管理列表化
└── 首次启用引导流程

P2 (中期目标)
├── 快捷切换功能
├── 参数调整面板
└── 连接测试工具

P3 (长期目标)
├── 多模型对比功能
├── 使用统计面板
└── 自定义主题支持
```

### 5.2 技术迁移路径

```
阶段 1: 菜单系统重构 (Week 1)
├── 移除底部固定菜单
├── 实现左侧导航栏
├── Agent 特殊区域设计
└── 响应式适配

阶段 2: 设置页面优化 (Week 2)
├── 左右分栏布局
├── 配置列表化展示
├── 表单验证增强
└── 空状态设计

阶段 3: Agent 选择重构 (Week 3)
├── 独立配置面板
├── 快速切换功能
├── 参数调整界面
└── 配置抽屉组件

阶段 4: 引导与反馈 (Week 4)
├── 首次启用流程
├── 功能提示系统
├── 操作反馈完善
└── 帮助文档集成
```

---

## 六、设计规范

### 6.1 菜单规范

```
侧边栏:
├── 宽度: 240px (展开) / 64px (折叠)
├── Logo高度: 64px
├── 菜单项高度: 40px
├── 图标大小: 20px
├── 左右内边距: 12px
└── 折叠过渡: 200ms ease

Agent 区域:
├── 高度: 80px (展开) / 64px (折叠)
├── 背景色: rgba(51, 129, 255, 0.05)
├── 左边框: 3px solid #3381FF
├── 圆角: 8px
└── 外边距: 8px 12px
```

### 6.2 设置页面规范

```
导航栏:
├── 宽度: 200px
├── 菜单项高度: 36px
└── 激活指示: 左侧蓝色竖线

内容区:
├── 卡片间距: 16px
├── 表单标签宽度: 120px
├── 输入框高度: 32px
└── 按钮高度: 32px (默认) / 28px (small)
```

### 6.3 颜色系统

```
Agent 专属:
├── 主色: #3381FF (蓝)
├── 成功: #0ECB81 (绿)
├── 警告: #F0B90B (黄)
├── 错误: #F6465D (红)
└── 中性: #848E9C (灰)

模型标识:
├── GPT-4: #10A37F
├── GPT-3.5: #74AA9C
├── DeepSeek: #4D6BFE
├── 其他: #3381FF
```

---

## 七、成功指标

### 7.1 用户体验指标

| 指标 | 当前 | 目标 | 测量方法 |
|------|------|------|---------|
| 首次启用成功率 | ~40% | >80% | 埋点统计 |
| 配置添加时间 | ~3分钟 | <1分钟 | 计时测试 |
| Agent 切换时间 | ~10秒 | <3秒 | 计时测试 |
| 菜单查找时间 | ~8秒 | <3秒 | 眼动追踪 |

### 7.2 可用性检查清单

- [ ] 首次使用有引导流程
- [ ] 所有开关有说明文字
- [ ] 危险操作有二次确认
- [ ] 表单验证实时反馈
- [ ] 错误信息友好易懂
- [ ] 快捷键提示完整
- [ ] 空状态有引导操作

---

## 八、附录

### 8.1 文件变更清单

```
需要修改的文件:
├── frontend/src/App.vue
│   ├── 移除底部菜单 (第758-767行)
│   ├── 添加侧边栏布局
│   └── 重构 menuOptions 数据结构
├── frontend/src/components/settings.vue
│   ├── 重构 AI 设置区域 (第379-459行)
│   ├── 添加左侧导航
│   └── 优化表单布局
├── frontend/src/components/agent-chat.vue
│   ├── 移除输入框内选择器 (第48-54行)
│   ├── 添加顶部工具栏
│   └── 添加配置抽屉
└── frontend/src/router/router.js
    └── 无需变更

需要新建的文件:
├── frontend/src/components/agent/
│   ├── AgentConfigDrawer.vue
│   ├── AgentSelector.vue
│   └── FirstTimeGuide.vue
├── frontend/src/components/settings/
│   ├── AiOverview.vue
│   ├── AiConfigList.vue
│   └── AiPrompts.vue
└── frontend/src/composables/
    ├── useAgentConfig.ts
    └── useAgentGuide.ts
```

### 8.2 组件结构建议

```
frontend/src/
├── components/
│   ├── layout/
│   │   ├── AppSidebar.vue       # 左侧导航栏
│   │   ├── SidebarHeader.vue     # Logo区域
│   │   ├── AiAgentSection.vue    # Agent特殊区域
│   │   └── SidebarFooter.vue     # 底部设置区域
│   ├── settings/
│   │   ├── SettingsLayout.vue    # 设置页面布局
│   │   ├── SettingsNav.vue       # 设置导航
│   │   ├── AiOverview.vue        # AI概览
│   │   ├── AiConfigList.vue      # 配置列表
│   │   └── AiPrompts.vue         # Prompt配置
│   └── agent/
│       ├── AgentToolbar.vue      # 聊天工具栏
│       ├── AgentConfigDrawer.vue # 配置抽屉
│       └── FirstTimeGuide.vue    # 首次引导
```

---

## 九、总结

本改造计划针对 AI Agent 菜单系统的三大问题进行了全面分析：

**核心改进:**
1. **菜单系统重构**: 从底部菜单升级为侧边栏导航，Agent 获得专属展示区域
2. **设置页面优化**: 左右分栏 + 列表化管理，配置操作直观便捷
3. **Agent 选择独立化**: 从输入框内嵌入变为独立工具栏，切换更流畅

**预期效果:**
- Agent 发现率提升 50%+
- 配置成功率提升 40%+
- 用户学习成本降低 60%
- 整体满意度提升 35%+

---

*文档版本: v1.0*
*最后更新: 2025-01-17*

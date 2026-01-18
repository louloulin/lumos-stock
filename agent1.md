# 个性化AI投资智能体实现计划

## 📋 执行摘要

**目标**: 构建一个人人都能拥有最佳投资策略的个性化AI投资智能体系统

**现状分析**:
- ✅ 已有Cloudwego Eino ReAct Agent框架
- ✅ 已有11个基础投资工具
- ❌ **缺少技能系统**
- ❌ **缺少个性化策略**
- ❌ **缺少用户画像**

**核心差距**:
1. 所有用户使用相同的11个工具
2. 没有用户风险偏好记录
3. 没有投资策略模板
4. 没有学习能力

---

## 🔍 当前AI框架分析

### 现有架构

```
┌─────────────────────────────────────────────────────┐
│                   Cloudwego Eino                    │
│                   ReAct Agent                       │
└─────────────────────────────────────────────────────┘
                         │
                         ├── AI模型层
                         │    ├── Ark (字节跳动)
                         │    ├── DeepSeek
                         │    └── OpenAI
                         │
                         ├── 工具层 (11个静态工具)
                         │    ├── QueryEconomicData (宏观经济)
                         │    ├── QueryStockPriceInfo (实时股价)
                         │    ├── QueryStockCodeInfo (股票信息)
                         │    ├── QueryMarketNews (市场资讯)
                         │    ├── ChoiceStockByIndicators (智能选股)
                         │    ├── QueryStockKLine (K线数据)
                         │    ├── InteractiveAnswerData (互动问答)
                         │    ├── FinancialReport (财务报表)
                         │    ├── QueryStockNews (个股新闻)
                         │    ├── IndustryResearchReport (行业研报)
                         │    └── QueryBKDict (板块字典)
                         │
                         └── 提示词层
                              ├── PromptTemplate (可自定义)
                              └── System Prompt (固定)
```

### 关键文件

**后端核心**:
- `backend/agent/agent.go`: Agent创建逻辑
- `backend/agent/agent_api.go`: API接口和流式传输
- `backend/agent/tools/*.go`: 11个工具实现

**数据模型**:
- `AIConfig`: AI模型配置 (ApiKey, BaseUrl, ModelName等)
- `PromptTemplate`: 系统提示词模板
- `Settings`: 全局设置

**前端**:
- `frontend/src/components/agent-chat.vue`: 聊天界面 (存在渲染bug)

### 现有能力矩阵

| 维度 | 支持情况 | 说明 |
|------|---------|------|
| 多模型支持 | ✅ | Ark/DeepSeek/OpenAI |
| 流式响应 | ✅ | Wails Events实时推送 |
| 工具调用 | ✅ | 11个投资工具 |
| 提示词定制 | ⚠️ | 仅有PromptTemplate表 |
| 用户画像 | ❌ | **缺失** |
| 投资策略 | ❌ | **缺失** |
| 技能系统 | ❌ | **缺失** |
| 学习机制 | ❌ | **缺失** |
| 风险评估 | ❌ | **缺失** |

---

## 🎯 个性化智能体设计

### 核心理念

**"一人一智能体，千人千策略"**

每个用户都应该拥有：
1. **独特的投资画像**: 基于年龄、资金、经验、风险偏好
2. **个性化策略库**: 保守型、激进型、量化型、价值型等
3. **动态技能组合**: 根据用户画像自动选择工具组合
4. **持续学习**: 从用户行为中学习优化策略

### 用户画像系统

#### 1. 用户基础信息表

```go
type UserProfile struct {
    gorm.Model
    UserID              uint   `gorm:"index"` // 关联Settings.ID
    Age                 int
    Occupation          string // 职业
    InvestmentExperience string // 投资经验: 无/1-3年/3-5年/5年以上
    InvestmentAmount    float64 // 投资金额
    RiskTolerance       string // 风险偏好: 保守/稳健/激进
    InvestmentGoals     string // 投资目标: 稳健增值/高收益/退休规划
    FocusMarkets        string // 关注市场: A股/港股/美股
    TradingFrequency    string // 交易频率: 日内/短线/中线/长线
    LossTolerance       float64 // 最大可承受亏损比例
    PreferredSectors    string // 偏好板块
}
```

#### 2. 投资策略表

```go
type InvestmentStrategy struct {
    gorm.Model
    Name              string
    Type              string // 策略类型: value/growth/momentum/quant
    RiskLevel         int    // 风险等级 1-5
    Description       string
    SystemPrompt      string // 策略专属系统提示词
    ToolWhitelist     string // JSON数组: 允许使用的工具
    ToolBlacklist     string // JSON数组: 禁止使用的工具
    MaxPosition       float64 // 最大仓位
    StopLoss          float64 // 止损线
    TakeProfit        float64 // 止盈线
    HoldPeriod        int    // 建议持有周期(天)
}

// 预设策略模板
var StrategyTemplates = []InvestmentStrategy{
    {
        Name:        "保守价值策略",
        Type:        "value",
        RiskLevel:   1,
        Description: "适合风险厌恶型投资者，关注低估值蓝筹股",
        SystemPrompt: "你现在是一位保守型投资顾问。请重点关注：1)低PE/PB股票 2)高股息率 3)稳定盈利能力。避免推荐高波动股票。",
        ToolWhitelist: `["QueryStockPriceInfo", "FinancialReport", "QueryStockKLine"]`,
        MaxPosition:  0.3,
        StopLoss:     0.08,
        TakeProfit:   0.15,
        HoldPeriod:   90,
    },
    {
        Name:        "激进成长策略",
        Type:        "growth",
        RiskLevel:   5,
        Description: "适合风险偏好型投资者，追求高成长",
        SystemPrompt: "你现在是一位激进成长型投资顾问。请重点关注：1)高营收增长 2)新兴行业 3)技术突破。可以容忍较高波动。",
        ToolWhitelist: `["QueryMarketNews", "ChoiceStockByIndicators", "IndustryResearchReport"]`,
        MaxPosition:  0.5,
        StopLoss:     0.15,
        TakeProfit:   0.50,
        HoldPeriod:  30,
    },
    // ... 更多策略
}
```

#### 3. 用户策略关联表

```go
type UserStrategy struct {
    gorm.Model
    UserID              uint   `gorm:"index"`
    StrategyID          uint   `gorm:"index"`
    IsActive            bool   // 是否当前激活
    CustomPrompt        string // 用户自定义提示词
    CustomToolWeights   string // JSON: 工具权重配置
    Performance         string // JSON: 策略表现统计
    CreatedAt           time.Time
    LastUsedAt          time.Time
}
```

### 技能系统架构

#### 技能定义

技能 = 工具组合 + 提示词增强 + 参数约束

```go
type AgentSkill struct {
    gorm.Model
    Name              string
    Category          string // 技能分类: analysis/selection/risk/execution
    Description       string
    RequiredTools     []string // 必需工具
    OptionalTools     []string // 可选工具
    PromptEnhancement string // 提示词增强片段
    SkillLevel        int    // 技能等级: 1-5
    Prerequisites     []string // 前置技能
}

// 技能示例
var SkillLibrary = []AgentSkill{
    {
        Name:        "技术面分析",
        Category:    "analysis",
        Description: "基于K线、技术指标进行股票分析",
        RequiredTools: []string{"QueryStockKLine", "QueryStockPriceInfo"},
        OptionalTools: []string{"QueryMarketNews"},
        PromptEnhancement: "在分析股票时，请结合以下技术指标：MA、MACD、KDJ、RSI、成交量。",
        SkillLevel:   2,
    },
    {
        Name:        "基本面选股",
        Category:    "selection",
        Description: "基于财务指标筛选优质股票",
        RequiredTools: []string{"FinancialReport", "ChoiceStockByIndicators"},
        OptionalTools: []string{"IndustryResearchReport"},
        PromptEnhancement: "在选股时，重点关注：ROE、净利润增长率、负债率、现金流。",
        SkillLevel:   3,
        Prerequisites: []string{"财务报表分析"},
    },
    {
        Name:        "市场情绪研判",
        Category:    "analysis",
        Description: "分析市场情绪和资金流向",
        RequiredTools: []string{"QueryMarketNews", "QueryStockNews"},
        OptionalTools: []string{"QueryEconomicData"},
        PromptEnhancement: "在研判市场时，请分析新闻情绪、北向资金流向、市场热点。",
        SkillLevel:   3,
    },
    {
        Name:        "风险控制",
        Category:    "risk",
        Description: "评估投资风险并给出风控建议",
        RequiredTools: []string{"QueryStockKLine", "FinancialReport"},
        PromptEnhancement: "在每次建议后，必须给出：止损位、止盈位、仓位建议、风险提示。",
        SkillLevel:   4,
    },
}
```

#### 智能体构建器

```go
// 根据用户画像和策略动态构建智能体
func BuildPersonalizedAgent(userProfile UserProfile, strategy InvestmentStrategy) *react.Agent {
    ctx := context.Background()

    // 1. 基础模型配置
    aiConfig := GetDefaultAIConfig()
    chatModel := createChatModel(aiConfig)

    // 2. 根据策略筛选工具
    availableTools := getAllTools()
    selectedTools := filterToolsByStrategy(availableTools, strategy)

    // 3. 根据用户画像增强系统提示词
    systemPrompt := buildPersonalizedPrompt(userProfile, strategy)

    // 4. 创建个性化Agent
    agent, _ := react.NewAgent(ctx, &react.AgentConfig{
        ToolCallingModel: chatModel,
        ToolsConfig: compose.ToolsNodeConfig{
            Tools: selectedTools,
        },
        SystemPrompt: systemPrompt,
        MaxStep:      calculateMaxSteps(userProfile, strategy),
    })

    return agent
}

func buildPersonalizedPrompt(profile UserProfile, strategy InvestmentStrategy) string {
    basePrompt := strategy.SystemPrompt

    personalizedPrompt := fmt.Sprintf(`
%s

用户画像:
- 年龄: %d岁
- 投资经验: %s
- 风险偏好: %s
- 投资金额: %.2f万元
- 交易风格: %s
- 最大可承受亏损: %.1f%%

请根据用户画像调整你的分析深度和建议风格。
`, basePrompt, profile.Age, profile.InvestmentExperience,
       profile.RiskTolerance, profile.InvestmentAmount/10000,
       profile.TradingFrequency, profile.LossTolerance*100)

    return personalizedPrompt
}
```

### 策略推荐引擎

```go
// 基于用户画像推荐最合适的策略
func RecommendStrategy(profile UserProfile) []InvestmentStrategy {
    var strategies []InvestmentStrategy

    // 规则引擎
    switch profile.RiskTolerance {
    case "保守":
        strategies = append(strategies, getStrategyByName("保守价值策略"))
        strategies = append(strategies, getStrategyByName("股息策略"))
    case "稳健":
        strategies = append(strategies, getStrategyByName("平衡配置策略"))
        strategies = append(strategies, getStrategyByName("GARP策略"))
    case "激进":
        strategies = append(strategies, getStrategyByName("激进成长策略"))
        strategies = append(strategies, getStrategyByName("动量策略"))
    }

    // 根据资金量调整
    if profile.InvestmentAmount < 50000 {
        // 小资金用户，推荐集中持股策略
        strategies = append(strategies, getStrategyByName("集中持股策略"))
    } else {
        // 大资金用户，推荐分散配置策略
        strategies = append(strategies, getStrategyByName("分散配置策略"))
    }

    return strategies
}
```

---

## 🏗️ 实现路线图

### Phase 1: 数据基础设施 (Week 1-2)

**目标**: 建立用户画像和策略数据库

#### 任务清单

- [ ] **数据库设计**
  - [ ] 创建 `user_profiles` 表
  - [ ] 创建 `investment_strategies` 表
  - [ ] 创建 `user_strategies` 关联表
  - [ ] 创建 `agent_skills` 表
  - [ ] 数据库迁移脚本

- [ ] **后端API开发**
  - [ ] `user_profile_api.go`: 用户画像CRUD
  - [ ] `strategy_api.go`: 策略管理API
  - [ ] `skill_api.go`: 技能管理API
  - [ ] `agent_builder.go`: 动态Agent构建器

- [ ] **预设策略模板**
  - [ ] 保守价值策略
  - [ ] 稳健成长策略
  - [ ] 激进进取策略
  - [ ] 量化选股策略
  - [ ] 主题投资策略
  - [ ] 股息策略
  - [ ] 动量策略
  - [ ] GARP策略

#### 验收标准

- ✅ 数据库表创建完成
- ✅ API接口测试通过
- ✅ 至少8个预设策略模板
- ✅ 可以通过API创建/查询/更新用户画像

### Phase 2: 个性化Agent构建器 (Week 3-4)

**目标**: 实现动态Agent构建引擎

#### 任务清单

- [ ] **Agent构建器核心**
  - [ ] `BuildPersonalizedAgent()` 函数
  - [ ] 工具筛选引擎
  - [ ] 提示词合成引擎
  - [ ] 参数配置引擎

- [ ] **策略推荐引擎**
  - [ ] 规则引擎实现
  - [ ] 问卷系统(用于收集用户画像)
  - [ ] 策略匹配算法

- [ ] **技能系统集成**
  - [ ] 技能库实现
  - [ ] 技能依赖检查
  - [ ] 技能等级验证

- [ ] **测试**
  - [ ] 单元测试
  - [ ] 集成测试
  - [ ] 不同用户画像的Agent构建测试

#### 验收标准

- ✅ 可以根据用户画像构建差异化Agent
- ✅ 不同策略生成的Agent使用不同工具组合
- ✅ 系统提示词根据画像动态调整
- ✅ 测试覆盖率 > 80%

### Phase 3: 前端UI开发 (Week 5-6)

**目标**: 用户友好的配置界面

#### 任务清单

- [ ] **用户画像页面**
  - [ ] 投资者问卷表单
  - [ ] 画像展示和编辑
  - [ ] 风险评估测试

- [ ] **策略管理页面**
  - [ ] 策略列表展示
  - [ ] 策略详情查看
  - [ ] 策略切换功能
  - [ ] 自定义策略编辑器

- [ ] **Agent配置页面**
  - [ ] 模型选择器
  - [ ] 技能配置器
  - [ ] 提示词编辑器
  - [ ] 工具开关

- [ ] **性能追踪页面**
  - [ ] 策略收益曲线
  - [ ] 胜率统计
  - [ ] 最大回撤分析

#### UI设计原则

- 简洁: 问卷不超过10题
- 智能: 根据用户输入自动推荐
- 可视化: 用图表展示策略特征
- 引导: 新用户引导流程

#### 验收标准

- ✅ 新用户可以在3分钟内完成画像设置
- ✅ 策略切换即时生效
- ✅ 所有配置项有明确说明
- ✅ UI适配暗黑模式

### Phase 4: 学习和优化系统 (Week 7-8)

**目标**: 让Agent从用户行为中学习

#### 任务清单

- [ ] **行为追踪**
  - [ ] 用户操作记录表设计
  - [ ] 建议采纳率追踪
  - [ ] 交易记录关联

- [ ] **反馈机制**
  - [ ] 建议评分系统
  - [ ] 实际收益录入
  - [ ] 体验反馈收集

- [ ] **策略优化**
  - [ ] A/B测试框架
  - [ ] 策略参数自动调优
  - [ ] 个性化推荐算法

- [ ] **报告生成**
  - [ ] 月度策略报告
  - [ ] 收益归因分析
  - [ ] 优化建议

#### 验收标准

- ✅ 可以追踪每个建议的后续结果
- ✅ 能够生成策略表现报告
- ✅ 有明确的优化方向建议

### Phase 5: 高级功能 (Week 9+)

**目标**: 差异化竞争力

#### 任务清单

- [ ] **策略分享市场**
  - [ ] 策略导出/导入
  - [ ] 策略评分和排行
  - [ ] 大师策略订阅

- [ ] **智能诊断**
  - [ ] 投资组合健康度检查
  - [ ] 风险预警
  - [ ] 优化建议

- [ ] **模拟交易**
  - [ ] 纸面交易功能
  - [ ] 策略回测
  - [ ] 历史表现分析

- [ ] **社区功能**
  - [ ] 策略讨论区
  - [ ] 用户交流
  - [ ] 专家问答

---

## 📊 数据库Schema

### 完整ER图

```
┌──────────────────┐       ┌──────────────────┐
│   user_profiles  │       │investment_strategies│
│ ──────────────── │       │ ──────────────────│
│ id (PK)          │       │ id (PK)           │
│ user_id (FK)     │       │ name              │
│ age              │       │ type              │
│ occupation       │       │ risk_level        │
│ inv_experience   │       │ description       │
│ inv_amount       │       │ system_prompt     │
│ risk_tolerance   │       │ tool_whitelist    │
│ inv_goals        │       │ max_position      │
│ focus_markets    │       │ stop_loss         │
│ trading_freq     │       │ take_profit       │
│ loss_tolerance   │       │ hold_period       │
│ pref_sectors     │       │ is_template       │
└──────────────────┘       └──────────────────┘
         │                           │
         │                           │
         ▼                           ▼
┌──────────────────┐       ┌──────────────────┐
│  user_strategies │       │   agent_skills    │
│ ──────────────── │       │ ──────────────────│
│ id (PK)          │       │ id (PK)           │
│ user_id (FK)     │       │ name              │
│ strategy_id (FK) │       │ category          │
│ is_active        │       │ description       │
│ custom_prompt    │       │ required_tools    │
│ custom_weights   │       │ optional_tools    │
│ performance      │       │ prompt_enhancement│
│ created_at       │       │ skill_level       │
│ last_used_at     │       │ prerequisites     │
└──────────────────┘       └──────────────────┘
         │                           │
         │                           │
         ▼                           ▼
┌──────────────────────────────────────────┐
│         user_behaviors                   │
│ ────────────────────────────────────     │
│ id (PK)                                  │
│ user_id (FK)                             │
│ strategy_id (FK)                         │
│ action_type                              │
│ action_detail (JSON)                     │
│ agent_suggestion (JSON)                  │
│ user_action                              │
│ outcome                                  │
│ timestamp                                │
└──────────────────────────────────────────┘
```

### Migration SQL

```sql
-- 用户画像表
CREATE TABLE user_profiles (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL UNIQUE,
    age INTEGER,
    occupation VARCHAR(100),
    investment_experience VARCHAR(50),
    investment_amount DECIMAL(15,2),
    risk_tolerance VARCHAR(20),
    investment_goals VARCHAR(200),
    focus_markets VARCHAR(100),
    trading_frequency VARCHAR(50),
    loss_tolerance DECIMAL(5,4),
    preferred_sectors TEXT,
    created_at DATETIME,
    updated_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES settings(id)
);

-- 投资策略表
CREATE TABLE investment_strategies (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(50),
    risk_level INTEGER CHECK(risk_level BETWEEN 1 AND 5),
    description TEXT,
    system_prompt TEXT,
    tool_whitelist TEXT,
    tool_blacklist TEXT,
    max_position DECIMAL(3,2),
    stop_loss DECIMAL(5,4),
    take_profit DECIMAL(5,4),
    hold_period INTEGER,
    is_template BOOLEAN DEFAULT 0,
    created_at DATETIME,
    updated_at DATETIME
);

-- 用户策略关联表
CREATE TABLE user_strategies (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    strategy_id INTEGER,
    is_active BOOLEAN DEFAULT 0,
    custom_prompt TEXT,
    custom_tool_weights TEXT,
    performance TEXT,
    created_at DATETIME,
    last_used_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES settings(id),
    FOREIGN KEY (strategy_id) REFERENCES investment_strategies(id)
);

-- 智能体技能表
CREATE TABLE agent_skills (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(100) NOT NULL UNIQUE,
    category VARCHAR(50),
    description TEXT,
    required_tools TEXT,
    optional_tools TEXT,
    prompt_enhancement TEXT,
    skill_level INTEGER CHECK(skill_level BETWEEN 1 AND 5),
    prerequisites TEXT,
    created_at DATETIME,
    updated_at DATETIME
);

-- 用户行为记录表
CREATE TABLE user_behaviors (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    strategy_id INTEGER,
    action_type VARCHAR(50),
    action_detail TEXT,
    agent_suggestion TEXT,
    user_action VARCHAR(50),
    outcome TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES settings(id)
);

-- 创建索引
CREATE INDEX idx_user_profiles_user_id ON user_profiles(user_id);
CREATE INDEX idx_user_strategies_user_id ON user_strategies(user_id);
CREATE INDEX idx_user_strategies_strategy_id ON user_strategies(strategy_id);
CREATE INDEX idx_user_behaviors_user_id ON user_behaviors(user_id);
CREATE INDEX idx_user_behaviors_timestamp ON user_behaviors(timestamp);
```

---

## 🎨 典型用户场景

### 场景1: 新用户引导

```
用户: 首次使用
     ↓
问卷: 10个问题 (年龄/经验/资金/风险偏好/目标...)
     ↓
分析: 系统分析用户画像
     ↓
推荐: 推荐3个最适合的策略
     ↓
选择: 用户选择策略并创建个性化Agent
     ↓
开始: 投资助手就绪
```

### 场景2: 策略切换

```
用户: 市场风格切换，想调整策略
     ↓
浏览: 查看可用策略列表
     ↓
对比: 对比策略特征和表现
     ↓
切换: 一键切换到新策略
     ↓
生效: Agent立即使用新策略的工具和提示词
     ↓
验证: 观察新策略的回复风格差异
```

### 场景3: 高级定制

```
用户: 有自己的投资理念
     ↓
克隆: 复制现有策略
     ↓
修改: 调整提示词、工具选择、参数
     ↓
测试: 使用模拟交易测试
     ↓
优化: 根据回测结果调整
     ↓
应用: 切换到定制策略
```

---

## 🔧 技术实现细节

### Agent构建器伪代码

```go
package agent

type PersonalizedAgentBuilder struct {
    userProfile    data.UserProfile
    strategy       data.InvestmentStrategy
    activeSkills   []data.AgentSkill
    aiConfig       data.AIConfig
}

func (b *PersonalizedAgentBuilder) Build() (*react.Agent, error) {
    // Step 1: 创建模型
    chatModel := b.createChatModel()

    // Step 2: 筛选工具
    tools := b.selectTools()

    // Step 3: 构建系统提示词
    systemPrompt := b.buildSystemPrompt()

    // Step 4: 创建Agent
    agent, err := react.NewAgent(context.Background(), &react.AgentConfig{
        ToolCallingModel: chatModel,
        ToolsConfig: compose.ToolsNodeConfig{
            Tools: tools,
        },
        SystemPrompt: systemPrompt,
        MaxStep:      b.calculateMaxSteps(),
    })

    return agent, err
}

func (b *PersonalizedAgentBuilder) selectTools() []tool.BaseTool {
    allTools := getAllTools()
    var selected []tool.BaseTool

    // 白名单优先
    if b.strategy.ToolWhitelist != "" {
        whitelist := parseJSONList(b.strategy.ToolWhitelist)
        for _, t := range allTools {
            if contains(whitelist, t.Name()) {
                selected = append(selected, t)
            }
        }
    } else {
        // 黑名单过滤
        blacklist := parseJSONList(b.strategy.ToolBlacklist)
        for _, t := range allTools {
            if !contains(blacklist, t.Name()) {
                selected = append(selected, t)
            }
        }
    }

    return selected
}

func (b *PersonalizedAgentBuilder) buildSystemPrompt() string {
    prompt := b.strategy.SystemPrompt

    // 添加用户画像信息
    prompt += fmt.Sprintf("\n\n用户画像:\n%s", b.formatUserProfile())

    // 添加技能增强
    for _, skill := range b.activeSkills {
        prompt += fmt.Sprintf("\n%s: %s", skill.Name, skill.PromptEnhancement)
    }

    return prompt
}
```

### API接口设计

```go
// 用户画像API
func CreateUserProfile(profile data.UserProfile) error
func GetUserProfile(userID uint) (data.UserProfile, error)
func UpdateUserProfile(profile data.UserProfile) error

// 策略API
func GetStrategies() ([]data.InvestmentStrategy, error)
func GetStrategyByID(id uint) (data.InvestmentStrategy, error)
func CreateCustomStrategy(strategy data.InvestmentStrategy) error
func RecommendStrategies(userID uint) ([]data.InvestmentStrategy, error)

// Agent API
func BuildPersonalizedAgent(userID uint, strategyID uint) (*react.Agent, error)
func SwitchUserStrategy(userID uint, strategyID uint) error
func GetActiveAgent(userID uint) (*react.Agent, error)

// 技能API
func GetSkills() ([]data.AgentSkill, error)
func ActivateSkill(userID uint, skillID uint) error
func DeactivateSkill(userID uint, skillID uint) error
```

---

## 📈 成功指标

### 技术指标

| 指标 | 目标 | 测量方式 |
|------|------|---------|
| Agent构建成功率 | >99% | 日志统计 |
| API响应时间 | <500ms | 性能监控 |
| 数据库查询时间 | <100ms | 慢查询日志 |
| 测试覆盖率 | >80% | 单元测试报告 |

### 产品指标

| 指标 | 目标 | 测量方式 |
|------|------|---------|
| 画像完成率 | >70% | 用户统计 |
| 策略切换率 | >30% | 行为分析 |
| Agent使用频率 | +50% | 对比基线 |
| 用户满意度 | >4.0/5.0 | 问卷调查 |

---

## 🚀 快速启动指南

### 开发环境准备

```bash
# 1. 创建feature分支
git checkout -b feature/personalized-agent

# 2. 创建开发文件
mkdir -p backend/agent/personalized
mkdir -p frontend/src/views/agent

# 3. 数据库迁移
sqlite3 lumos-stock.db < migrations/001_personalized_agent.sql

# 4. 运行测试
go test ./backend/agent/personalized/...
```

### 最小可行产品(MVP)范围

**Week 1 MVP**:
- ✅ 用户画像表和API
- ✅ 3个预设策略(保守/稳健/激进)
- ✅ 简化版Agent构建器
- ✅ 基础前端配置页面

**验证**: 可以创建不同的用户画像，并获得不同回复风格的Agent

---

## 🎯 总结

### 核心价值

1. **差异化竞争**: 从"通用AI"到"个性化AI投资顾问"
2. **用户粘性**: 个性化配置提高切换成本
3. **持续优化**: 学习机制让Agent越来越智能
4. **可扩展性**: 策略和技能系统易于扩展

### 技术亮点

- 基于成熟的Cloudwego Eino框架
- 动态Agent构建引擎
- 数据驱动的策略推荐
- 完整的学习闭环

### 下一步行动

1. **立即**: 创建数据库migration
2. **本周**: 实现用户画像API
3. **下周**: 开发Agent构建器
4. **持续**: 前端UI和用户体验优化

---

**愿景**: 让每个投资者都能拥有最适合自己的人工智能投资助手 🚀

# lumos-stock 架构设计文档

## 系统概述

lumos-stock 是一个基于 **Wails** 框架的桌面应用程序，采用 **Go 后端 + Vue3 前端** 的架构，集成了大语言模型 (LLM) 实现智能股票分析。

## 技术栈

### 后端 (Go)
- **框架**: Wails v2.10.1
- **ORM**: GORM v1.31.1
- **数据库**: SQLite (glebarez/sqlite)
- **AI Agent**: Cloudwego Eino v0.7.9
- **HTTP 客户端**: resty/v2
- **缓存**: freecache
- **定时任务**: robfig/cron/v3
- **爬虫**: chromedp (Chrome DevTools Protocol)

### 前端 (Vue3)
- **框架**: Vue 3.5.17
- **UI 库**: NaiveUI 2.43.2
- **构建工具**: Vite 7.2.4
- **路由**: Vue Router 4.5.0
- **图表**: ECharts 5.6.0
- **Markdown**: md-editor-v3
- **弹幕**: vue3-danmaku

## 整体架构

```
┌─────────────────────────────────────────────────────────────┐
│                        用户界面层                            │
│                    (Vue3 + NaiveUI)                         │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │
│  │ 股票详情 │ │ AI 分析  │ │ 市场行情 │ │  设置    │       │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘       │
└──────────────────────┬──────────────────────────────────────┘
                       │ Wails Bindings
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                        应用逻辑层                            │
│                         (Go)                                │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │
│  │ 数据API  │ │ AI Agent │ │ 爬虫API  │ │ 通知API  │       │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘       │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                        数据访问层                            │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │
│  │SQLite DB │ │  内存缓存 │ │ HTTP API │ │爬虫引擎  │       │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘       │
└─────────────────────────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                        外部数据源                            │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │
│  │ Tushare  │ │ 财经网站 │ │ AI 服务  │ │ 新闻API  │       │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘       │
└─────────────────────────────────────────────────────────────┘
```

## 目录结构

```
lumos-stock/
├── backend/                    # 后端代码
│   ├── agent/                 # AI Agent 模块
│   │   ├── agent.go          # Agent 核心逻辑
│   │   ├── agent_api.go      # Agent API 接口
│   │   ├── tool_logger/      # 工具调用日志
│   │   └── tools/            # AI 工具集 (12+ 个工具)
│   ├── data/                 # 数据访问层
│   │   ├── stock_data_api.go
│   │   ├── market_news_api.go
│   │   ├── openai_api.go
│   │   ├── crawler_api.go
│   │   ├── fund_data_api.go
│   │   └── ...
│   ├── db/                   # 数据库层
│   ├── models/               # 数据模型
│   ├── logger/               # 日志模块
│   └── util/                 # 工具函数
├── frontend/                 # 前端代码
│   ├── src/
│   │   ├── components/       # Vue 组件 (27 个)
│   │   ├── router/           # 路由配置
│   │   ├── assets/           # 静态资源
│   │   └── main.js           # 入口文件
│   ├── wailsjs/              # Wails 生成的绑定
│   └── package.json
├── build/                    # 构建配置
│   ├── darwin/               # macOS 配置
│   ├── windows/              # Windows 配置
│   └── screenshot/           # 截图
├── docs/                     # 文档
├── scripts/                  # 构建脚本
├── app.go                    # 主应用
├── main.go                   # 程序入口
├── go.mod                    # Go 模块定义
└── wails.json                # Wails 配置
```

## 核心模块设计

### 1. AI Agent 模块

#### 架构图
```
┌──────────────────────────────────────────────────────────┐
│                    AI Agent (Eino)                        │
│  ┌────────────┐      ┌────────────┐      ┌────────────┐  │
│  │ ReAct Loop │ ───▶ │Tool Router │ ───▶ │Tool Executor│  │
│  └────────────┘      └────────────┘      └────────────┘  │
└──────────────────────────────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────┐
│                     工具集 (Tools)                         │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐     │
│  │股票查询  │ │K线数据   │ │市场新闻   │ │财务报告   │     │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘     │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐     │
│  │指标选股  │ │行业研报   │ │经济数据   │ │互动问答   │     │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘     │
└──────────────────────────────────────────────────────────┘
```

#### Agent 工作流程
1. **接收用户输入**: 用户通过前端发送问题
2. **思维链推理**: Agent 分析问题，规划解决步骤
3. **工具调用**: 根据需要调用相应的工具函数
4. **结果整合**: 将工具返回结果整合成回答
5. **返回结果**: 以 Markdown 格式返回给前端

#### 工具函数接口
```go
type Tool interface {
    Name() string
    Description() string
    Execute(ctx context.Context, params map[string]interface{}) (string, error)
}

// 示例: 股票 K 线数据工具
type StockKLineDataTool struct {
    dataAPI *data.StockDataAPI
}

func (t *StockKLineDataTool) Execute(ctx context.Context, params map[string]interface{}) (string, error) {
    stockCode := params["stock_code"].(string)
    period := params["period"].(string)
    klineData, err := t.dataAPI.GetStockKLineData(stockCode, period)
    // ... 处理数据并返回字符串格式
}
```

### 2. 数据访问层

#### 数据流设计
```
┌──────────────┐
│ 用户请求     │
└──────┬───────┘
       ▼
┌──────────────┐      ┌──────────────┐
│ 检查缓存     │ ───▶ │ 缓存命中     │ ───▶ 返回数据
└──────┬───────┘      └──────────────┘
       │ 未命中
       ▼
┌──────────────┐
│ 查询数据库   │
└──────┬───────┘
       ▼
┌──────────────┐      ┌──────────────┐
│ 调用外部API  │ ───▶ │ 数据验证     │
└──────┬───────┘      └──────┬───────┘
       │                     ▼
       │              ┌──────────────┐
       │              │ 保存到缓存   │
       │              └──────┬───────┘
       │                     ▼
       │              ┌──────────────┐
       └─────────────▶│ 保存到数据库 │
                      └──────┬───────┘
                             ▼
                      ┌──────────────┐
                      │   返回数据   │
                      └──────────────┘
```

#### 数据源策略
1. **优先级**: 缓存 > 数据库 > 外部 API
2. **更新策略**:
   - 实时行情: 5 分钟缓存
   - K 线数据: 1 小时缓存
   - 基本信息: 24 小时缓存
3. **容错机制**:
   - 主数据源失败 → 备用数据源
   - 超时重试 (最多 3 次)
   - 降级处理 (返回缓存数据)

### 3. 前端架构

#### 组件层次
```
App.vue (根组件)
├── router-view (路由视图)
│   ├── stock.vue (股票详情)
│   │   ├── KLineChart.vue (K 线图)
│   │   └── ...
│   ├── market.vue (市场行情)
│   ├── agent-chat.vue (AI 聊天)
│   ├── settings.vue (设置)
│   └── about.vue (关于)
└── Layout Components (布局组件)
    ├── Header
    ├── Sidebar
    └── Footer
```

#### 状态管理
```javascript
// 使用 Vue3 Composition API
import { ref, reactive } from 'vue'

export default {
  setup() {
    // 响应式状态
    const stockInfo = ref(null)
    const loading = ref(false)

    // 方法
    const fetchStockData = async (code) => {
      loading.value = true
      try {
        stockInfo.value = await GetStockRealtimeData(code)
      } finally {
        loading.value = false
      }
    }

    return {
      stockInfo,
      loading,
      fetchStockData
    }
  }
}
```

### 4. 数据库设计

#### 表结构
```sql
-- 股票基本信息
CREATE TABLE stock_basics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    industry TEXT,
    market TEXT,
    updated_at DATETIME
);

-- 用户配置
CREATE TABLE settings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    key TEXT NOT NULL UNIQUE,
    value TEXT,
    updated_at DATETIME
);

-- 提示词模板
CREATE TABLE prompts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at DATETIME,
    updated_at DATETIME
);

-- 股票分组
CREATE TABLE groups (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    created_at DATETIME
);

-- 自选股
CREATE TABLE followed_stocks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    stock_code TEXT NOT NULL,
    cost REAL,
    group_id INTEGER,
    created_at DATETIME,
    FOREIGN KEY (group_id) REFERENCES groups(id)
);

-- 市场新闻
CREATE TABLE news_lists (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    content TEXT,
    source TEXT,
    publish_time DATETIME,
    url TEXT,
    created_at DATETIME
);
```

## 数据流

### 典型场景: AI 股票分析

```
用户输入: "分析贵州茅台的最近走势"
    │
    ▼
┌───────────────────────────────────────┐
│ 1. 前端发送请求到后端                  │
│    AnalyzeStockByAI("600519", "分析...")│
└───────────────┬───────────────────────┘
                ▼
┌───────────────────────────────────────┐
│ 2. 后端 Agent 处理                     │
│    - ReAct 推理                        │
│    - 确定需要调用: K线工具、新闻工具    │
└───────────────┬───────────────────────┘
                ▼
┌───────────────────────────────────────┐
│ 3. 并行调用工具                        │
│    ├─ GetStockKLineData("600519")     │
│    ├─ GetStockNews("600519")          │
│    └─ GetFinancialReports("600519")   │
└───────────────┬───────────────────────┘
                ▼
┌───────────────────────────────────────┐
│ 4. 工具获取数据                        │
│    - 检查缓存                          │
│    - 查询数据库                        │
│    - 调用外部 API (Tushare)            │
└───────────────┬───────────────────────┘
                ▼
┌───────────────────────────────────────┐
│ 5. Agent 整合结果                      │
│    - 调用 LLM (DeepSeek/OpenAI)        │
│    - 生成 Markdown 格式分析报告        │
└───────────────┬───────────────────────┘
                ▼
┌───────────────────────────────────────┐
│ 6. 返回给前端                          │
│    - 前端使用 md-editor-v3 展示        │
└───────────────────────────────────────┘
```

## 并发处理

### Goroutine 使用场景
1. **批量数据获取**: 并发获取多个股票数据
2. **定时任务**: 使用 cron 定时更新数据
3. **新闻爬取**: 并发爬取多个新闻源

### 示例代码
```go
// 并发获取多个股票数据
func (s *StockDataAPI) GetBatchStockData(codes []string) ([]models.StockInfo, error) {
    var wg sync.WaitGroup
    results := make([]models.StockInfo, len(codes))
    errs := make([]error, len(codes))

    for i, code := range codes {
        wg.Add(1)
        go func(idx int, c string) {
            defer wg.Done()
            data, err := s.GetStockRealtimeData(c)
            results[idx] = data
            errs[idx] = err
        }(i, code)
    }

    wg.Wait()

    // 处理结果和错误
    // ...
}
```

## 缓存策略

### 多级缓存
```
┌──────────────────────────────────────┐
│   Level 1: 内存缓存 (freecache)       │
│   - 热点数据                         │
│   - 5-60 分钟 TTL                    │
└──────────────┬───────────────────────┘
               │ Miss
               ▼
┌──────────────────────────────────────┐
│   Level 2: 数据库 (SQLite)            │
│   - 历史数据                         │
│   - 持久化存储                       │
└──────────────┬───────────────────────┘
               │ Miss
               ▼
┌──────────────────────────────────────┐
│   Level 3: 外部 API                   │
│   - Tushare API                      │
│   - 财经网站爬虫                     │
└──────────────────────────────────────┘
```

### 缓存更新策略
- **主动更新**: 定时任务批量更新
- **被动更新**: 用户请求时更新
- **失效策略**: TTL 过期自动失效

## 错误处理

### 错误类型
```go
type AppError struct {
    Code      string
    Message   string
    Details   string
    Timestamp time.Time
}

// 错误码定义
const (
    ErrNetwork      = "NETWORK_ERROR"
    ErrDataNotFound = "DATA_NOT_FOUND"
    ErrAIProvider   = "AI_PROVIDER_ERROR"
    ErrInvalidParam = "INVALID_PARAMETER"
    ErrDatabase     = "DATABASE_ERROR"
)
```

### 错误处理流程
```
API 调用
    │
    ▼
捕获错误
    │
    ├─── 网络错误 ──▶ 重试 (最多 3 次)
    ├─── 数据错误 ──▶ 返回缓存数据
    ├─── AI 错误 ───▶ 降级到简单分析
    └─── 其他错误 ──▶ 记录日志 + 用户提示
```

## 性能优化

### 1. 数据库优化
- 添加索引
- 查询优化
- 连接池

### 2. 前端优化
- 组件懒加载
- 虚拟列表
- 图表渲染优化

### 3. 网络优化
- HTTP/2
- 请求合并
- 压缩传输

## 安全考虑

### 1. API 密钥管理
```go
// 使用环境变量
tushareToken := os.Getenv("TUSHARE_TOKEN")
openAIKey := os.Getenv("OPENAI_API_KEY")
```

### 2. 数据加密
- 本地数据库加密 (可选)
- HTTPS 通信

### 3. 输入验证
```go
// 验证股票代码格式
func validateStockCode(code string) bool {
    matched, _ := regexp.MatchString(`^\d{6}$`, code)
    return matched
}
```

## 扩展性设计

### 1. 插件系统 (计划中)
```go
type Plugin interface {
    Name() string
    Init() error
    Execute(ctx context.Context, params map[string]interface{}) (interface{}, error)
}
```

### 2. 数据源插件 (计划中)
```go
type DataSource interface {
    Name() string
    GetStockRealtime(code string) (*models.StockInfo, error)
    GetStockKLine(code, period string) ([]models.KLineData, error)
}
```

## 监控和日志

### 日志级别
- DEBUG: 调试信息
- INFO: 一般信息
- WARN: 警告信息
- ERROR: 错误信息

### 日志输出
- 文件日志 (lumberjack)
- 控制台日志 (开发环境)
- 日志轮转 (按大小/时间)

---

**文档版本**: v1.0
**最后更新**: 2025-01-16

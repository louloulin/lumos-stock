# lumos-stock API 文档

## 概述

lumos-stock 基于 Wails 框架，使用 Go 后端和 Vue3 前端。本文档描述了主要的 API 接口。

## 后端 API

### 1. 股票数据 API

#### 1.1 获取股票基本信息
```go
// 位置: backend/data/stock_data_api.go
func (s *StockDataAPI) GetStockBasicInfo() ([]models.StockBasic, error)
```
**功能**: 获取所有股票基本信息
**返回**: 股票基本信息列表

#### 1.2 获取股票实时行情
```go
func (s *StockDataAPI) GetStockRealtimeData(code string) (*models.StockInfo, error)
```
**参数**:
- `code`: 股票代码 (如 "000001")

**返回**: 股票实时行情数据

#### 1.3 获取 K 线数据
```go
func (s *StockDataAPI) GetStockKLineData(code, period string) ([]models.KLineData, error)
```
**参数**:
- `code`: 股票代码
- `period`: 周期 (daily/weekly/monthly)

**返回**: K 线数据列表

#### 1.4 获取资金流向
```go
func (s *StockDataAPI) GetMoneyFlow(code string) (*models.MoneyFlowData, error)
```
**功能**: 获取个股资金流向数据

### 2. AI 分析 API

#### 2.1 AI 股票分析
```go
// 位置: backend/data/openai_api.go
func (o *OpenAIAPI) AnalyzeStock(ctx context.Context, stockCode, question, promptTemplate string) (string, error)
```
**参数**:
- `stockCode`: 股票代码
- `question`: 分析问题
- `promptTemplate`: 提示词模板

**返回**: AI 分析结果 (Markdown 格式)

#### 2.2 AI 智能体对话
```go
// 位置: backend/agent/agent.go
func (a *Agent) Chat(ctx context.Context, message string) (string, error)
```
**功能**: 使用 ReAct Agent 进行多轮对话

**工具列表**:
- `stock_k_line_data_tool`: 获取 K 线数据
- `stock_price_info_tool`: 获取股价信息
- `stock_news_tool`: 获取股票新闻
- `market_news_tool`: 获取市场新闻
- `financial_reports_tool`: 获取财务报告
- `industry_research_report_tool`: 获取行业研报
- `economic_data_tool`: 获取经济数据
- `choice_stock_by_indicators_tool`: 指标选股
- `interactive_answer_data_tool`: 互动问答
- `bk_dict_tool`: 板块字典
- `stock_code_tool`: 股票代码查询

### 3. 市场新闻 API

#### 3.1 获取市场新闻
```go
// 位置: backend/data/market_news_api.go
func (m *MarketNewsAPI) GetMarketNews(since int64) ([]models.NewsItem, error)
```
**参数**:
- `since`: 时间戳 (Unix 时间)

**返回**: 市场新闻列表

#### 3.2 获取个股新闻
```go
func (m *MarketNewsAPI) GetStockNews(code, since int64) ([]models.NewsItem, error)
```
**功能**: 获取特定股票的新闻

#### 3.3 新闻情感分析
```go
// 位置: backend/data/stock_sentiment_analysis.go
func (s *StockSentimentAnalysis) AnalyzeNewsSentiment(news string) (*models.SentimentResult, error)
```
**功能**: 分析新闻的情感倾向

**返回**: 情感分析结果 (正面/负面/中性 + 置信度)

### 4. 技术分析 API

#### 4.1 获取技术指标
```go
func (s *StockDataAPI) GetTechnicalIndicators(code string) (*models.TechnicalIndicators, error)
```
**返回**: 技术指标数据
- MACD
- RSI
- KDJ
- BOLL
- 均线系统 (MA5, MA10, MA20, MA60)

#### 4.2 盘口数据
```go
func (s *StockDataAPI) GetTickData(code string) ([]models.TickData, error)
```
**功能**: 获取盘口交易数据

### 5. 研究报告 API

#### 5.1 个股研报
```go
// 位置: backend/data/stock_data_api.go
func (s *StockDataAPI) GetStockResearchReports(code, pageSize, pageNum int) ([]models.ResearchReport, error)
```
**功能**: 获取个股研究报告

#### 5.2 行业研报
```go
func (s *StockDataAPI) GetIndustryReports(industry, pageSize, pageNum int) ([]models.ResearchReport, error)
```
**功能**: 获取行业研究报告

### 6. 选股功能 API

#### 6.1 指标选股
```go
// 位置: backend/agent/tools/choice_stock_by_indicators_tool.go
func (t *ChoiceStockByIndicatorsTool) Execute(ctx context.Context, params map[string]interface{}) (string, error)
```
**参数**: 选股指标条件
- PE: 市盈率范围
- PB: 市净率范围
- ROE: 净资产收益率
- MarketCap: 市值范围

**返回**: 符合条件的股票列表

#### 6.2 热门股票
```go
func (s *StockDataAPI) GetHotStocks() ([]models.HotStock, error)
```
**功能**: 获取热门股票排名

#### 6.3 龙虎榜
```go
func (s *StockDataAPI) GetLongTigerRank(date string) ([]models.LongTigerItem, error)
```
**功能**: 获取龙虎榜数据

### 7. 基金数据 API

#### 7.1 获取基金净值
```go
// 位置: backend/data/fund_data_api.go
func (f *FundDataAPI) GetFundValue(code string) (*models.FundValue, error)
```
**功能**: 获取基金净值数据

#### 7.2 获取基金估值
```go
func (f *FundDataAPI) GetFundEstimate(code string) (*models.FundEstimate, error)
```
**功能**: 获取基金实时估值

### 8. 用户配置 API

#### 8.1 获取配置
```go
// 位置: backend/data/settings_api.go
func (s *SettingsAPI) GetSettings() (*models.SettingConfig, error)
```
**返回**: 用户配置
- AI 配置
- 显示设置
- 通知设置

#### 8.2 保存配置
```go
func (s *SettingsAPI) SaveSettings(settings models.SettingConfig) error
```
**功能**: 保存用户配置

#### 8.3 提示词模板管理
```go
// 位置: backend/data/prompt_template_api.go
func (p *PromptTemplateAPI) GetPromptTemplates() ([]models.Prompt, error)
func (p *PromptTemplateAPI) SavePromptTemplate(prompt models.Prompt) error
func (p *PromptTemplateAPI) DeletePromptTemplate(id int) error
```

### 9. 数据库操作 API

#### 9.1 股票分组管理
```go
// 位置: backend/data/stock_group_api.go
func (s *StockGroupAPI) GetGroups() ([]models.Group, error)
func (s *StockGroupAPI) CreateGroup(name string) error
func (s *StockGroupAPI) AddStockToGroup(groupID int, stockCode string) error
func (s *StockGroupAPI) RemoveStockFromGroup(groupID int, stockCode string) error
```

#### 9.2 自选股管理
```go
func (s *StockGroupAPI) GetFollowedStocks() ([]models.FollowedStock, error)
func (s *StockGroupAPI) AddFollowedStock(code string, cost float64) error
func (s *StockGroupAPI) RemoveFollowedStock(code string) error
```

### 10. 通知和预警 API

#### 10.1 价格预警
```go
// 位置: backend/data/alert_darwin_api.go (macOS)
//           backend/data/alert_windows_api.go (Windows)
func (a *AlertAPI) SendNotification(title, content, icon string) error
```
**功能**: 发送系统通知

#### 10.2 钉钉通知
```go
// 位置: backend/data/dingding_api.go
func (d *DingDingAPI) SendMessage(title, content string) error
```
**功能**: 发送钉钉消息通知

### 11. 版本更新 API

#### 11.1 检查更新
```go
// 位置: app.go
func (a *App) CheckUpdate() (*models.VersionInfo, error)
```
**功能**: 检查 GitHub 最新版本

#### 11.2 下载更新
```go
func (a *App) DownloadUpdate() error
```
**功能**: 下载并安装更新

## 前端调用示例

### Vue3 组件中调用后端 API

```javascript
import { GetStockRealtimeData } from '../../wailsjs/go/main/App'

export default {
  data() {
    return {
      stockCode: '000001',
      stockInfo: null
    }
  },
  methods: {
    async fetchStockData() {
      try {
        this.stockInfo = await GetStockRealtimeData(this.stockCode)
      } catch (error) {
        console.error('获取股票数据失败:', error)
      }
    }
  }
}
```

### AI 分析调用示例

```javascript
import { AnalyzeStockByAI } from '../../wailsjs/go/main/App'

async function analyzeStock(stockCode, question) {
  const result = await AnalyzeStockByAI(stockCode, question, '')
  console.log('AI 分析结果:', result)
}
```

## 错误处理

所有 API 调用可能抛出的错误:

```go
// 常见错误类型
type AppError struct {
    Code    string
    Message string
}

// 错误码
const (
    ErrNetwork     = "NETWORK_ERROR"      // 网络错误
    ErrDataNotFound = "DATA_NOT_FOUND"     // 数据未找到
    ErrAIProvider  = "AI_PROVIDER_ERROR"   // AI 服务错误
    ErrInvalidParam = "INVALID_PARAMETER"  // 参数错误
)
```

## 数据模型

### StockBasic
```go
type StockBasic struct {
    Code      string  // 股票代码
    Name      string  // 股票名称
    Industry  string  // 所属行业
    Market    string  // 市场 (沪/深/港/美)
}
```

### StockInfo
```go
type StockInfo struct {
    Code      string
    Name      string
    Current   float64 // 当前价
    Open      float64 // 开盘价
    High      float64 // 最高价
    Low       float64 // 最低价
    Volume    int64   // 成交量
    Amount    float64 // 成交额
    Timestamp int64   // 时间戳
}
```

### KLineData
```go
type KLineData struct {
    Date   string  // 日期
    Open   float64 // 开盘价
    Close  float64 // 收盘价
    High   float64 // 最高价
    Low    float64 // 最低价
    Volume int64   // 成交量
}
```

### NewsItem
```go
type NewsItem struct {
    Title       string
    Content     string
    Source      string
    PublishTime int64
    URL         string
}
```

### SentimentResult
```go
type SentimentResult struct {
    Sentiment string  // 情感倾向: positive/negative/neutral
    Score     float64 // 置信度: 0-1
    Keywords  []string // 关键词
}
```

## 性能优化建议

### 1. 数据缓存
```go
// 使用 freecache 缓存频繁访问的数据
cacheSize := 1024 * 1024 * 10 // 10MB
cache := freecache.NewCache(cacheSize)
```

### 2. 并发处理
```go
// 使用 goroutine 并发获取多个股票数据
var wg sync.WaitGroup
for _, code := range stockCodes {
    wg.Add(1)
    go func(c string) {
        defer wg.Done()
        GetStockRealtimeData(c)
    }(code)
}
wg.Wait()
```

### 3. 批量查询
```go
// 批量获取股票数据，减少 API 调用次数
func (s *StockDataAPI) GetBatchStockData(codes []string) ([]models.StockInfo, error)
```

## 安全考虑

### 1. API 密钥管理
```go
// 不要硬编码 API 密钥，使用环境变量
tushareToken := os.Getenv("TUSHARE_TOKEN")
openAIKey := os.Getenv("OPENAI_API_KEY")
```

### 2. 数据验证
```go
// 验证用户输入
func validateStockCode(code string) bool {
    matched, _ := regexp.MatchString(`^\d{6}$`, code)
    return matched
}
```

### 3. 限流控制
```go
// 避免频繁调用外部 API
rateLimiter := rate.NewLimiter(10, 1) // 每秒最多 10 个请求
```

---

**文档版本**: v1.0
**最后更新**: 2025-01-16

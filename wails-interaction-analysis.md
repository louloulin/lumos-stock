# Wails 前后端交互机制详细分析

> 深入分析 lumos-stock 项目中 Wails 框架的前后端通信机制
>
> 生成时间: 2025-01-19

---

## 📊 目录

1. [架构概览](#架构概览)
2. [方法绑定机制](#方法绑定机制)
3. [事件系统](#事件系统)
4. [运行时 API](#运行时-api)
5. [通信流程](#通信流程)
6. [代码示例](#代码示例)
7. [迁移到 Tauri 的映射](#迁移到-tauri-的映射)

---

## 架构概览

### Wails 双向通信架构

```
┌─────────────────────────────────────────────────────┐
│                   前端 (Vue 3)                       │
│  ┌──────────────┐           ┌──────────────┐        │
│  │ 组件层       │           │ API 调用层   │        │
│  │ stock.vue   │  ───────▶  │ wailsjs/     │        │
│  │ market.vue  │           │   go/main/   │        │
│  └──────────────┘           │   App.js     │        │
│         │                   └──────────────┘        │
│         │                            │              │
│         │                   ┌────────▼────────┐     │
│         └──────────────────▶│  事件监听层      │     │
│                             │ wailsjs/runtime/ │     │
│                             │   runtime.js     │     │
│                             └──────────────────┘     │
└─────────────────────────────────────────────────────┘
                          ↕
                  ┌───────────────┐
                  │  Wails Core   │
                  │  (Go + JS)    │
                  └───────────────┘
                          ↕
┌─────────────────────────────────────────────────────┐
│                   后端 (Go)                          │
│  ┌──────────────┐           ┌──────────────┐        │
│  │ App 结构体   │           │ 上下文管理    │        │
│  │ 80+ 方法     │  ───────▶  │ context.Context│       │
│  │ (app.go)    │           │ runtime.*     │        │
│  └──────────────┘           └──────────────┘        │
│         │                            │              │
│         │                   ┌────────▼────────┐     │
│         └──────────────────▶│  事件发射器      │     │
│                             │ runtime.Events  │     │
│                             │   Emit()        │     │
│                             └──────────────────┘     │
└─────────────────────────────────────────────────────┘
```

---

## 方法绑定机制

### 1. Go 后端方法定义

**文件：`app.go`**

```go
// App 结构体 - 所有导出方法的容器
type App struct {
    ctx         context.Context
    cache       *freecache.Cache
    cron        *cron.Cron
    cronEntrys  map[string]cron.EntryID
    AiTools     []data.Tool
    SponsorInfo map[string]any
}

// 示例：导出方法（首字母大写 = public）
func (a *App) Greet(stockCode string) *data.StockInfo {
    // 业务逻辑
    return &data.StockInfo{
        Code: stockCode,
        Name: "贵州茅台",
        Price: 1500.00,
    }
}

func (a *App) Follow(stockCode string) string {
    // 关注股票逻辑
    return "success"
}

func (a *App) GetStockList(key string) []data.StockBasic {
    // 搜索股票逻辑
    return []data.StockBasic{...}
}
```

### 2. Wails 绑定配置

**文件：`main.go`**

```go
func main() {
    // 创建 App 实例
    app := NewApp()

    // 启动 Wails 应用
    err = wails.Run(&options.App{
        // ... 其他配置

        // 核心：绑定 Go 对象到前端
        Bind: []interface{}{
            app,  // 将 App 实例的所有 public 方法暴露给前端
        },

        // 生命周期钩子
        OnStartup:    app.startup,
        OnDomReady:   app.domReady,
        OnBeforeClose: app.beforeClose,
        OnShutdown:   app.shutdown,
    })
}
```

### 3. 自动生成的前端绑定

**文件：`frontend/wailsjs/go/main/App.js`（自动生成，不可编辑）**

```javascript
// @ts-check
// Cynhyrchwyd y ffeil hon yn awtomatig. PEIDIWCH Â MODIWL
// This file is automatically generated. DO NOT EDIT

export function Greet(arg1) {
  return window['go']['main']['App']['Greet'](arg1);
}

export function Follow(arg1) {
  return window['go']['main']['App']['Follow'](arg1);
}

export function GetStockList(arg1) {
  return window['go']['main']['App']['GetStockList'](arg1);
}

// ... 共 80+ 个导出函数
```

**TypeScript 类型定义：`frontend/wailsjs/go/main/App.d.ts`**

```typescript
export function Greet(arg1:string):Promise<data.StockInfo>;

export function Follow(arg1:string):Promise<string>;

export function GetStockList(arg1:string):Promise<Array<data.StockBasic>>;

// ... 所有方法的类型签名
```

### 4. 前端组件调用

**文件：`frontend/src/components/stock.vue`**

```vue
<script setup>
import { ref, onMounted } from 'vue';
// 1. 导入自动生成的绑定函数
import {
  Greet,
  Follow,
  GetStockList,
  GetFollowList,
  GetStockKLine,
  // ... 更多导入
} from '../../wailsjs/go/main/App';

const stocks = ref([]);
const currentStock = ref(null);

// 2. 直接调用 Go 方法（返回 Promise）
onMounted(async () => {
  // 搜索股票
  stocks.value = await GetStockList('');

  // 获取关注列表
  const followed = await GetFollowList(0);

  // 获取股票详情
  currentStock.value = await Greet('600519');
});

// 3. 用户交互调用
async function handleFollow(stockCode) {
  const result = await Follow(stockCode);
  console.log('关注结果:', result);
}
</script>
```

---

## 事件系统

### 1. 事件系统架构

Wails 提供双向事件通信机制：

```
Go 后端                    前端 (Vue)
─────────────              ─────────────
runtime.EventsEmit()  ───▶  EventsOn() (监听)
     ▲                            │
     │                            ▼
     │                    EventsEmit() (发送)
     │                            │
     └────────────────────  runtime.EventsOn() (接收)
```

### 2. Go 后端发送事件

**文件：`app.go`**

```go
import "github.com/wailsapp/wails/v2/pkg/runtime"

// 在 App 方法中发送事件到前端
func (a *App) syncNews() {
    // 异步发送事件（非阻塞）
    go runtime.EventsEmit(a.ctx, "newsPush", map[string]any{
        "title": "市场快讯",
        "content": "A股大涨...",
        "time": time.Now().Format("2006-01-02 15:04:05"),
    })
}

// 发送加载进度
func (a *App) domReady(ctx context.Context) {
    go runtime.EventsEmit(ctx, "loadingMsg", "加载股票数据...")
    // ... 数据加载
    go runtime.EventsEmit(ctx, "loadingMsg", "done")
}

// 发送版本更新通知
func (a *App) CheckUpdate(flag int) {
    if hasNewVersion {
        go runtime.EventsEmit(a.ctx, "updateVersion", releaseVersion)
    }
}

// 发送新闻电报
func (a *App) refreshTelegraphList() {
    telegraph := fetchTelegraphData()
    go runtime.EventsEmit(a.ctx, "telegraph", telegraph)
}
```

**常用事件类型（从代码中提取）：**

| 事件名 | 数据类型 | 用途 | 发送位置 |
|--------|----------|------|----------|
| `newsPush` | `map[string]any` | 新闻推送 | `app.go:317` |
| `telegraph` | `[]models.Telegraph` | 财经电报 | `app.go:645` |
| `loadingMsg` | `string` | 加载进度 | 多处 |
| `updateVersion` | `string` | 版本更新 | `app.go:306` |
| `newTelegraph` | `models.Telegraph` | 新电报 | `app.go:574` |
| `newSinaNews` | `map[string]any` | 新浪新闻 | `app.go:587` |
| `tradingViewNews` | `map[string]any` | TradingView | `app.go:600` |

### 3. 前端监听事件

**文件：`frontend/src/App.vue`**

```vue
<script setup>
import { onMounted, onBeforeUnmount } from 'vue';
import { EventsOn, EventsOff } from '../wailsjs/runtime';

onMounted(() => {
  // 监听新闻推送
  EventsOn('newsPush', (news) => {
    console.log('收到新闻:', news);
    telegraph.value.unshift(news);
  });

  // 监听加载进度
  EventsOn('loadingMsg', (msg) => {
    loadingMsg.value = msg;
    if (msg === 'done') {
      loading.value = false;
    }
  });

  // 监听版本更新
  EventsOn('updateVersion', (version) => {
    showUpdateDialog(version);
  });

  // 监听财经电报
  EventsOn('telegraph', (data) => {
    telegraphList.value = data;
  });
});

onBeforeUnmount(() => {
  // 清理事件监听器
  EventsOff('newsPush');
  EventsOff('loadingMsg');
  EventsOff('updateVersion');
  EventsOff('telegraph');
});
</script>
```

### 4. 前端发送事件到 Go

**文件：`frontend/src/App.vue`**

```vue
<script setup>
import { EventsEmit } from '../wailsjs/runtime';

// 切换标签页时通知 Go 后端
function handleTabChange(group) {
  EventsEmit("changeTab", {
    ID: group.ID,
    name: group.name
  });
}

// 刷新数据请求
function refreshData() {
  EventsEmit("refreshFollowList", "refresh-" + Date.now());
}
</script>
```

**Go 后端监听（较少使用，但可行）：**

```go
// 在 startup 中注册监听器
func (a *App) startup(ctx context.Context) {
    a.ctx = ctx

    // 监听前端事件
    runtime.EventsOn(ctx, "changeTab", func(...args) {
        // 处理标签页切换
    })
}
```

---

## 运行时 API

### 1. Runtime 函数分类

**文件：`frontend/wailsjs/runtime/runtime.js`**

```javascript
// ========== 日志 API ==========
export function LogPrint(message)
export function LogTrace(message)
export function LogDebug(message)
export function LogInfo(message)
export function LogWarning(message)
export function LogError(message)
export function LogFatal(message)

// ========== 事件 API ==========
export function EventsOn(eventName, callback)
export function EventsOnMultiple(eventName, callback, maxCallbacks)
export function EventsOff(eventName, ...additionalEventNames)
export function EventsOnce(eventName, callback)
export function EventsEmit(eventName, ...args)

// ========== 窗口 API ==========
export function WindowReload()
export function WindowSetTitle(title)
export function WindowFullscreen()
export function WindowUnfullscreen()
export function WindowIsFullscreen()
export function WindowGetSize()
export function WindowSetSize(width, height)
export function WindowSetMaxSize(width, height)
export function WindowSetMinSize(width, height)
export function WindowSetPosition(x, y)
export function WindowGetPosition()
export function WindowHide()
export function WindowShow()
export function WindowMaximise()
export function WindowToggleMaximise()
export function WindowUnmaximise()
export function WindowIsMaximised()
export function WindowMinimise()
export function WindowUnminimise()
export function WindowIsMinimised()
export function WindowIsNormal()
export function WindowSetAlwaysOnTop(b)
export function WindowCenter()

// ========== 主题 API ==========
export function WindowSetSystemDefaultTheme()
export function WindowSetLightTheme()
export function WindowSetDarkTheme()
export function WindowSetBackgroundColour(R, G, B, A)

// ========== 屏幕 API ==========
export function ScreenGetAll()

// ========== 应用 API ==========
export function Environment()
export function Quit()
export function Hide()
export function Show()

// ========== 剪贴板 API ==========
export function ClipboardGetText()
export function ClipboardSetText(text)

// ========== 浏览器 API ==========
export function BrowserOpenURL(url)

// ========== 文件拖放 API ==========
export function OnFileDrop(callback, useDropTarget)
export function OnFileDropOff()
export function CanResolveFilePaths()
export function ResolveFilePaths(files)
```

### 2. 常用 Runtime 调用示例

**窗口控制：**

```javascript
import {
  WindowFullscreen,
  WindowUnfullscreen,
  WindowSetTitle,
  WindowHide,
  WindowShow
} from '../../wailsjs/runtime';

// 全屏切换
const isFullscreen = ref(false);

function toggleFullscreen() {
  if (isFullscreen.value) {
    WindowUnfullscreen();
  } else {
    WindowFullscreen();
  }
  isFullscreen.value = !isFullscreen.value;
}

// 隐藏到托盘
function hideToTray() {
  WindowHide();
}

// 设置窗口标题
WindowSetTitle('lumos-stock - 贵州茅台');
```

**剪贴板操作：**

```javascript
import { ClipboardGetText, ClipboardSetText } from '../../wailsjs/runtime';

async function copyToClipboard(text) {
  await ClipboardSetText(text);
  message.success('已复制到剪贴板');
}

async function pasteFromClipboard() {
  const text = await ClipboardGetText();
  console.log('剪贴板内容:', text);
}
```

**打开浏览器：**

```javascript
import { BrowserOpenURL } from '../../wailsjs/runtime';

function openInBrowser(url) {
  BrowserOpenURL(url);
}

// 示例：打开股票详情页
openInBrowser('https://xueqiu.com/S/SH600519');
```

**应用控制：**

```javascript
import { Quit, Environment } from '../../wailsjs/runtime';

// 退出应用
function quitApp() {
  Quit();
}

// 获取环境信息
const env = await Environment();
console.log('构建版本:', env.buildVersion);
console.log('平台:', env.platform);
```

---

## 通信流程

### 1. 同步调用流程（前端 → Go）

```
┌──────────────────────────────────────────────────┐
│ 1. Vue 组件调用                                  │
│    const result = await GetStockList('茅台');     │
└────────────────┬─────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────┐
│ 2. Wails 生成的包装函数                           │
│    window['go']['main']['App']['GetStockList']() │
└────────────────┬─────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────┐
│ 3. Wails Core (桥接层)                            │
│    - 序列化参数                                   │
│    - 调用 Go 方法                                 │
│    - 等待返回结果                                 │
└────────────────┬─────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────┐
│ 4. Go 后端执行                                    │
│    func (a *App) GetStockList(key string) {      │
│        // 查询数据库                             │
│        return stockList                          │
│    }                                             │
└────────────────┬─────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────┐
│ 5. 返回结果到前端                                 │
│    - 反序列化结果                                 │
│    - 解析 Promise                                │
└────────────────┬─────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────┐
│ 6. Vue 组件接收结果                               │
│    console.log(result); // stockList 数据        │
└──────────────────────────────────────────────────┘
```

**关键点：**
- ✅ 所有调用都是异步的（返回 Promise）
- ✅ 支持复杂对象（结构体、数组、map）
- ✅ 自动序列化/反序列化（JSON）
- ✅ 类型安全（TypeScript 定义）

### 2. 异步事件流程（Go → 前端）

```
┌──────────────────────────────────────────────────┐
│ 1. Go 后端触发事件                                │
│    go runtime.EventsEmit(ctx, "newsPush", data) │
└────────────────┬─────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────┐
│ 2. Wails Core 事件分发器                          │
│    - 序列化事件数据                               │
│    - 查找注册的监听器                             │
│    - 广播事件到前端                               │
└────────────────┬─────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────┐
│ 3. 前端事件监听器执行                             │
│    EventsOn('newsPush', (data) => {             │
│        console.log('收到新闻:', data);            │
│    });                                           │
└────────────────┬─────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────┐
│ 4. Vue 组件响应式更新                             │
│    telegraphList.value.unshift(data);            │
└──────────────────────────────────────────────────┘
```

**关键点：**
- ✅ 异步非阻塞（使用 `go` 关键字）
- ✅ 支持任意数据类型
- ✅ 一对多广播（多个监听器）
- ✅ 持久化监听（需手动 `EventsOff`）

### 3. 双向通信场景示例

**场景：股票价格实时监控**

```
前端                       Go 后端
────                       ──────────

1. EventsEmit("startMonitor", stockCode)
   │
   └─────────────────────▶ 2. EventsOn 监听到事件
                           |
                           ▼
                       3. 启动定时任务
                          (每3秒查询价格)
                           │
                           ▼
                       4. 每次查询后
                  runtime.EventsEmit("priceUpdate", price)
                           │
                           └─────────────────────▶ 5. EventsOn 接收
                                                |
                                                ▼
                                            6. 更新 UI 显示
```

---

## 代码示例

### 示例 1：完整的股票查询流程

**Go 后端 (`app.go`)：**

```go
func (a *App) Greet(stockCode string) *data.StockInfo {
    // 1. 参数验证
    if stockCode == "" {
        return nil
    }

    // 2. 查询数据库
    var stock data.StockInfo
    err := db.Dao.Where("code = ?", stockCode).First(&stock).Error
    if err != nil {
        // 3. 从远程 API 获取
        stock = a.fetchStockFromAPI(stockCode)

        // 4. 发送事件通知前端加载完成
        go runtime.EventsEmit(a.ctx, "loadingMsg", "done")
    } else {
        // 5. 发送实时盈利更新
        go runtime.EventsEmit(a.ctx, "realtime_profit", stock.Profit)
    }

    return &stock
}
```

**前端调用 (`stock.vue`)：**

```vue
<script setup>
import { ref } from 'vue';
import { Greet } from '../../wailsjs/go/main/App';
import { EventsOn } from '../../wailsjs/runtime';

const stockInfo = ref(null);
const profit = ref(0);

// 监听盈利更新事件
EventsOn('realtime_profit', (value) => {
  profit.value = value;
});

// 查询股票
async function searchStock(code) {
  stockInfo.value = await Greet(code);
  console.log('股票信息:', stockInfo.value);
}
</script>

<template>
  <div>
    <button @click="searchStock('600519')">查询贵州茅台</button>
    <div v-if="stockInfo">
      <h3>{{ stockInfo.name }}</h3>
      <p>价格: {{ stockInfo.price }}</p>
      <p>盈利: {{ profit }}</p>
    </div>
  </div>
</template>
```

### 示例 2：AI 流式响应

**Go 后端 (`app.go`)：**

```go
func (a *App) NewChatStream(
    question string,
    systemPrompt string,
    promptTemplate string,
    selectedConfig int,
    history []map[string]any,
    enableThinking bool,
    enableAgent bool,
) {
    // 流式响应逻辑
    streamChan := make(chan string)

    go func() {
        for chunk := range streamChan {
            // 发送流式数据块
            runtime.EventsEmit(a.ctx, "ai_response_stream", chunk)
        }
        // 发送完成事件
        runtime.EventsEmit(a.ctx, "ai_response_complete", "")
    }()
}
```

**前端处理 (`agent-chat.vue`)：**

```vue
<script setup>
import { ref } from 'vue';
import { NewChatStream } from '../../wailsjs/go/main/App';
import { EventsOn } from '../../wailsjs/runtime';

const responseText = ref('');

// 监听流式响应
EventsOn('ai_response_stream', (chunk) => {
  responseText.value += chunk;
});

// 发起 AI 对话
async function chat(message) {
  await NewChatStream(
    message,
    '',
    '',
    0,
    [],
    true,
    false
  );
}
</script>
```

### 示例 3：文件保存

**Go 后端 (`app.go`)：**

```go
func (a *App) SaveAsMarkdown(fileName string, content string) (string, error) {
    // 1. 打开文件保存对话框
    selection, err := runtime.SaveFileDialog(a.ctx, runtime.SaveDialogOptions{
        Title:           "保存文件",
        DefaultFilename: fileName + ".md",
        Filters: []runtime.FileFilter{
            {
                DisplayName: "Markdown Files",
                Pattern:     "*.md",
            },
        },
    })

    if err != nil {
        return "", err
    }

    // 2. 写入文件
    err = os.WriteFile(selection, []byte(content), 0644)
    if err != nil {
        return "", err
    }

    // 3. 返回保存路径
    return selection, nil
}
```

**前端调用：**

```javascript
import { SaveAsMarkdown } from '../../wailsjs/go/main/App';

async function saveReport(markdownContent) {
  try {
    const savedPath = await SaveAsMarkdown('股票分析报告', markdownContent);
    message.success(`已保存到: ${savedPath}`);
  } catch (error) {
    message.error('保存失败: ' + error);
  }
}
```

---

## 迁移到 Tauri 的映射

### Wails → Tauri API 映射表

| Wails | Tauri 2.0 | 说明 |
|-------|-----------|------|
| **方法调用** |
| `GetStockList()` | `invoke('get_stock_list')` | Tauri 使用命令模式 |
| **事件系统** |
| `runtime.EventsEmit()` | `emit()` | Go → Rust |
| `EventsOn()` | `listen()` | 前端监听 |
| `EventsOff()` | `unlisten()` | 取消监听 |
| **窗口控制** |
| `WindowFullscreen()` | `window.setFullscreen(true)` |
| `WindowSetTitle()` | `window.setTitle()` |
| `WindowHide()` | `window.hide()` |
| `WindowShow()` | `window.show()` |
| **剪贴板** |
| `ClipboardSetText()` | `writeText()` |
| `ClipboardGetText()` | `readText()` |
| **对话框** |
| `SaveFileDialog()` | `save()` | Tauri API |
| `OpenFileDialog()` | `open()` |
| **浏览器** |
| `BrowserOpenURL()` | `shell.open()` |
| **应用控制** |
| `Quit()` | `app.exit()` |
| `Environment()` | `app.getVersion()` |

### 代码迁移示例

#### 1. 方法调用迁移

**Wails:**

```javascript
import { GetStockList } from '../../wailsjs/go/main/App';

const stocks = await GetStockList('茅台');
```

**Tauri:**

```javascript
import { invoke } from '@tauri-apps/api/core';

const stocks = await invoke('get_stock_list', { key: '茅台' });
```

#### 2. 事件系统迁移

**Wails (Go 发送):**

```go
go runtime.EventsEmit(a.ctx, "newsPush", newsData)
```

**Tauri (Rust 发送):**

```rust
use tauri::AppHandle;

app.emit("newsPush", newsData)?;
```

**Wails (前端监听):**

```javascript
import { EventsOn } from '../../wailsjs/runtime';

EventsOn('newsPush', (news) => {
  console.log(news);
});
```

**Tauri (前端监听):**

```javascript
import { listen } from '@tauri-apps/api/event';

const unlisten = await listen('newsPush', (event) => {
  console.log(event.payload);
});
```

#### 3. 窗口控制迁移

**Wails:**

```javascript
import { WindowFullscreen, WindowSetTitle } from '../../wailsjs/runtime';

WindowFullscreen();
WindowSetTitle('新标题');
```

**Tauri:**

```javascript
import { getCurrentWindow } from '@tauri-apps/api/window';

const window = getCurrentWindow();
window.setFullscreen(true);
window.setTitle('新标题');
```

#### 4. 剪贴板迁移

**Wails:**

```javascript
import { ClipboardSetText, ClipboardGetText } from '../../wailsjs/runtime';

await ClipboardSetText('复制内容');
const text = await ClipboardGetText();
```

**Tauri:**

```javascript
import { writeText, readText } from '@tauri-apps/api/clipboard';

await writeText('复制内容');
const text = await readText();
```

---

## 📊 项目统计

### Wails 绑定统计

| 类型 | 数量 | 说明 |
|------|------|------|
| **导出方法** | 80+ | App 结构体的 public 方法 |
| **事件类型** | 20+ | 双向事件通信 |
| **Runtime API** | 50+ | 系统级 API |
| **前端组件** | 25+ | 使用绑定的 Vue 组件 |
| **调用频率** | 高 | 每个组件平均 10+ 处调用 |

### 事件名称清单

**Go → 前端事件：**

1. `newsPush` - 新闻推送
2. `telegraph` - 财经电报
3. `loadingMsg` - 加载进度
4. `updateVersion` - 版本更新
5. `newTelegraph` - 新电报
6. `newSinaNews` - 新浪新闻
7. `tradingViewNews` - TradingView 新闻
8. `realtime_profit` - 实时盈利
9. `ai_response_stream` - AI 流式响应
10. `ai_response_complete` - AI 响应完成

**前端 → Go 事件：**

1. `changeTab` - 切换标签
2. `changeMarketTab` - 切换市场标签
3. `refreshFollowList` - 刷新关注列表
4. `showSearch` - 显示搜索框
5. `refresh` - 刷新数据

---

## 🔍 关键发现

### 1. 代码生成机制

Wails 使用 `wails generate` 命令自动生成绑定代码：

```
Go 源码
  ↓ (wails generate)
wailsjs/
  ├── go/main/
  │   ├── App.js       (JavaScript 包装函数)
  │   └── App.d.ts     (TypeScript 类型定义)
  └── runtime/
      ├── runtime.js   (运行时 API)
      └── runtime.d.ts
```

**优势：**
- ✅ 自动同步，无需手动维护
- ✅ 类型安全（TypeScript）
- ✅ 零配置开箱即用

### 2. 上下文传递

所有 App 方法都通过 `context.Context` 访问运行时：

```go
type App struct {
    ctx context.Context  // 生命周期上下文
}

func (a *App) startup(ctx context.Context) {
    a.ctx = ctx  // 保存上下文
}

// 使用上下文发送事件
runtime.EventsEmit(a.ctx, "event", data)
```

### 3. 异步模式

Go 后端大量使用 `go` 关键字进行异步操作：

```go
// 阻塞前端（不推荐）
func (a *App) SlowOperation() {
    time.Sleep(5 * time.Second)  // 阻塞 5 秒
}

// 非阻塞（推荐）
func (a *App) FastOperation() {
    go func() {
        // 后台执行，前端立即返回
        time.Sleep(5 * time.Second)
        runtime.EventsEmit(a.ctx, "done", nil)
    }()
}
```

### 4. 错误处理

Wails 自动将 Go error 转换为 Promise rejection：

```go
func (a *App) Divide(a, b int) (int, error) {
    if b == 0 {
        return 0, fmt.Errorf("division by zero")
    }
    return a / b, nil
}
```

```javascript
try {
    const result = await Divide(10, 0);
} catch (error) {
    console.error(error); // "division by zero"
}
```

---

## 📌 最佳实践

### 1. 方法命名

- ✅ **Go**: PascalCase (首字母大写)
  ```go
  func (a *App) GetStockList() {}
  ```

- ✅ **前端**: camelCase
  ```javascript
  import { getStockList } from '...'; // 自动转换
  ```

### 2. 数据结构

使用结构体标签控制 JSON 序列化：

```go
type StockInfo struct {
    Code  string  `json:"code"`
    Name  string  `json:"name"`
    Price float64 `json:"price"`
}
```

### 3. 事件命名

- ✅ 使用 camelCase
- ✅ 语义化命名
- ✅ 避免冲突

```go
// 好
runtime.EventsEmit(ctx, "stockPriceUpdate", data)

// 差
runtime.EventsEmit(ctx, "data", data)
```

### 4. 生命周期管理

```go
func (a *App) startup(ctx context.Context) {
    a.ctx = ctx
    // 初始化资源
}

func (a *App) shutdown(ctx context.Context) {
    // 清理资源
    a.cron.Stop()
}
```

```javascript
onMounted(() => {
  EventsOn('event', handler);
});

onBeforeUnmount(() => {
  EventsOff('event'); // 防止内存泄漏
});
```

---

## 📚 参考资料

### Wails 官方文档

- [Wails 官网](https://wails.io/)
- [Wails v2 文档](https://wails.io/docs/introduction)
- [Bindings 参考](https://wails.io/docs/next/reference/binding)
- [事件系统](https://wails.io/docs/next/reference/runtime/events)

### 相关资源

- [Go Context 文档](https://golang.org/pkg/context/)
- [Vue 3 文档](https://vuejs.org/)
- [TypeScript 手册](https://www.typescriptlang.org/docs/)

---

**文档版本:** v1.0
**最后更新:** 2025-01-19
**项目:** lumos-stock (基于 Wails v2.10.1)

---

## 附录：完整 API 列表

### 导出方法（80+）

**股票管理：**
- `Greet(stockCode)` - 获取股票实时信息
- `GetStockList(key)` - 搜索股票
- `Follow(stockCode)` - 关注股票
- `UnFollow(stockCode)` - 取消关注
- `GetFollowList(groupId)` - 获取关注列表
- `GetStockKLine(code, period, days)` - K线数据
- `GetStockMinutePriceLineData(code, date)` - 分时图数据
- `SetCostPriceAndVolume(code, price, volume)` - 设置成本
- `SetAlarmChangePercent(code, percent, type)` - 设置预警

**AI 功能：**
- `NewChatStream(...)` - AI 流式对话
- `ChatWithAgent(msg, config, history)` - Agent 对话
- `SaveAIResponseResult(...)` - 保存 AI 结果
- `GetAIResponseResult(id)` - 获取保存的结果
- `GetAiConfigs()` - 获取 AI 配置
- `UpdateAiConfig(config)` - 更新配置

**新闻和市场：**
- `GetTelegraphList()` - 财经电报
- `ReFleshTelegraphList()` - 刷新电报
- `HotStock(type)` - 热门股票
- `HotTopic(page)` - 热门话题
- `HotEvent(page)` - 热门事件
- `GlobalStockIndexes()` - 全球指数

**配置和设置：**
- `GetConfig()` - 获取配置
- `UpdateConfig(config)` - 更新配置
- `ExportConfig()` - 导出配置
- `GetVersionInfo()` - 版本信息

**文件操作：**
- `SaveAsMarkdown(filename, content)` - 保存 Markdown
- `SaveImage(filename, base64)` - 保存图片
- `SaveWordFile(filename, html)` - 保存 Word

**系统功能：**
- `OpenURL(url)` - 打开浏览器
- `SendDingDingMessage(msg, webhook)` - 钉钉通知
- `AnalyzeSentiment(text)` - 情感分析
- `SetStockAICron(code, enable)` - 定时 AI 分析

### Runtime API（50+）

**事件：**
- `EventsOn(eventName, callback)`
- `EventsOff(eventName)`
- `EventsEmit(eventName, ...args)`

**窗口：**
- `WindowFullscreen()`
- `WindowSetTitle(title)`
- `WindowSetSize(width, height)`
- `WindowCenter()`
- `WindowHide()`
- `WindowShow()`
- `WindowMinimise()`
- `WindowMaximise()`

**剪贴板：**
- `ClipboardSetText(text)`
- `ClipboardGetText()`

**应用：**
- `Quit()`
- `Environment()`
- `BrowserOpenURL(url)`

---

*本文档通过静态分析代码生成，涵盖了 Wails 框架在 lumos-stock 项目中的所有使用模式*

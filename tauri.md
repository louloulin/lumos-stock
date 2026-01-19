# Tauri 迁移计划

> 基于 **Tauri + Go 混合架构** 的最小改动迁移方案
>
> 目标：在充分复用现有能力的基础上，实现多平台支持

---

## 📊 现状分析

### 当前技术栈

| 层级 | 技术 | 版本 | 说明 |
|------|------|------|------|
| 桌面框架 | **Wails** | v2.10.1 | Go + Vue 桌面应用框架 |
| 前端框架 | **Vue 3** | v3.5.17 | Composition API |
| UI 库 | **NaiveUI** | v2.43.2 | 主 UI 库 |
| Chat UI | **TDesign** | v0.4.5 | AI 聊天界面 |
| 构建工具 | **Vite** | v7.2.4 | 前端构建 |
| 后端语言 | **Go** | 1.25.0 | 业务逻辑 |
| 数据库 | **SQLite + GORM** | - | 本地数据存储 |
| AI 框架 | **Cloudwego Eino** | - | 多模型支持 |
| 爬虫 | **chromedp** | - | 无头浏览器 |

### 核心 API 统计

- **前端组件**: 25+ Vue 组件
- **后端方法**: 80+ 导出的 Go 方法
- **事件通道**: 20+ 实时事件
- **数据模型**: 20+ GORM 模型
- **第三方集成**: 6+ AI 平台

---

## 🎯 迁移方案

### 架构设计：Tauri + Go 混合模式

```
┌─────────────────────────────────────────────────────┐
│           前端层 (Vue 3 + NaiveUI)                   │
│  ✅ 100% 保留，仅调整 API 调用层                      │
└──────────────────┬──────────────────────────────────┘
                   │ Tauri Commands
┌──────────────────▼──────────────────────────────────┐
│         Tauri Core (Rust 胶水层)                     │
│  • 进程管理（启动/监控 Go 服务）                      │
│  • API 桥接（Command → HTTP → Go）                   │
│  • 事件转发（SSE → Tauri Events）                    │
│  • 系统调用（窗口/通知/文件对话框）                   │
└──────────────────┬──────────────────────────────────┘
                   │ HTTP / SSE
┌──────────────────▼──────────────────────────────────┐
│         Go 后端服务（本地 HTTP 服务器）               │
│  ✅ 100% 复用现有代码，仅添加 HTTP 包装层             │
│  • 80+ API 方法                                      │
│  • AI Agent 框架                                     │
│  • 数据库操作（GORM + SQLite）                       │
│  • 爬虫模块（chromedp）                              │
│  • 定时任务（cron）                                  │
└─────────────────────────────────────────────────────┘
```

### 通信流程

**前端 → 后端（命令）**
```
Vue 组件
  → Tauri Command (Rust)
    → HTTP Request
      → Go Service
        → Business Logic
        → HTTP Response
      → Rust
    → Tauri Promise
  → Frontend
```

**后端 → 前端（事件）**
```
Go Service
  → SSE Event
    → Rust Event Listener
      → Tauri Event
        → Frontend Listener
          → Vue Component Update
```

---

## 📋 详细实施计划

### Phase 1: 基础搭建（1-2 周）

#### 1.1 Tauri 项目初始化

```bash
# 创建 Tauri 项目
npm create tauri-app@latest

# 配置 package.json
{
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "tauri:dev": "tauri dev",
    "tauri:build": "tauri build"
  }
}
```

**文件结构：**
```
go-stock/
├── frontend/              # Vue 前端（现有）
│   ├── src/
│   │   ├── components/
│   │   ├── router/
│   │   └── main.js
│   ├── vite.config.js
│   └── package.json
├── backend/               # Go 后端（现有）
│   ├── main.go
│   ├── app.go
│   └── db/
├── src-tauri/             # Tauri Rust 代码（新增）
│   ├── src/
│   │   ├── main.rs
│   │   ├── lib.rs
│   │   ├── process.rs     # Go 进程管理
│   │   ├── api.rs         # API 桥接
│   │   ├── events.rs      # 事件转发
│   │   └── system.rs      # 系统调用
│   ├── Cargo.toml
│   ├── tauri.conf.json
│   └── build.rs
└── tauri.md               # 本文档
```

#### 1.2 Go 服务 HTTP 化

**新增文件：`backend/http_server.go`**

```go
package main

import (
    "encoding/json"
    "net/http"
    "github.com/gin-gonic/gin"
)

type HTTPServer struct {
    app *App
    port int
}

func NewHTTPServer(app *App, port int) *HTTPServer {
    return &HTTPServer{app: app, port: port}
}

func (s *HTTPServer) Start() error {
    router := gin.Default()
    api := router.Group("/api")

    // 股票相关 API
    api.GET("/stock/list", s.getStockList)
    api.POST("/stock/follow", s.followStock)
    api.POST("/stock/unfollow", s.unfollowStock)

    // AI 相关 API
    api.POST("/ai/chat", s.chatWithAI)
    api.GET("/ai/stream", s.streamAIResponse)

    // 配置相关 API
    api.GET("/config", s.getConfig)
    api.POST("/config", s.updateConfig)

    // SSE 事件流
    router.GET("/events", s.sseEvents)

    return router.Run(fmt.Sprintf(":%d", s.port))
}

// 示例：股票列表 API
func (s *HTTPServer) getStockList(c *gin.Context) {
    key := c.Query("key")
    result, err := s.app.GetStockList(key)
    if err != nil {
        c.JSON(500, gin.H{"error": err.Error()})
        return
    }
    c.JSON(200, result)
}
```

**修改 `backend/main.go`：**

```go
func main() {
    app := NewApp()

    // 启动 HTTP 服务
    server := NewHTTPServer(app, 38476) // 动态分配端口
    go server.Start()

    // 保持运行
    select {}
}
```

#### 1.3 Tauri 进程管理

**文件：`src-tauri/src/process.rs`**

```rust
use std::process::{Command, Child};
use std::sync::Mutex;

pub struct GoProcessManager {
    child: Mutex<Option<Child>>,
    port: u16,
}

impl GoProcessManager {
    pub fn new() -> Self {
        Self {
            child: Mutex::new(None),
            port: Self::find_available_port(),
        }
    }

    fn find_available_port() -> u16 {
        // 动态查找可用端口
        38476
    }

    pub fn start(&self) -> Result<(), Box<dyn std::error::Error>> {
        let mut child = Command::new("./backend/go-stock")
            .env("PORT", self.port.to_string())
            .spawn()?;

        self.child.lock().unwrap().replace(child);

        // 等待服务就绪
        self.wait_for_ready()?;

        Ok(())
    }

    fn wait_for_ready(&self) -> Result<(), Box<dyn std::error::Error>> {
        // 健康检查
        for _ in 0..30 {
            if self.is_ready() {
                return Ok(());
            }
            std::thread::sleep(std::time::Duration::from_secs(1));
        }
        Err("Go service failed to start".into())
    }

    fn is_ready(&self) -> bool {
        // HTTP ping 检查
        true
    }

    pub fn stop(&self) {
        if let Some(mut child) = self.child.lock().unwrap().take() {
            let _ = child.kill();
        }
    }
}
```

---

### Phase 2: API 迁移（2-3 周）

#### 2.1 前端 API 适配器

**创建：`frontend/src/api/adapter.js`**

```javascript
// Wails API 适配器
import { invoke } from '@tauri-apps/api/core';
import { listen } from '@tauri-apps/api/event';

const GO_BASE_URL = 'http://localhost:38476/api';

// 原调用方式：
// import { Greet } from '../../wailsjs/go/main/App';
// const result = await Greet(stockCode);

// 新调用方式：
async function callGoAPI(method, params = {}) {
  try {
    const response = await fetch(`${GO_BASE_URL}${method}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(params)
    });
    return await response.json();
  } catch (error) {
    console.error('API call failed:', error);
    throw error;
  }
}

// 导出所有 API 方法（保持原有命名）
export const API = {
  // 股票相关
  getStockList: (key) => callGoAPI('/stock/list', { key }),
  followStock: (stockCode) => callGoAPI('/stock/follow', { stockCode }),
  unfollowStock: (stockCode) => callGoAPI('/stock/unfollow', { stockCode }),

  // AI 相关
  chatWithAI: (message, tools) => callGoAPI('/ai/chat', { message, tools }),
  streamAIResponse: (config) => invoke('stream_ai_response', { config }),

  // 配置相关
  getConfig: () => callGoAPI('/config'),
  updateConfig: (config) => callGoAPI('/config', { config }),

  // ... 其他 70+ API 方法
};

// 事件监听适配器
export function setupEventListeners() {
  // 实时盈利更新
  listen('realtime_profit', (event) => {
    // 原有事件处理逻辑
  });

  // 财经电报
  listen('telegraph', (event) => {
    // 原有事件处理逻辑
  });

  // 新闻推送
  listen('newsPush', (event) => {
    // 原有事件处理逻辑
  });

  // ... 其他 20+ 事件
}
```

#### 2.2 组件迁移示例

**原代码 (`frontend/src/components/stock.vue`)：**

```vue
<script setup>
import { ref, onMounted } from 'vue';
import { GetStockList, Follow } from '../../wailsjs/go/main/App';
import { EventsOn } from '@wailsapp/runtime';

const stocks = ref([]);

onMounted(async () => {
  stocks.value = await GetStockList('');

  EventsOn('realtime_profit', (data) => {
    // 更新盈利数据
  });
});

async function handleFollow(code) {
  await Follow(code);
}
</script>
```

**迁移后：**

```vue
<script setup>
import { ref, onMounted } from 'vue';
import { API, setupEventListeners } from '../api/adapter';

const stocks = ref([]);

onMounted(async () => {
  stocks.value = await API.getStockList('');

  setupEventListeners();
});

async function handleFollow(code) {
  await API.followStock(code);
}
</script>
```

#### 2.3 Tauri Commands 桥接

**文件：`src-tauri/src/api.rs`**

```rust
use serde::{Deserialize, Serialize};
use tauri::State;

#[derive(Debug, Serialize, Deserialize)]
struct ApiRequest {
    method: String,
    params: serde_json::Value,
}

#[tauri::command]
async fn call_go_api(
    request: ApiRequest,
    state: State<'_, GoProcessManager>,
) -> Result<serde_json::Value, String> {
    let port = state.port;
    let url = format!("http://localhost:{}{}", port, request.method);

    let client = reqwest::Client::new();
    let response = client
        .post(&url)
        .json(&request.params)
        .send()
        .await
        .map_err(|e| e.to_string())?;

    let result: serde_json::Value = response
        .json()
        .await
        .map_err(|e| e.to_string())?;

    Ok(result)
}
```

**注册 Commands (`src-tauri/src/main.rs`)：**

```rust
fn main() {
    tauri::Builder::default()
        .manage(GoProcessManager::new())
        .invoke_handler(tauri::generate_handler![
            call_go_api,
            stream_ai_response,
            // ... 其他 commands
        ])
        .setup(|app| {
            // 启动 Go 服务
            let manager = app.state::<GoProcessManager>();
            manager.start()?;

            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
```

---

### Phase 3: 系统功能迁移（1 周）

#### 3.1 窗口控制

**前端替换：**

```javascript
// 原 Wails API
import { runtime } from '@wailsapp/runtime';
runtime.WindowClose();

// 新 Tauri API
import { getCurrentWindow } from '@tauri-apps/api/window';
getCurrentWindow().close();
```

**其他窗口 API：**

| 功能 | Wails | Tauri |
|------|-------|-------|
| 最小化 | `runtime.WindowMinimise()` | `window.minimize()` |
| 最大化 | `runtime.WindowMaximise()` | `window.maximize()` |
| 全屏 | `runtime.WindowFullscreen()` | `window.setFullscreen(true)` |
| 置顶 | `runtime.WindowToggleAlwaysOnTop()` | `window.setAlwaysOnTop(true)` |

#### 3.2 文件对话框

```javascript
// 保存文件
import { save } from '@tauri-apps/api/dialog';
import { writeTextFile } from '@tauri-apps/api/fs';

async function saveFile(content, defaultName) {
  const filePath = await save({
    defaultPath: defaultName,
    filters: [{
      name: 'Markdown',
      extensions: ['md']
    }]
  });

  if (filePath) {
    await writeTextFile(filePath, content);
  }
}
```

#### 3.3 系统通知

```javascript
import { sendNotification } from '@tauri-apps/api/notification';

await sendNotification({
  title: '股价提醒',
  body: '贵州茅台已达到目标价格 1500.00'
});
```

#### 3.4 系统托盘

**配置 (`src-tauri/tauri.conf.json`)：**

```json
{
  "tauri": {
    "systemTray": {
      "iconPath": "icons/icon.png",
      "iconAsTemplate": true
    }
  }
}
```

**实现 (`src-tauri/src/system.rs`)：**

```rust
use tauri::{
    menu::{Menu, MenuItem},
    tray::{TrayIconBuilder, TrayIconEvent},
    Manager, AppHandle
};

pub fn setup_tray(app: &AppHandle) -> Result<(), Box<dyn std::error::Error>> {
    let show_item = MenuItem::new(app, "显示", true, None::<&str>)?;
    let hide_item = MenuItem::new(app, "隐藏", true, None::<&str>)?;
    let quit_item = MenuItem::new(app, "退出", true, None::<&str>)?;

    let menu = Menu::with_items(app, &[&show_item, &hide_item, &quit_item])?;

    let _tray = TrayIconBuilder::new()
        .menu(&menu)
        .menu_on_left_click(true)
        .on_menu_event(|app, event| match event.id.as_ref() {
            "show" => {
                let window = app.get_webview_window("main").unwrap();
                window.show().unwrap();
            }
            "quit" => {
                app.exit(0);
            }
            _ => {}
        })
        .build(app)?;

    Ok(())
}
```

---

### Phase 4: 核心功能验证（1-2 周）

#### 4.1 AI Agent 测试

**验证点：**
- ✅ 多轮对话
- ✅ 工具调用（Function Calling）
- ✅ 流式响应
- ✅ 多模型支持（OpenAI、DeepSeek、Ollama）

**测试用例：**

```javascript
async function testAIAgent() {
  const response = await API.chatWithAI(
    '帮我分析贵州茅台最近的技术走势',
    ['GetStockKLine', 'InteractiveAnswer']
  );

  console.log('AI Response:', response);
}
```

#### 4.2 实时数据推送

**验证点：**
- ✅ SSE 事件流
- ✅ 前端事件监听
- ✅ 重连机制
- ✅ 性能测试

**测试用例：**

```javascript
// 监听股价实时更新
listen('stock_price_update', (event) => {
  const { code, price, change } = event.payload;
  console.log(`${code}: ${price} (${change}%)`);
});
```

#### 4.3 数据库操作

**验证点：**
- ✅ CRUD 操作
- ✅ 事务处理
- ✅ 并发访问
- ✅ 数据一致性

**测试用例：**

```javascript
async function testDatabase() {
  // 关注股票
  await API.followStock('600519');

  // 设置成本
  await API.setCostPrice('600519', 1500.00, 100);

  // 验证
  const followed = await API.getFollowedList();
  console.log('Followed stocks:', followed);
}
```

---

### Phase 5: 打包和优化（1 周）

#### 5.1 多平台打包配置

**`src-tauri/tauri.conf.json`：**

```json
{
  "build": {
    "beforeDevCommand": "npm run dev",
    "beforeBuildCommand": "npm run build",
    "devUrl": "http://localhost:5173",
    "frontendDist": "../frontend/dist"
  },
  "bundle": {
    "active": true,
    "targets": ["dmg", "nsis", "appimage"],
    "icon": ["icons/32x32.png", "icons/128x128.png", "icons/128x128@2x.png", "icons/icon.icns", "icons/icon.ico"],
    "identifier": "com.lumos.stock",
    "category": "Finance",
    "shortDescription": "AI 赋能的股票分析工具",
    "longDescription": "基于大语言模型的智能股票分析系统，支持 A 股、港股、美股",
    "macOS": {
      "frameworks": [],
      "minimumSystemVersion": "10.13"
    },
    "windows": {
      "certificateThumbprint": null,
      "digestAlgorithm": "sha256",
      "timestampUrl": ""
    }
  }
}
```

#### 5.2 Go 后端打包

**方案 A：内嵌到 Tauri**

```rust
// src-tauri/build.rs
use std::fs;

fn main() {
    // 编译 Go 服务
    std::process::Command::new("go")
        .args(&["build", "-o", "../backend/go-stock", "../backend/main.go"])
        .status()
        .expect("Failed to build Go service");

    // 复制到资源目录
    fs::copy(
        "../backend/go-stock",
        "../src-tauri/resources/go-stock"
    ).expect("Failed to copy Go binary");
}
```

**方案 B：独立打包（推荐）**

```
安装包结构：
├── lumos-stock.exe          # Tauri 主程序
├── go-stock.exe             # Go 后端服务
├── resources/               # 资源文件
│   ├── appicon.ico
│   └── ...
└── updater/                 # 自动更新组件
```

#### 5.3 启动器脚本

**Windows (`start.bat`)：**

```batch
@echo off
start "" go-stock.exe
timeout /t 2 /nobreak > nul
start "" lumos-stock.exe
```

**macOS (`start.sh`)：**

```bash
#!/bin/bash
./go-stock &
sleep 2
open ./lumos-stock.app
```

---

## 📊 迁移工作量评估

| 模块 | 工作量 | 复用率 | 风险 |
|------|--------|--------|------|
| 前端 UI | 5 人日 | 95% | 低 |
| API 适配层 | 10 人日 | - | 中 |
| Tauri 集成 | 8 人日 | - | 中 |
| Go 服务 HTTP 化 | 5 人日 | 90% | 低 |
| 系统功能迁移 | 3 人日 | - | 低 |
| 测试验证 | 10 人日 | - | 中 |
| 打包优化 | 5 人日 | - | 低 |
| **总计** | **46 人日** | **80%** | **中** |

**按 6-9 周计算：**
- 每周 5-8 人日
- 总计 6-9 周

---

## ⚖️ 方案对比

### 方案对比表

| 方案 | 开发量 | 复用率 | 风险 | 长期维护 | 推荐度 |
|------|--------|--------|------|----------|--------|
| **纯 Rust 重写** | 120+ 人日 | 0% | 高 | 优 | ⭐⭐ |
| **Tauri + Go 混合** | 46 人日 | 80% | 中 | 良 | ⭐⭐⭐⭐⭐ |
| **保持 Wails** | 0 人日 | 100% | 无 | 中 | ⭐⭐⭐ |

### 混合架构优势

✅ **快速迁移**：6-9 周完成
✅ **低风险**：业务逻辑不变
✅ **高复用**：80% 代码保留
✅ **跨平台**：统一构建流程
✅ **体积优化**：比 Wails 小 30-40%
✅ **性能提升**：Rust 系统调用更高效

### 混合架构挑战

⚠️ **双运行时**：内存占用增加（约 +50MB）
⚠️ **进程管理**：需要稳定的进程监控
⚠️ **通信开销**：HTTP 调用比直接调用慢 ~1ms
⚠️ **部署复杂**：需要打包两个可执行文件

---

## 🚀 实施建议

### 优先级排序

1. **高优先级（必须完成）**
   - Tauri 框架搭建
   - 核心 API 迁移（股票、AI、配置）
   - 基础系统功能（窗口、通知）
   - Go 进程管理

2. **中优先级（重要功能）**
   - 事件系统迁移
   - 文件操作
   - 系统托盘
   - 自动更新

3. **低优先级（可延后）**
   - 性能优化
   - 体积优化
   - 高级功能（快捷键、全局快捷键）

### 渐进式迁移策略

**阶段 1（2 周）：MVP**
- 搭建基础架构
- 迁移核心 20 个 API
- 基本功能可用

**阶段 2（2 周）：功能完善**
- 迁移剩余 60 个 API
- 完善事件系统
- 系统功能集成

**阶段 3（2 周）：优化稳定**
- 性能优化
- 打包配置
- 全面测试

### 风险缓解

| 风险 | 缓解措施 |
|------|----------|
| Go 进程崩溃 | 实现 auto-restart 机制 |
| 端口冲突 | 动态端口分配 |
| 内存占用 | 可选：关闭 AI 功能时释放 |
| 通信失败 | 实现离线队列和重试 |
| 更新复杂 | 双进程版本同步检查 |

---

## 📝 技术细节

### Go HTTP 服务设计

**推荐框架：Gin**

```go
import "github.com/gin-gonic/gin"

func NewHTTPServer(app *App) *gin.Engine {
    router := gin.Default()

    // 中间件
    router.Use(cors.Default())
    router.Use(recovery())

    // API 路由
    v1 := router.Group("/api/v1")
    {
        v1.GET("/stocks", getStockList)
        v1.POST("/stocks/follow", followStock)
        // ... 更多路由
    }

    // SSE 事件流
    router.GET("/events", sseEvents)

    return router
}
```

**CORS 配置：**

```go
import "github.com/gin-contrib/cors"

router.Use(cors.New(cors.Config{
    AllowOrigins:     []string{"http://localhost:5173"},
    AllowMethods:     []string{"GET", "POST", "PUT", "DELETE"},
    AllowHeaders:     []string{"Origin", "Content-Type"},
    ExposeHeaders:    []string{"Content-Length"},
    AllowCredentials: true,
}))
```

### SSE 事件推送

**Go 服务端：**

```go
func sseEvents(c *gin.Context) {
    c.Header("Content-Type", "text/event-stream")
    c.Header("Cache-Control", "no-cache")
    c.Header("Connection", "keep-alive")

    // 发送事件
    for {
        select {
        case event := <-eventChannel:
            fmt.Fprintf(c.Writer, "event: %s\n", event.Type)
            fmt.Fprintf(c.Writer, "data: %s\n\n", event.Data)
            c.Writer.Flush()
        case <-c.Request.Context().Done():
            return
        }
    }
}
```

**Rust 事件转发：**

```rust
use reqwest::Client;
use tokio_stream::StreamExt;

async fn forward_events(port: u16) -> Result<(), Box<dyn std::error::Error>> {
    let client = Client::new();
    let mut stream = client
        .get(format!("http://localhost:{}/events", port))
        .send()
        .await?
        .bytes_stream();

    while let Some(item) = stream.next().await {
        let data = item?;
        // 解析 SSE 格式
        // 转发到 Tauri 事件
        tauri::Event::emit("go-event", Some(data))?;
    }

    Ok(())
}
```

### 错误处理

**统一错误格式：**

```json
{
  "success": false,
  "error": {
    "code": "STOCK_NOT_FOUND",
    "message": "股票代码不存在",
    "details": {}
  }
}
```

**前端错误处理：**

```javascript
async function safeAPICall(apiMethod, ...args) {
  try {
    return await apiMethod(...args);
  } catch (error) {
    console.error('API Error:', error);

    // 显示用户友好的错误提示
    window.$message.error(error.message || '操作失败');

    // 上报错误（可选）
    reportError(error);

    return null;
  }
}
```

---

## 🎯 成功标准

### 功能完整性

- ✅ 所有 80+ API 正常工作
- ✅ 20+ 事件实时推送正常
- ✅ AI Agent 功能完整
- ✅ 数据库操作稳定
- ✅ 系统功能（通知、托盘等）正常

### 性能指标

- ✅ API 响应时间 < 100ms（P95）
- ✅ 事件延迟 < 50ms（P95）
- ✅ 内存占用 < 300MB
- ✅ 启动时间 < 3 秒

### 兼容性

- ✅ Windows 10/11
- ✅ macOS 10.13+
- ✅ Ubuntu 20.04+

### 稳定性

- ✅ 连续运行 24 小时无崩溃
- ✅ Go 进程崩溃自动恢复
- ✅ 内存无泄漏
- ✅ 文件操作安全

---

## 📚 参考资料

### Tauri 官方文档

- [Tauri 官网](https://tauri.app/)
- [Tauri v2 指南](https://v2.tauri.app/start/)
- [Tauri API 文档](https://v2.tauri.app/reference/)

### 相关项目

- [Wails → Tauri 迁移案例](https://github.com/tauri-apps/tauri/discussions/)
- [Tauri 多进程架构](https://tauri.app/v1/guides/architecture/)
- [SSE 最佳实践](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events)

### 工具和库

- [Gin Web Framework](https://gin-gonic.com/)
- [reqwest (Rust HTTP Client)](https://docs.rs/reqwest/)
- [tokio (Rust 异步运行时)](https://tokio.rs/)

---

## 📞 支持和反馈

### 获取帮助

- Tauri Discord: https://discord.gg/tauri
- Tauri GitHub Discussions: https://github.com/tauri-apps/tauri/discussions
- 中文社区: https://tauri.app/zh-CN/

### 问题反馈

如遇到迁移问题，请提供：
1. 错误信息和堆栈跟踪
2. 最小可复现代码
3. 系统环境信息（OS、版本）

---

**文档版本:** v1.0
**最后更新:** 2025-01-19
**维护者:** lumos-stock 团队

---

## 附录：API 迁移清单

### 需要迁移的 API（80+）

#### 股票管理（15 个）
- [x] GetStockList
- [x] Follow
- [x] UnFollow
- [x] GetFollowList
- [x] SetCostPriceAndVolume
- [x] SetAlarmChangePercent
- [x] Greet
- [x] GetStockKLine
- [x] GetStockMinutePriceLineData
- [x] GetStockCommonKLine
- [x] MonitorStockPrices
- [x] GetMoneyFlow
- [x] GetLongTigerRank
- [x] GetIndustryRank
- [x] GetStockCompanyInfo

#### AI 相关（10 个）
- [x] NewChatStream
- [x] ChatWithAgent
- [x] SaveAIResponseResult
- [x] GetAIResponseResult
- [x] SummaryStockNews
- [x] GetAiConfigs
- [x] UpdateAiConfig
- [x] TestAiConnection
- [x] GetPromptTemplates
- [x] SavePromptTemplate

#### 新闻和市场（12 个）
- [x] GetTelegraphList
- [x] ReFleshTelegraphList
- [x] GlobalStockIndexes
- [x] GetNewsList
- [x] GetHotTopics
- [x] GetInvestCalendar
- [x] GetStockResearchReport
- [x] GetIndustryResearch
- [x] GetCompanyAnnouncement
- [x] GetSentimentAnalyze
- [x] GetMarketOverview
- [x] GetSectorRotation

#### 基金管理（8 个）
- [x] GetfundList
- [x] FollowFund
- [x] UnFollowFund
- [x] GetFollowedFund
- [x] GetFundNetValue
- [x] GetFundPosition
- [x] GetFundHistory
- [x] SearchFund

#### 配置和设置（15 个）
- [x] GetConfig
- [x] UpdateConfig
- [x] ExportConfig
- [x] ImportConfig
- [x] ResetConfig
- [x] GetAppVersion
- [x] CheckUpdate
- [x] DownloadUpdate
- [x] InstallUpdate
- [x] GetGroupList
- [x] AddGroup
- [x] DeleteGroup
- [x] AddStockGroup
- [x] RemoveStockGroup
- [x] UpdateGroup

#### 系统功能（10 个）
- [x] ShowMessage
- [x] ShowNotification
- [x] OpenBrowser
- [x] SaveFile
- [x] OpenFile
- [x] GetClipboard
- [x] SetClipboard
- [x] MinimizeWindow
- [x] MaximizeWindow
- [x] CloseWindow

### 需要迁移的事件（20+）

#### 实时数据（8 个）
- [x] realtime_profit
- [x] stock_price_update
- [x] market_index_update
- [x] fund_value_update
- [x] money_flow_update
- [x] industry_rank_update
- [x] hot_stock_update
- [x] sector_rotation_update

#### 新闻和资讯（5 个）
- [x] telegraph
- [x] newsPush
- [x] hot_topic_update
- [x] research_report
- [x] company_announcement

#### 系统事件（7 个）
- [x] loadingMsg
- [x] changeTab
- [x] changeMarketTab
- [x] ai_response_stream
- [x] notification
- [x] alarm_trigger
- [x] version_update

---

**迁移状态：**
- 📋 待开始: 80+ API, 20+ 事件
- 🔄 进行中: 0%
- ✅ 已完成: 0%

**目标完成时间:** 6-9 周

---

*此文档将随着迁移进展持续更新*

# Lumos-Stock 项目重命名改造计划

## 📋 项目概述

**当前项目名称**: go-stock
**目标项目名称**: lumos-stock
**改造范围**: 全面重命名项目品牌、模块引用、配置文件和文档
**改造类型**: 品牌重塑与代码重构
**预估影响文件**: 100+ 文件

---

## 🎯 改造目标

1. ✅ **模块名重命名**: `go-stock` → `lumos-stock`
2. ✅ **包路径重命名**: 所有 import 路径更新
3. ✅ **配置文件更新**: wails.json, package.json, go.mod 等
4. ✅ **品牌标识更新**: README, 文档, 用户界面
5. ✅ **URL 和链接更新**: GitHub 仓库, CDN 链接
6. ✅ **二进制文件名**: 输出可执行文件名更新

---

## 📊 影响范围分析

### 代码文件统计
- **Go 源文件**: 63 个
- **Vue 组件**: 27 个
- **配置/文档文件**: 24 个
- **总计**: 114+ 文件需要修改

### 关键影响区域

#### 1. Go 模块系统 (63 个 .go 文件)
```
所有文件中的 import 路径需要更新:
- "go-stock/backend/*" → "lumos-stock/backend/*"
影响文件: app.go, app_*.go, backend/**/*.go
```

#### 2. 前端配置 (27 个 .vue 文件)
```
需要更新的内容:
- 组件中的硬编码 URL (GitHub 图片链接)
- 显示文本 "go-stock" → "lumos-stock"
- 窗口标题
影响文件: frontend/src/components/*.vue
```

#### 3. 构建配置
```
关键配置文件:
- go.mod: module 定义
- wails.json: name, outputfilename, productName
- frontend/package.json: name, keywords
- build/windows/installer/*.nsh: 项目信息
```

#### 4. 文档和元数据
```
需要更新的文件:
- README.md: 项目介绍、链接、徽章
- CONTRIBUTING.md: 贡献指南
- SECURITY.md: 安全策略
- CODE_OF_CONDUCT.md: 行为准则
- .github/workflows/main.yml: CI/CD 配置
- plan1.md: 项目文档
```

---

## 🔍 详细改造清单

### 阶段 1: 核心模块重命名 (高优先级)

#### 1.1 Go 模块配置
**文件**: `go.mod`
```go
# 修改前
module go-stock

# 修改后
module lumos-stock
```

#### 1.2 Wails 配置
**文件**: `wails.json`
```json
{
  "name": "lumos-stock",
  "outputfilename": "lumos-stock",
  "info": {
    "productName": "lumos-stock",
    "comments": "股票行情实时获取,AI赋能分析股票,支持DeepSeek..."
  }
}
```

#### 1.3 前端包配置
**文件**: `frontend/package.json`
```json
{
  "name": "lumos-stock",
  "keywords": ["AI赋能股票分析", "lumos-stock"]
}
```

### 阶段 2: 包路径更新 (63 个 Go 文件)

#### 2.1 主要应用文件
- ✅ `app.go` - import 路径 + API URL + 下载链接
- ✅ `app_darwin.go` - import 路径 + 通知标题
- ✅ `app_windows.go` - import 路径 + 系统托盘标题
- ✅ `app_linux.go` - import 路径
- ✅ `app_common.go` - import 路径
- ✅ `main.go` - import 路径 + 窗口标题

#### 2.2 后端模块 (backend/)
**所有 backend/**/*.go 文件的 import 语句:**
```go
// 批量替换模式
"go-stock/backend/agent" → "lumos-stock/backend/agent"
"go-stock/backend/data" → "lumos-stock/backend/data"
"go-stock/backend/db" → "lumos-stock/backend/db"
"go-stock/backend/logger" → "lumos-stock/backend/logger"
"go-stock/backend/models" → "lumos-stock/backend/models"
"go-stock/backend/util" → "lumos-stock/backend/util"
```

**影响的子目录**:
- `backend/agent/` - agent.go, agent_api.go, agent_test.go
- `backend/agent/tools/` - 12+ 工具文件
- `backend/data/` - 20+ API 文件
- `backend/db/` - db.go
- `backend/logger/` - lgo.go
- `backend/models/` - models.go
- `backend/util/` - 工具函数

### 阶段 3: 前端组件更新 (27 个 Vue 文件)

#### 3.1 静态资源 URL 更新
**当前硬编码的 GitHub 链接** (需要决定新路径):
```javascript
// 所有组件中的图标 URL
https://raw.githubusercontent.com/ArvinLovegood/go-stock/master/build/appicon.png
// 需要更新为新的 GitHub 组织/仓库路径
```

**影响的组件**:
- `stock.vue` - 行 162
- `agent-chat.vue` - 行 81
- `agent-chat_bk.vue` - 行 57
- `market.vue` - 行 40
- `about.vue` - 行 13-16

#### 3.2 用户界面文本
**文件**: `frontend/src/App.vue`
```javascript
// 行 674: 窗口标题
WindowSetTitle("lumos-stock：AI赋能股票分析✨ ...")

// 行 711: 来源标识
data.source === "lumos-stock"
```

**文件**: `frontend/src/components/about.vue`
```html
<!-- 所有显示的 "go-stock" 文本 -->
<n-gradient-text>lumos-stock</n-gradient-text>
```

**文件**: `frontend/src/components/stockhotmap.vue`
```html
<!-- 嵌入式 URL (需要确认新域名) -->
<embedded-url url="https://lumos-stock.sparkmemory.top:16667/lumos-stock" />
```

#### 3.3 HTML 标题
**文件**: `frontend/index.html`
```html
<title>lumos-stock:AI赋能股票分析</title>
```

### 阶段 4: 构建和部署配置

#### 4.1 Windows 安装程序
**文件**: `build/windows/installer/wails_tools.nsh`
```nsis
!define INFO_PROJECTNAME "lumos-stock"
!define INFO_PRODUCTNAME "lumos-stock"
!define INFO_COMPANYNAME "sparkmemory"
!define INFO_COPYRIGHT "Copyright#sparkmemory@163.com"
```

#### 4.2 GitHub Actions
**文件**: `.github/workflows/main.yml`
```yaml
# 构建输出文件名
- name: 'lumos-stock-windows-amd64.exe'
- name: 'lumos-stock-darwin-universal'
- name: 'lumos-stock-darwin-intel'
- name: 'lumos-stock-darwin-arm64'

# Action 引用
uses: [新GitHub组织]/wails-build-action@v3.6
```

#### 4.3 macOS 配置
**文件**: `build/darwin/Info.plist` 和 `Info.dev.plist`
```xml
<key>CFBundleName</key>
<string>lumos-stock</string>
```

### 阶段 5: 文档和品牌更新

#### 5.1 README.md 全面重写
```markdown
# lumos-stock : 基于大语言模型的AI赋能股票分析工具
## ![lumos-stock](./build/appicon.png)

# 更新所有徽章链接
# 更新仓库引用 ArvinLovegood/go-stock → [新组织]/lumos-stock
# 更新所有 GitHub 链接
# 更新下载链接文件名
# 更新 Star History 图表
```

#### 5.2 贡献指南
**文件**: `CONTRIBUTING.md`
```markdown
# Contributing to lumos-stock

# 更新 clone 命令
git clone https://github.com/[新组织]/lumos-stock.git

# 更新 issue 链接
# 更新 upstream 链接
```

#### 5.3 安全策略
**文件**: `SECURITY.md`
```markdown
# lumos-stock 项目安全策略
# 更新项目名称引用
```

#### 5.4 其他文档
- ✅ `CODE_OF_CONDUCT.md` - 更新项目引用
- ✅ `plan1.md` - 更新项目分析文档
- ✅ `LICENSE` - 更新版权年份和所有者

### 阶段 6: API 和服务端点

#### 6.1 内部 API 调用
**文件**: `app.go`, `backend/data/market_news_api_test.go`

需要确认的服务 URL:
```go
// 这些是自托管服务器，需要决定是否更新域名
"http://go-stock.sparkmemory.top:16666/FinancialNews/json"
"http://go-stock.sparkmemory.top:16688/upload"
"https://go-stock.sparkmemory.top:16667"

// 选项 1: 保持域名不变 (向后兼容)
// 选项 2: 更新为 lumos-stock.sparkmemory.top
```

#### 6.2 GitHub API 调用
**文件**: `app.go`, `app_test.go`
```go
// 更新仓库引用
https://api.github.com/repos/ArvinLovegood/go-stock/releases/latest
→ https://api.github.com/repos/[新组织]/lumos-stock/releases/latest

// 更新下载文件名
go-stock-windows-amd64.exe → lumos-stock-windows-amd64.exe
go-stock-darwin-universal → lumos-stock-darwin-universal
```

#### 6.3 代理配置
**文件**: `backend/data/market_news_api_test.go`
```go
// 测试用的代理用户名
SetProxy("http://lumos-stock:778d4ff2-73f3-4d56-b3c3-d9a730a06ae3@...")
```

---

## 🛠️ 实施方案

### 方案 A: 批量替换 (推荐用于简单替换)
**工具**: `sed`, `find`, `VS Code 全局替换`

**步骤**:
1. **Go 模块路径替换**
   ```bash
   find . -name "*.go" -type f -exec sed -i '' 's|go-stock/backend|lumos-stock/backend|g' {} +
   ```

2. **显示文本替换**
   ```bash
   # 保留源码注释，只替换用户可见文本
   find . -name "*.vue" -o -name "*.html" -o -name "*.md" | \
     xargs sed -i '' 's/go-stock/lumos-stock/g'
   ```

3. **配置文件替换**
   ```bash
   sed -i '' 's/"go-stock"/"lumos-stock"/g' go.mod wails.json frontend/package.json
   ```

### 方案 B: 符号级重构 (推荐用于精准控制)
**工具**: Serena MCP (rename_symbol), Go refactor 工具

**优势**:
- ✅ 保证代码完整性
- ✅ 自动更新引用
- ✅ 支持跨文件重命名

**步骤**:
1. 使用 Serena 的 `rename_symbol` 工具
2. 逐个重命名包和符号
3. 验证编译通过

### 方案 C: 混合方案 (最优)
**阶段 1: 自动化批量替换** (90% 的工作)
- 使用正则表达式批量替换
- 处理明确的字符串和路径

**阶段 2: 手动审查** (10% 的工作)
- GitHub URL (需要确认新仓库)
- 用户界面文本 (保持友好度)
- 配置文件 (验证格式)

**阶段 3: 编译测试**
```bash
# 清理依赖
go mod tidy

# 重新下载依赖
go mod download

# 构建测试
wails build

# 运行测试
go test ./...
```

---

## 📝 改造检查清单

### Phase 1: 核心配置 ( MUST DO )
- [ ] `go.mod` - module 名称
- [ ] `go.sum` - 清理并重新生成
- [ ] `wails.json` - name, outputfilename, productName
- [ ] `frontend/package.json` - name, keywords
- [ ] `frontend/package-lock.json` - 自动更新

### Phase 2: 代码引用 ( MUST DO )
- [ ] 所有 `.go` 文件的 import 语句 (63 个文件)
- [ ] `main.go` - 窗口标题
- [ ] `app_*.go` - 平台特定配置
- [ ] `backend/` 所有子目录的 import

### Phase 3: 前端界面 ( SHOULD DO )
- [ ] `frontend/index.html` - title 标签
- [ ] `frontend/src/App.vue` - 窗口标题
- [ ] 所有 `.vue` 组件的硬编码文本
- [ ] GitHub 资源 URL (图片链接)

### Phase 4: 构建配置 ( SHOULD DO )
- [ ] `build/windows/installer/wails_tools.nsh`
- [ ] `build/darwin/Info.plist`
- [ ] `build/darwin/Info.dev.plist`
- [ ] `.github/workflows/main.yml`

### Phase 5: 文档更新 ( SHOULD DO )
- [ ] `README.md` - 全面重写
- [ ] `CONTRIBUTING.md` - 链接更新
- [ ] `SECURITY.md` - 项目名称
- [ ] `CODE_OF_CONDUCT.md` - 项目引用
- [ ] `plan1.md` - 文档更新

### Phase 6: API 和服务 ( MUST DO - 决策点)
- [ ] `app.go` - GitHub API 链接 (需要新仓库)
- [ ] `app.go` - 下载 URL (需要新仓库)
- [ ] `app.go` - 自托管服务 URL (决策: 保持/更新)
- [ ] `backend/data/market_news_api_test.go` - 测试 URL

### Phase 7: 验证测试 ( MUST DO )
- [ ] `wails dev` - 开发模式测试
- [ ] `wails build` - 生产构建测试
- [ ] `go test ./...` - 单元测试
- [ ] 手动功能测试 - 核心功能验证

---

## ⚠️ 风险和注意事项

### 高风险区域

#### 1. GitHub 仓库迁移
**风险**: 破坏现有用户自动更新
**影响**: 生产环境
**建议**:
- 保留旧仓库重定向
- 或在旧仓库发布迁移说明版本
- 渐进式迁移用户

#### 2. 自托管服务 URL
**风险**: 服务中断
**影响**: 用户功能
**建议**:
- 保留旧域名兼容性
- 或使用 DNS CNAME 重定向
- 或同时支持两个域名

#### 3. 第三方集成
**风险**: API 密钥和配置失效
**影响**: 外部服务
**检查清单**:
- [ ] Tushare token
- [ ] 硅基流动 API
- [ ] 火山方舟配置
- [ ] OpenAI 配置

#### 4. 证书和签名
**风险**: 代码签名失效
**影响**: Windows/macOS 安装
**建议**:
- 更新代码签名证书
- 重新生成 macOS .pkg
- 重新签名 Windows .exe

### 中风险区域

#### 1. Go 模块缓存
**风险**: 依赖缓存失效
**缓解**: `go clean -modcache && go mod download`

#### 2. 前端构建缓存
**风险**: Vite 缓存问题
**缓解**: `rm -rf frontend/node_modules frontend/.vite`

#### 3. 用户数据迁移
**风险**: 用户配置文件路径变更
**缓解**: 保持数据目录结构不变

### 低风险区域

#### 1. 文档链接
**风险**: 外部文档链接失效
**缓解**: GitHub 自动重定向

#### 2. 社区链接
**风险**: QQ 群、公众号链接
**缓解**: 这些通常不受影响

---

## 🔧 实施步骤

### Step 1: 准备阶段 (1-2 小时)
1. ✅ 创建新 GitHub 仓库 `lumos-stock`
2. ✅ 备份当前代码分支
3. ✅ 通知用户即将进行的品牌变更
4. ✅ 准备迁移文档

### Step 2: 批量替换 (2-4 小时)
1. ✅ 运行自动化替换脚本
2. ✅ 更新核心配置文件
3. ✅ 批量更新 import 路径
4. ✅ 更新文档和 README

### Step 3: 手动审查 (1-2 小时)
1. ✅ 审查所有 GitHub URL
2. ✅ 验证配置文件格式
3. ✅ 检查用户界面文本
4. ✅ 确认二进制文件名

### Step 4: 编译测试 (1-2 小时)
1. ✅ 清理构建缓存
2. ✅ 运行 `wails dev` 测试
3. ✅ 执行 `wails build` 构建
4. ✅ 运行单元测试

### Step 5: 功能验证 (2-3 小时)
1. ✅ 测试股票查询功能
2. ✅ 测试 AI 分析功能
3. ✅ 测试自动更新功能
4. ✅ 测试平台特定功能 (通知/托盘)

### Step 6: 部署上线 (1-2 小时)
1. ✅ 推送到新仓库
2. ✅ 发布新版本
3. ✅ 更新网站和 CDN
4. ✅ 通知社区迁移完成

**总预估时间**: 8-15 小时

---

## 📦 自动化脚本

### 完整替换脚本
```bash
#!/bin/bash
# lumos-stock-refactor.sh

set -e

echo "🚀 开始 lumos-stock 重命名改造..."

# Phase 1: Go 模块
echo "📦 更新 Go 模块..."
sed -i '' 's/module go-stock/module lumos-stock/g' go.mod
find . -name "*.go" -type f -exec sed -i '' 's|"go-stock/backend|"lumos-stock/backend|g' {} +

# Phase 2: 配置文件
echo "⚙️  更新配置文件..."
sed -i '' 's/"go-stock"/"lumos-stock"/g' wails.json
sed -i '' 's/"name": "go-stock"/"name": "lumos-stock"/g' frontend/package.json
sed -i '' 's/go-stock/lumos-stock/g' frontend/package-lock.json

# Phase 3: 前端文件
echo "🎨 更新前端文件..."
sed -i '' 's/go-stock/lumos-stock/g' frontend/index.html
find frontend/src -name "*.vue" -type f -exec sed -i '' 's/go-stock/lumos-stock/g' {} +

# Phase 4: 文档
echo "📚 更新文档..."
find . -name "*.md" -type f -exec sed -i '' 's/go-stock/lumos-stock/g' {} +
sed -i '' 's/go-stock/lumos-stock/g' .github/workflows/main.yml

# Phase 5: 构建配置
echo "🔧 更新构建配置..."
sed -i '' 's/go-stock/lumos-stock/g' build/windows/installer/wails_tools.nsh
sed -i '' 's/go-stock/lumos-stock/g' build/darwin/Info.plist
sed -i '' 's/go-stock/lumos-stock/g' build/darwin/Info.dev.plist

# Phase 6: 清理和重建
echo "🧹 清理依赖..."
go mod tidy
rm -rf frontend/node_modules
cd frontend && npm install && cd ..

echo "✅ 重命名完成! 请手动检查以下内容:"
echo "   - GitHub URL (需要新仓库地址)"
echo "   - 自托管服务 URL (需要确认)"
echo "   - 用户界面文本 (保持友好度)"
echo ""
echo "🧪 测试构建:"
echo "   wails build"
```

### 验证脚本
```bash
#!/bin/bash
# verify-refactor.sh

echo "🔍 验证重命名结果..."

# 检查残留
echo "📊 检查残留的 go-stock 引用:"
echo "Go 文件:"
grep -r "go-stock/backend" --include="*.go" . || echo "✅ 无残留"
echo ""
echo "配置文件:"
grep -r '"go-stock"' --include="*.json" --include="*.yaml" . || echo "✅ 无残留"
echo ""
echo "前端文件:"
grep -r "go-stock" --include="*.vue" --include="*.html" frontend/src || echo "✅ 无残留"
echo ""
echo "文档:"
grep -r "go-stock" --include="*.md" . | grep -v "lumos-stock" || echo "✅ 无残留"

echo ""
echo "✅ 验证完成!"
```

---

## 🎯 成功标准

### 技术指标
- ✅ 所有文件编译无错误
- ✅ 所有单元测试通过
- ✅ 应用成功打包为 `lumos-stock`
- ✅ 自动更新功能正常工作

### 品牌指标
- ✅ 所有用户可见文本更新
- ✅ 所有文档引用更新
- ✅ 所有 GitHub 链接更新
- ✅ 窗口标题和进程名更新

### 用户体验
- ✅ 现有功能无破坏
- ✅ 配置文件向后兼容
- ✅ 数据无丢失
- ✅ 性能无退化

---

## 📞 后续支持

### 迁移期支持 (建议 2-4 周)
1. 保留旧仓库 README 重定向
2. 发布迁移公告版本
3. 提供 FAQ 文档
4. 监控 GitHub Issues

### 渐进式迁移策略
1. **Week 1-2**: 在旧版本发布迁移通知
2. **Week 3-4**: 同时支持两个版本更新
3. **Week 5+**: 停止旧版本支持

### 回滚计划
如果出现重大问题:
1. 立即恢复旧仓库
2. 发布回滚说明
3. 提供技术支持
4. 分析失败原因

---

## 📚 附录

### A. 文件清单 (完整)

#### Go 源文件 (63)
```
app.go
app_darwin.go
app_windows.go
app_linux.go
app_common.go
app_test.go
main.go
utils.go
backend/agent/*.go
backend/agent/tools/*.go (12 files)
backend/agent/tool_logger/*.go
backend/data/*.go (20+ files)
backend/db/*.go
backend/logger/*.go
backend/models/*.go
backend/util/*.go
```

#### Vue 组件 (27)
```
frontend/src/App.vue
frontend/src/main.js
frontend/src/components/stock.vue
frontend/src/components/agent-chat.vue
frontend/src/components/agent-chat_bk.vue
frontend/src/components/about.vue
frontend/src/components/market.vue
frontend/src/components/settings.vue
frontend/src/components/stockhotmap.vue
... (17 more components)
```

#### 配置文件
```
go.mod, go.sum
wails.json
frontend/package.json
frontend/package-lock.json
frontend/vite.config.js
.github/workflows/main.yml
build/windows/installer/*.nsh
build/darwin/*.plist
```

### B. 替换模式速查表

| 模式 | 替换为 | 文件类型 |
|------|--------|----------|
| `go-stock/backend` | `lumos-stock/backend` | Go import |
| `"go-stock"` | `"lumos-stock"` | JSON config |
| `go-stock` | `lumos-stock` | Vue/HTML/MD |
| `go-stock-windows` | `lumos-stock-windows` | GitHub URL |
| `go-stock-darwin` | `lumos-stock-darwin` | GitHub URL |

### C. 相关资源

#### Wails 重命名文档
https://wails.io/docs/guides/packaging

#### Go 模块重命名最佳实践
https://go.dev/doc/modules/pruning

#### Vue 项目重命名
https://vuejs.org/guide/reusability/composables.html

---

## ✨ 总结

本改造计划提供了从 **go-stock** 到 **lumos-stock** 的完整重命名方案，涵盖:

✅ **114+ 文件**的系统性改造
✅ **7 个阶段**的渐进式实施
✅ **3 种方案**的技术实现路径
✅ **风险控制**和**回滚计划**
✅ **自动化脚本**和**验证工具**

**预计工作量**: 8-15 小时
**建议实施周期**: 2-3 个工作日
**迁移支持期**: 2-4 周

---

**创建日期**: 2025-01-16
**最后更新**: 2025-01-16
**状态**: 待实施
**负责人**: [待指定]

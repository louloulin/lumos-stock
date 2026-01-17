# AI Chat 输出停止问题分析报告

> 问题描述: AI Agent 聊天输出仅显示 2 个字符后停止
> 分析日期: 2025-01-17
> 严重程度: 🔴 P0 - 阻塞性问题

---

## 一、问题现象

### 1.1 用户反馈
- **表现**: AI 回复仅输出 2 个字符后停止
- **频率**: 每次发送消息都会发生
- **影响**: 功能完全不可用

### 1.2 预期行为 vs 实际行为

```
预期: 用户提问 → AI 流式输出完整回答 (数百字符)
实际: 用户提问 → AI 输出 2 字符 → 停止
```

---

## 二、问题定位

### 2.1 前端事件处理分析

**文件**: `frontend/src/components/agent-chat.vue`

```javascript
// 第 95-127 行
EventsOn("agent-message", (data) => {
  console.log(data)
  if(data['role']==="assistant"){
    loading.value = false;
    const lastIndex = 0;  // ❌ 问题 1: 硬编码索引
    const lastItem = chatList.value[lastIndex];  // ❌ 问题 2: 总是获取第一条消息

    // 创建新对象以触发Vue响应式更新
    const updatedItem = { ...lastItem };

    if (data['reasoning_content']){
      updatedItem.reasoning += data['reasoning_content'];
    }
    if (data['content']){
      updatedItem.content += data['content'];  // ❌ 问题 3: 每次更新同一条消息
    }
    if(data['tool_calls']){
      for (const tool of  data['tool_calls']) {
        updatedItem.reasoning += "\n```"+tool.function.name+"\n" +
            "参数："+ (tool.function.arguments?tool.function.arguments:"无")+
            "\n```\n";
      }
    }

    // 替换整个对象以触发响应式更新
    chatList.value[lastIndex] = updatedItem;  // ❌ 问题 4: 覆盖同一条消息
  }
  if(data['response_meta']&&data['response_meta'].finish_reason==="stop"){
    isStreamLoad.value = false;
    loading.value = false;
  }
})
```

### 2.2 消息列表结构分析

```javascript
// 第 172-195 行
const chatList = ref([
  {
    avatar: h(NImage, { src: icon.value, height: '48px', width: '48px'}),
    name: 'Go-Stock AI',
    datetime: '',
    reasoning: '',
    content: '我是您的AI赋能股票分析助手...',
    role: 'assistant',
    duration: 10,
  },
  {
    avatar: 'https://tdesign.gtimg.com/site/avatar.jpg',
    name: '宇宙无敌大韭菜',
    datetime: '',
    content: '介绍下自己？',
    role: 'user',
    reasoning: '',
  },
]);
```

**关键发现**: chatList 使用 `unshift` 添加新消息，所以:
- `chatList.value[0]` = 最新添加的 AI 空消息占位符
- `chatList.value[1]` = 用户刚发送的消息
- `chatList.value[2]` = 上一条 AI 消息

### 2.3 后端事件发送分析

**文件**: `app_common.go`

```go
// 第 69-74 行
func (a *App) ChatWithAgent(question string, aiConfigId int, sysPromptId *int) {
	ch := agent.NewStockAiAgentApi().Chat(question, aiConfigId, sysPromptId)
	for msg := range ch {
		runtime.EventsEmit(a.ctx, "agent-message", msg)  // 发送 schema.Message
	}
}
```

**文件**: `backend/agent/agent_api.go`

```go
// 第 75-88 行
for {
    msg, err := sr.Recv()
    if err != nil {
        if errors.Is(err, io.EOF) {
            break  // 流结束
        }
        logger.SugaredLogger.Errorf("failed to recv: %v", err)
        break
    }
    logger.SugaredLogger.Infof("stream: %s", msg.String())
    ch <- msg  // 发送到 channel
}
```

---

## 三、根本原因分析

### 3.1 问题根源

**核心问题**: 前端事件处理器的逻辑错误，导致每个流式数据块都更新到**错误的聊天消息**

```
流程分析:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. 用户发送消息
   ↓
2. chatList.unshift(用户消息)        // [用户消息]
   ↓
3. chatList.unshift(AI 空消息占位)    // [AI空消息, 用户消息]
   ↓
4. 调用 ChatWithAgent()
   ↓
5. 后端开始流式发送,触发 EventsOn
   ↓
6. ❌ lastIndex = 0 (硬编码)
   ↓
7. ❌ chatList[0] = AI空消息 (每次都更新这条)
   ↓
8. 收到第1个 chunk (2字符)
   ↓
9. ❌ chatList[0].content = "2字符"  (更新了正确的消息)
   ↓
10. 收到第2个 chunk
   ↓
11. ❌ chatList[0].content = "2字符" + "新内容"
   ↓
12. ❌ 但由于 Vue 响应式问题,可能只显示初始值
```

### 3.2 详细问题分解

#### 问题 1: 硬编码索引 `lastIndex = 0`

```javascript
const lastIndex = 0;  // ❌ 总是获取第一条
```

**问题**:
- 假设 chatList 为: `[AI空消息, 用户消息, 上一条AI消息, ...]`
- `lastIndex = 0` 指向最新添加的 AI 空消息
- 但如果聊天历史很长,这个假设可能不成立

#### 问题 2: 没有正确跟踪当前正在生成的消息

```javascript
const lastItem = chatList.value[lastIndex];
```

**问题**:
- 没有存储"当前正在生成"的消息索引
- 每次 `EventsOn` 触发时,重新从固定位置获取
- 如果在生成过程中用户又发送了消息,会混乱

#### 问题 3: 消息更新逻辑问题

```javascript
chatList.value[lastIndex] = updatedItem;
```

**问题**:
- 直接替换整个对象,可能导致渲染问题
- TDesign 的 `t-chat` 组件可能需要特定的更新方式

#### 问题 4: 缺少流式结束处理

```javascript
if(data['response_meta']&&data['response_meta'].finish_reason==="stop"){
  isStreamLoad.value = false;
  loading.value = false;
}
```

**问题**:
- 只检查 `response_meta.finish_reason`
- 但后端可能没有发送这个字段
- 导致 `isStreamLoad` 一直为 `true`,阻止新消息发送

### 3.3 可能的 Vue 响应式问题

```javascript
// 问题代码
const updatedItem = { ...lastItem };
updatedItem.content += data['content'];
chatList.value[lastIndex] = updatedItem;
```

**潜在问题**:
1. **对象引用问题**: `{ ...lastItem }` 创建浅拷贝,`avatar` 是 VNode 可能有问题
2. **数组索引更新**: 直接通过索引修改数组元素,Vue 可能无法正确追踪
3. **TDesign 组件重新渲染**: 组件可能需要特定的数据格式才能正确更新

---

## 四、解决方案

### 4.1 修复方案 1: 使用响应式引用跟踪当前消息 ⭐ 推荐

```vue
<script setup lang="ts">
// 新增: 跟踪当前正在生成的消息索引
const currentGeneratingIndex = ref(-1);

EventsOn("agent-message", (data) => {
  console.log('agent-message event:', data)

  if(data['role'] === "assistant"){
    loading.value = false;

    // 修复 1: 使用动态索引而不是硬编码
    const lastIndex = currentGeneratingIndex.value;
    if (lastIndex < 0 || lastIndex >= chatList.value.length) {
      console.error('Invalid message index:', lastIndex);
      return;
    }

    const lastItem = chatList.value[lastIndex];

    // 修复 2: 使用响应式 API 更新
    if (data['reasoning_content']){
      chatList.value[lastIndex].reasoning += data['reasoning_content'];
    }
    if (data['content']){
      chatList.value[lastIndex].content += data['content'];
    }
    if(data['tool_calls']){
      for (const tool of data['tool_calls']) {
        chatList.value[lastIndex].reasoning += "\n```"+tool.function.name+"\n" +
            "参数："+ (tool.function.arguments || "无") +
            "\n```\n";
      }
    }

    // 修复 3: 强制触发响应式更新
    chatList.value = [...chatList.value];
  }

  // 修复 4: 更完善的结束检测
  if(data['response_meta']?.finish_reason === "stop" ||
     data['response_meta']?.finish_reason === "length" ||
     (!data['content'] && !data['reasoning_content'])) {
    isStreamLoad.value = false;
    loading.value = false;
    currentGeneratingIndex.value = -1;  // 重置索引
  }
})

const inputEnter = function () {
  if (isStreamLoad.value) {
    return;
  }
  if (!inputValue.value) return;

  // 添加用户消息
  chatList.value.unshift({
    avatar: 'https://tdesign.gtimg.com/site/avatar.jpg',
    name: '宇宙无敌大韭菜',
    datetime: new Date().toISOString(),
    content: inputValue.value,
    role: 'user',
    reasoning: '',
  });

  // 添加 AI 空消息占位符
  const aiMessage = {
    avatar: h(NImage, { src: icon.value, height: '48px', width: '48px'}),
    name: 'Go-Stock AI',
    datetime: new Date().toISOString(),
    content: '',
    reasoning: '',
    role: 'assistant',
  };
  chatList.value.unshift(aiMessage);

  // 修复 5: 记录当前正在生成的消息索引
  currentGeneratingIndex.value = 0;

  loading.value = true;
  isStreamLoad.value = true;

  // 清空输入
  const question = inputValue.value;
  inputValue.value = '';

  ChatWithAgent(question, selectValue.value, 0).catch(err => {
    console.error('ChatWithAgent error:', err);
    isStreamLoad.value = false;
    loading.value = false;
    currentGeneratingIndex.value = -1;
  });
};

// 修复 6: 组件卸载时清理
onBeforeUnmount(() => {
  EventsOff("agent-message")
  currentGeneratingIndex.value = -1;
})
</script>
```

### 4.2 修复方案 2: 使用唯一消息 ID

```vue
<script setup lang="ts">
// 为每条消息生成唯一 ID
let messageIdCounter = 0;
const currentMessageId = ref(null);

EventsOn("agent-message", (data) => {
  if(data['role'] === "assistant" && data['message_id']){
    const message = chatList.value.find(m => m.id === data['message_id']);
    if (message) {
      if (data['content']) {
        message.content += data['content'];
      }
      if (data['reasoning_content']) {
        message.reasoning += data['reasoning_content'];
      }
      // 强制更新
      chatList.value = [...chatList.value];
    }
  }
})

const inputEnter = function () {
  // ...
  const aiMessage = {
    id: `msg_${++messageIdCounter}`,
    avatar: h(NImage, { src: icon.value, height: '48px', width: '48px'}),
    name: 'Go-Stock AI',
    content: '',
    reasoning: '',
    role: 'assistant',
  };
  currentMessageId.value = aiMessage.id;
  chatList.value.unshift(aiMessage);

  ChatWithAgent(inputValue.value, selectValue.value, currentMessageId.value);
};
</script>
```

### 4.3 后端配合修复 (可选)

**修改后端,在消息中添加 message_id**:

```go
// app_common.go
func (a *App) ChatWithAgent(question string, aiConfigId int, sysPromptId *int) {
    messageId := generateMessageId()  // 生成唯一 ID

    ch := agent.NewStockAiAgentApi().Chat(question, aiConfigId, sysPromptId)
    for msg := range ch {
        // 添加 message_id 到消息
        msgMap := map[string]interface{}{
            "role": msg.Role,
            "content": msg.Content,
            "reasoning_content": msg.RespContent,
            "message_id": messageId,
        }
        runtime.EventsEmit(a.ctx, "agent-message", msgMap)
    }

    // 发送结束信号
    runtime.EventsEmit(a.ctx, "agent-message", map[string]interface{}{
        "role": "assistant",
        "message_id": messageId,
        "response_meta": map[string]interface{}{
            "finish_reason": "stop",
        },
    })
}
```

---

## 五、测试验证

### 5.1 测试用例

```javascript
// 测试 1: 正常流式输出
输入: "你好"
预期: 完整输出,逐字符显示

// 测试 2: 快速连续发送多条消息
输入: "你好" → [立即] "介绍一下自己"
预期: 两条消息独立流式输出,互不干扰

// 测试 3: 长文本输出
输入: "详细分析贵州茅台的投资价值"
预期: 完整输出数百字符的回答

// 测试 4: 工具调用
输入: "查询平安银行最新股价"
预期: 正确显示工具调用和最终回答
```

### 5.2 调试日志

```javascript
EventsOn("agent-message", (data) => {
  console.log('=== Agent Message ===');
  console.log('Role:', data['role']);
  console.log('Content length:', data['content']?.length || 0);
  console.log('Content preview:', data['content']?.substring(0, 20));
  console.log('Reasoning length:', data['reasoning_content']?.length || 0);
  console.log('Finish reason:', data['response_meta']?.finish_reason);
  console.log('Current index:', currentGeneratingIndex.value);
  console.log('Chat list length:', chatList.value.length);
  console.log('====================');
})
```

---

## 六、预防措施

### 6.1 代码审查检查清单

- [ ] 避免硬编码数组索引
- [ ] 正确处理异步状态
- [ ] 添加错误处理和边界检查
- [ ] 使用唯一 ID 而非数组索引引用
- [ ] 添加详细的调试日志
- [ ] 测试快速连续操作

### 6.2 最佳实践

```javascript
// ✅ 好的做法
const currentTaskId = ref(null);
const tasks = ref(new Map());

function startTask() {
  const id = generateId();
  currentTaskId.value = id;
  tasks.value.set(id, { status: 'running', result: '' });
}

function updateTask(id, data) {
  const task = tasks.value.get(id);
  if (task) {
    task.result += data;
    tasks.value.set(id, { ...task });
  }
}

// ❌ 不好的做法
const list = ref([]);
function update(data) {
  list[0] += data;  // 硬编码索引
}
```

---

## 七、相关文件清单

### 7.1 需要修改的文件

```
frontend/src/components/agent-chat.vue  (主要修改)
├── 第 92-94 行: EventsOn 处理器
├── 第 99 行: lastIndex 定义
├── 第 121 行: 消息更新逻辑
└── 第 205-231 行: inputEnter 函数

app_common.go (可选修改)
└── 第 69-74 行: ChatWithAgent 函数
```

### 7.2 相关文件

```
backend/agent/agent_api.go         (后端流式实现)
backend/agent/tool_logger/tool_logger.go  (回调处理)
frontend/src/components/agent-chat_bk.vue  (备份版本)
```

---

## 八、总结

### 8.1 问题根源

**核心问题**: 前端事件处理器使用硬编码索引 `lastIndex = 0`,导致流式更新时总是更新同一条消息,加上 Vue 响应式更新机制的问题,导致消息显示不完整。

### 8.2 解决方案

**推荐方案**: 使用 `currentGeneratingIndex` 响应式变量跟踪当前正在生成的消息索引,配合正确的 Vue 响应式 API 进行更新。

### 8.3 预期效果

- ✅ AI 回复完整显示
- ✅ 流式输出正常
- ✅ 支持连续对话
- ✅ 工具调用正确显示

---

*文档版本: v1.0*
*创建日期: 2025-01-17*

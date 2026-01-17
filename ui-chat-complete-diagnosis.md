# AI Chat 渲染问题 - 完整诊断与最终修复

> 问题: AI 回复仍然只显示 "我是," (2字符)
> 状态: 🔍 深度分析中
> 日期: 2025-01-17

---

## 一、问题现象确认

### 当前行为
```
用户输入: "介绍一下自己"
AI输出: "我是," → 停止
预期: "我是您的AI赋能股票分析助手,您可以问我任何关于股票投资方面的问题。"
```

### 控制台日志分析
根据修改后的代码,应该看到:
```
=== agent-message event ===
Raw data: { role: 'assistant', content: '我是,' }
Processed content: "我是," length: 3
Updated content, new length: 3

=== agent-message event ===
Raw data: { role: 'assistant', content: '您的AI' }
Processed content: "您的AI" length: 3
Updated content, new length: 6

... (继续接收数据)
```

**但界面上仍然只显示 "我是,"**

---

## 二、深度分析

### 分析 1: TDesign Chat 组件的 data 属性

**当前代码**:
```vue
<t-chat
    ref="chatRef"
    :clear-history="chatList.length > 0 && !isStreamLoad"
    :data="chatList"  <!-- ⚠️ 传递整个数组 -->
    :text-loading="loading"
    :is-stream-load="isStreamLoad"
>
```

**问题**:
- `t-chat` 组件的 `:data` 属性接收的是**整个 chatList 数组**
- TDesign 可能**缓存了初始数据**
- 当流式更新时,虽然数组引用变了,但 TDesign 可能没有正确重新渲染

### 分析 2: chatList 初始数据问题

**当前代码** (第 249-272 行):
```javascript
const chatList = ref([
  {
    avatar: h(NImage, { src: icon.value, height: '48px', width: '48px'}),
    name: 'Go-Stock AI',
    content: '我是您的AI赋能股票分析助手...',
    role: 'assistant',
  },
  {
    avatar: 'https://tdesign.gtimg.com/site/avatar.jpg',
    name: '宇宙无敌大韭菜',
    content: '介绍下自己？',
    role: 'user',
  },
]);
```

**问题分析**:
1. 初始化时,索引 0 是 **欢迎消息**,索引 1 是用户消息
2. 当发送新消息时:
   - `unshift(userMessage)` → 索引 0 变成用户消息,欢迎消息移到索引 2
   - `unshift(aiMessage)` → 索引 0 变成 AI 空消息,用户消息移到索引 1
3. **但欢迎消息仍然存在**!

**实际问题**:
- 可能 TDesign 组件在处理数组时,有**缓存或索引混乱**
- 或者欢迎消息的 VNode `avatar` 引用导致渲染问题

### 分析 3: Vue 响应式 + TDesign 组件冲突

**当前更新方式**:
```javascript
const lastItem = chatList.value[lastIndex];
lastItem.content += content;
chatList.value = [...chatList.value];
```

**问题**:
1. 虽然 `chatList.value` 的引用变了
2. 但 `lastItem` 是**同一个对象引用**
3. TDesign 组件可能**深度缓存**了消息对象
4. 直接修改对象属性可能**不触发组件更新**

### 分析 4: 条件渲染的时机问题

**当前模板**:
```vue
<t-chat-content v-if="item.content.length > 0" :content="item.content" />
```

**问题**:
- `v-if="item.content.length > 0"` 条件可能有问题
- 如果初始 content 是空字符串 `""`
- 第一次更新为 `"我是,"` 后,长度变为 3
- **但 TDesign 可能没有检测到变化**

### 分析 5: 初始欢迎消息的干扰

**关键发现**:

当发送第一条新消息时:
```
初始状态 (2条消息):
[0] AI 欢迎消息 (content: "我是您的AI赋能股票分析助手...")
[1] 用户消息 "介绍下自己"

发送后 (4条消息):
[0] AI 空消息 (content: "")
[1] 用户消息 "介绍下自己"
[2] AI 欢迎消息 (content: "我是您的AI赋能股票分析助手...")
[3] 用户消息 "介绍下自己"
```

**等等!这里有重复!**

让我重新检查 `inputEnter` 函数...

实际上看起来是正常的:
- 初始有 2 条消息
- 添加用户消息 → 变成 3 条
- 添加 AI 消息 → 变成 4 条

但问题可能是:**初始的欢迎消息可能干扰了新消息的渲染!**

---

## 三、最终解决方案

### 解决方案: 清空初始消息,修复响应式更新

**修改 `inputEnter` 函数**:

```javascript
const inputEnter = function () {
  if (isStreamLoad.value) {
    return;
  }
  if (!inputValue.value) return;

  // ✅ 修复 1: 清空初始欢迎消息,避免干扰
  chatList.value = [];

  // 保存输入内容
  const question = inputValue.value;
  inputValue.value = '';

  // 添加用户消息
  const userMessage = {
    avatar: 'https://tdesign.gtimg.com/site/avatar.jpg',
    name: '宇宙无敌大韭菜',
    datetime: new Date().toISOString(),
    content: question,
    role: 'user',
    reasoning: '',
  };
  chatList.value.unshift(userMessage);

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

  // 记录当前正在生成的消息索引
  currentGeneratingIndex.value = 0;

  loading.value = true;
  isStreamLoad.value = true;

  // 调用 ChatWithAgent
  ChatWithAgent(question, selectValue.value, 0).catch((err) => {
    console.error('ChatWithAgent error:', err);
    isStreamLoad.value = false;
    loading.value = false;
    currentGeneratingIndex.value = -1;

    if (currentGeneratingIndex.value >= 0 && currentGeneratingIndex.value < chatList.value.length) {
      chatList.value[currentGeneratingIndex.value].content = '抱歉，发生了错误，请重试。';
      chatList.value = [...chatList.value];
    }
  });
};
```

### 关键改动:

1. **在发送消息前清空 chatList**:
   ```javascript
   chatList.value = [];
   ```
   - 移除初始的欢迎消息
   - 避免旧消息干扰新消息的渲染
   - 确保 TDesign 组件重新初始化

2. **先保存 question,再清空 inputValue**:
   ```javascript
   const question = inputValue.value;
   inputValue.value = '';
   // 然后再添加消息...
   ```
   - 避免 inputValue 在使用前被清空

### 解决方案: 改进响应式更新方式

**修改事件处理器**:

```javascript
EventsOn("agent-message", (data) => {
  console.log('=== agent-message event ===')
  console.log('Raw data:', data)
  console.log('Current generating index:', currentGeneratingIndex.value)
  console.log('Chat list length:', chatList.value.length)

  if(data?.role === "assistant"){
    loading.value = false;

    const lastIndex = currentGeneratingIndex.value;

    if (lastIndex < 0 || lastIndex >= chatList.value.length) {
      console.error('Invalid message index:', lastIndex);
      return;
    }

    // ✅ 关键修复: 创建新对象而非修改旧对象
    const oldItem = chatList.value[lastIndex];
    const newItem = {
      ...oldItem,
      content: oldItem.content + (data.content || ''),
      reasoning: oldItem.reasoning + (data.reasoning_content || data.RespContent || '')
    };

    // ✅ 替换数组中的对象
    chatList.value[lastIndex] = newItem;

    // ✅ 强制触发响应式更新
    chatList.value = [...chatList.value];
  }

  const finishReason = data?.response_meta?.finish_reason;
  if (finishReason === "stop" || finishReason === "length") {
    console.log('Stream finished:', finishReason);
    isStreamLoad.value = false;
    loading.value = false;
    currentGeneratingIndex.value = -1;
  }

  if (data?.error) {
    console.error('Stream error:', data.error);
    isStreamLoad.value = false;
    loading.value = false;
    currentGeneratingIndex.value = -1;
  }
})
```

**关键改进**:
- 使用展开运算符创建**新对象**
- 确保对象引用改变,触发 Vue 响应式
- 同时保留 avatar 等其他属性

---

## 四、可能的其他问题

### 问题 A: TDesign 组件版本问题

检查 `package.json` 中的 TDesign 版本:
```json
{
  "dependencies": {
    "@tdesign-vue-next/chat": "^0.4.5"
  }
}
```

**可能的问题**:
- TDesign Chat 组件本身有 bug
- 版本过旧,不支持流式更新

**解决方案**:
- 尝试升级到最新版本
- 或者考虑使用其他聊天组件

### 问题 B: Wails 事件序列化问题

**后端代码** (app_common.go):
```go
func (a *App) ChatWithAgent(question string, aiConfigId int, sysPromptId *int) {
	ch := agent.NewStockAiAgentApi().Chat(question, aiConfigId, sysPromptId)
	for msg := range ch {
		runtime.EventsEmit(a.ctx, "agent-message", msg)  // 直接发送 Go 结构体
	}
}
```

**可能的问题**:
- Go 的 `schema.Message` 结构体序列化到 JS 时,字段名可能不同
- 某些字段可能被忽略或转换错误

**调试方法**:
```javascript
EventsOn("agent-message", (data) => {
  console.log('Full data object:', JSON.stringify(data, null, 2))
  // 这将显示完整的 JSON 结构
})
```

### 问题 C: TDesign 的 content 类型要求

**TDesign Chat 文档** 可能要求:
- `content` 必须是**字符串**
- 不支持 `null` 或 `undefined`
- 空字符串可能有特殊处理

**检查**:
```javascript
// 确保初始化时 content 是空字符串
content: '',  // ✅ 正确
content: null,  // ❌ 可能导致问题
```

---

## 五、紧急修复代码

完全替换 `agent-chat.vue` 的关键部分:

```vue
<script setup lang="ts">
import {ref, onMounted, h, onBeforeUnmount, onBeforeMount, nextTick} from 'vue';

// ... 其他导入 ...

// ✅ 修复: 移除初始欢迎消息
const chatList = ref([]);

// ✅ 修复: 改进的事件处理器
EventsOn("agent-message", (data) => {
  console.log('=== agent-message ===', {
    role: data?.role,
    content: data?.content,
    reasoning: data?.reasoning_content,
    respContent: data?.RespContent,
    index: currentGeneratingIndex.value,
    listLength: chatList.value.length
  })

  if (data?.role === "assistant") {
    loading.value = false;
    const lastIndex = currentGeneratingIndex.value;

    if (lastIndex < 0 || lastIndex >= chatList.value.length) {
      console.error('❌ Invalid index:', lastIndex);
      return;
    }

    const oldItem = chatList.value[lastIndex];
    const contentChunk = data?.content || data?.RespContent || '';
    const reasoningChunk = data?.reasoning_content || '';

    // ✅ 创建新对象
    const newItem = {
      ...oldItem,
      content: oldItem.content + contentChunk,
      reasoning: oldItem.reasoning + reasoningChunk
    };

    // ✅ 替换并触发更新
    chatList.value[lastIndex] = newItem;
    chatList.value = [...chatList.value];

    console.log('✅ Updated:', {
      index: lastIndex,
      contentLength: newItem.content.length,
      reasoningLength: newItem.reasoning.length
    })
  }

  const finishReason = data?.response_meta?.finish_reason;
  if (finishReason === "stop" || finishReason === "length") {
    console.log('✅ Stream finished');
    isStreamLoad.value = false;
    loading.value = false;
    currentGeneratingIndex.value = -1;
  }
})

const inputEnter = function () {
  if (isStreamLoad.value) return;
  if (!inputValue.value) return;

  const question = inputValue.value;
  inputValue.value = '';

  // ✅ 清空旧消息
  chatList.value = [];

  // 添加用户消息
  chatList.value.unshift({
    avatar: 'https://tdesign.gtimg.com/site/avatar.jpg',
    name: '宇宙无敌大韭菜',
    datetime: new Date().toISOString(),
    content: question,
    role: 'user',
    reasoning: '',
  });

  // 添加 AI 空消息
  chatList.value.unshift({
    avatar: h(NImage, { src: icon.value, height: '48px', width: '48px'}),
    name: 'Go-Stock AI',
    datetime: new Date().toISOString(),
    content: '',
    reasoning: '',
    role: 'assistant',
  });

  currentGeneratingIndex.value = 0;
  loading.value = true;
  isStreamLoad.value = true;

  ChatWithAgent(question, selectValue.value, 0)
    .catch(err => {
      console.error('❌ ChatWithAgent error:', err);
      chatList.value[currentGeneratingIndex.value].content = '抱歉，发生了错误，请重试。';
      chatList.value = [...chatList.value];
      isStreamLoad.value = false;
      loading.value = false;
      currentGeneratingIndex.value = -1;
    });
};
</script>
```

---

## 六、诊断步骤

请按以下步骤测试:

### 步骤 1: 检查控制台日志

发送消息后,检查控制台:
```
应该看到:
=== agent-message event ===
Content: "我是," (或其他内容)
Updated content, new length: 3
✅ Updated: { index: 0, contentLength: 3 }
```

### 步骤 2: 检查数据是否累加

在控制台输入:
```javascript
console.log('Current chatList[0]:', chatList.value[0])
```
应该看到 content 逐渐增长

### 步骤 3: 检查 TDesign 组件

在控制台输入:
```javascript
console.log('TChat data:', chatRef.value)
```

### 步骤 4: 强制重新渲染

在控制台输入:
```javascript
chatList.value = [...chatList.value]
```

### 步骤 5: 如果还是不行

问题可能在 TDesign 组件本身,考虑:
1. 升级 TDesign Vue Next Chat 版本
2. 或者改用其他聊天组件(如 naive-ui 的聊天组件)
3. 或者自己实现简单的聊天界面

---

## 七、备选方案: 使用原生实现

如果 TDesign 组件确实有问题,可以用简单的原生实现替换:

```vue
<template #content="{ item, index }">
  <div class="message" :class="`message-${item.role}`">
    <div class="message-avatar">{{ item.name.charAt(0) }}</div>
    <div class="message-content">
      <div v-if="item.reasoning" class="reasoning">{{ item.reasoning }}</div>
      <div class="content">{{ item.content }}</div>
    </div>
  </div>
</template>
```

**优点**:
- 完全控制渲染逻辑
- 避免第三方组件的问题
- 更容易调试

---

*文档版本: v3.0 - 深度分析*
*创建日期: 2025-01-17*

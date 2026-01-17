<template>
  <div class="chat-box">
    <t-chat
        ref="chatRef"
        :clear-history="chatList.length > 0 && !isStreamLoad"
        :data="chatList"
        :text-loading="loading"
        :is-stream-load="isStreamLoad"
        style="height: 100%"
        @scroll="handleChatScroll"
        @clear="clearConfirm"
    >
      <!-- eslint-disable vue/no-unused-vars -->
      <template #content="{ item, index }">
        <t-chat-reasoning v-if="item.role === 'assistant' && item.reasoning.length > 0" expand-icon-placement="right">
          <t-chat-content :content="item.reasoning" />
        </t-chat-reasoning>
        <t-chat-content v-if="item.content.length > 0" :content="item.content" />
      </template>
      <template #actions="{ item, index }">
        <t-chat-action
            :content="item.content"
            :operation-btn="['copy']"
            @operation="handleOperation"
        />
      </template>
      <template #footer>
<!--        <t-chat-input :stop-disabled="isStreamLoad" @send="inputEnter" @stop="onStop"> </t-chat-input>-->
          <t-chat-sender
              ref="chatSenderRef"
              v-model="inputValue"
              class="chat-sender"
              :textarea-props="{
                placeholder: '请输入消息...',
              }"
              :loading="loading"
              :stop-disabled="isStreamLoad"
              @send="inputEnter"
              @stop="onStop"
          >
            <template #suffix>
              <!-- 监听键盘回车发送事件需要在sender组件监听 -->
              <t-button theme="default" variant="text" size="large" class="btn" @click="inputEnter"> 发送 </t-button>
            </template>
            <template #prefix>
              <NFlex>
                <NSelect
                    v-model:value="selectValue"
                    :options="selectOptions"
                    label-field="name" value-field="ID"
                    size="tiny"
                    style="width: 200px;"
                />
              </NFlex>
            </template>
          </t-chat-sender>

      </template>
    </t-chat>
    <t-button v-show="isShowToBottom" variant="text" class="bottomBtn" @click="backBottom">
      <div class="to-bottom">
        <ArrowDownIcon />
      </div>
    </t-button>
  </div>
</template>
<script setup lang="ts">
import {ref, onMounted, h, onBeforeUnmount, onBeforeMount} from 'vue';
import {ArrowDownIcon, CheckCircleIcon, SystemSumIcon} from 'tdesign-icons-vue-next';
const fetchCancel = ref(null);
const loading = ref(false);

const inputValue = ref('');
// 流式数据加载中
const isStreamLoad = ref(false);

const chatRef = ref(null);
const isShowToBottom = ref(false);

const icon = ref('https://raw.githubusercontent.com/ArvinLovegood/lumos-stock/master/build/appicon.png');
import {darkTheme, NFlex, NImage,NSelect} from "naive-ui";
import {ChatWithAgent, GetAiConfigs, GetConfig, GetSponsorInfo, GetVersionInfo} from "../../wailsjs/go/main/App";
import {EventsOff, EventsOn} from '../../wailsjs/runtime'
import 'tdesign-vue-next/es/style/index.css';


const allowToolTip = ref(true);
const chatSenderRef = ref(null);
const selectOptions = ref([]);
const selectValue = ref("default");

// 修复: 跟踪当前正在生成的消息索引
const currentGeneratingIndex = ref(-1);

onBeforeUnmount(() => {
  EventsOff("agent-message")
  currentGeneratingIndex.value = -1;
})

// 用于累积内容的临时存储
const accumulatedContent = ref('');
const accumulatedReasoning = ref('');

EventsOn("agent-message", (data) => {
  console.log('=== RAW DATA FROM GO ===')
  console.log('typeof data:', typeof data)
  console.log('data keys:', Object.keys(data || {}))
  console.log('full data:', JSON.stringify(data, null, 2))

  if (data?.role === "assistant") {
    loading.value = false;
    const lastIndex = currentGeneratingIndex.value;

    if (lastIndex < 0 || lastIndex >= chatList.value.length) {
      console.error('❌ Invalid index:', lastIndex, 'length:', chatList.value.length);
      return;
    }

    // 尝试所有可能的字段名
    const contentPart = data?.content || data?.Content || '';
    const reasoningPart = data?.reasoning_content || data?.ReasoningContent || '';

    console.log('📦 Content part:', JSON.stringify(contentPart), 'type:', typeof contentPart)
    console.log('📦 Reasoning part:', JSON.stringify(reasoningPart), 'type:', typeof reasoningPart)

    // 累积内容
    accumulatedContent.value += contentPart;
    accumulatedReasoning.value += reasoningPart;

    console.log('📊 Accumulated content length:', accumulatedContent.value.length)
    console.log('📊 Accumulated reasoning length:', accumulatedReasoning.value.length)

    // 创建完全新的数组
    const newChatList = chatList.value.map((item, idx) => {
      if (idx === lastIndex) {
        // 返回一个全新的对象
        return {
          avatar: item.avatar,
          name: item.name,
          datetime: item.datetime,
          role: item.role,
          content: accumulatedContent.value,
          reasoning: accumulatedReasoning.value,
        };
      }
      return item;
    });

    // 完全替换数组
    chatList.value = newChatList;
  }

  const finishReason = data?.response_meta?.finish_reason;
  if (finishReason === "stop" || finishReason === "length") {
    console.log('✅ Stream finished, total content length:', accumulatedContent.value.length);
    isStreamLoad.value = false;
    loading.value = false;
    currentGeneratingIndex.value = -1;
    accumulatedContent.value = '';
    accumulatedReasoning.value = '';
  }

  if (data?.error) {
    console.error('❌ Stream error:', data.error);
    isStreamLoad.value = false;
    loading.value = false;
    currentGeneratingIndex.value = -1;
  }
})
onBeforeMount(() => {
  GetAiConfigs().then(res=>{
    console.log(res)
    selectOptions.value = res
    selectValue.value = res[0].ID
  })
})

onMounted(() => {
  //chatRef.value.scrollToBottom();

  GetConfig().then((res) => {
    if (res.darkTheme) {
      document.documentElement.setAttribute("theme-mode", "dark");
    } else {
      document.documentElement.removeAttribute("theme-mode");    }
  })


  GetVersionInfo().then((res) => {
    icon.value = res.icon;
  });

});

// 滚动到底部
const backBottom = () => {
  chatRef.value.scrollToBottom({
    behavior: 'smooth',
  });
};
// 是否显示回到底部按钮
const handleChatScroll = function ({ e }) {
  const scrollTop = e.target.scrollTop;
  isShowToBottom.value = scrollTop < 0;
};
// 清空消息
const clearConfirm = function () {
  chatList.value = [];
};
const handleOperation = function (type, options) {
  console.log('handleOperation', type, options);
};
// 倒序渲染
const chatList = ref([
  // {
  //   content: `模型由<span>hunyuan</span>变为<span>GPT4</span>`,
  //   role: 'model-change',
  //   reasoning: '',
  // },
  {
    avatar: h(NImage, { src: icon.value, height: '48px', width: '48px'}),
    name: 'Go-Stock AI',
    datetime: '',
    reasoning: '',
    content: '我是您的AI赋能股票分析助手,您可以问我任何关于股票投资方面的问题。',
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

const onStop = function () {
  if (fetchCancel.value) {
    fetchCancel.value.controller.close();
    loading.value = false;
    isStreamLoad.value = false;
    currentGeneratingIndex.value = -1;  // 修复 8: 停止时重置索引
  }
};

const inputEnter = function () {
  if (isStreamLoad.value) return;
  if (!inputValue.value) return;

  const question = inputValue.value;
  inputValue.value = '';

  // 重置累积器
  accumulatedContent.value = '';
  accumulatedReasoning.value = '';

  // 清空旧消息
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

  console.log('🚀 Starting chat, index:', 0, 'question:', question)

  ChatWithAgent(question, selectValue.value, 0)
    .catch(err => {
      console.error('❌ ChatWithAgent error:', err);
      chatList.value[currentGeneratingIndex.value] = {
        ...chatList.value[currentGeneratingIndex.value],
        content: '抱歉，发生了错误，请重试。'
      };
      chatList.value = [...chatList.value];
      isStreamLoad.value = false;
      loading.value = false;
      currentGeneratingIndex.value = -1;
    });
};
</script>
<style lang="less">
/* 应用滚动条样式 */
::-webkit-scrollbar-thumb {
  background-color: var(--td-scrollbar-color);
}
::-webkit-scrollbar-thumb:horizontal:hover {
  background-color: var(--td-scrollbar-hover-color);
}
::-webkit-scrollbar-track {
  background-color: var(--td-scroll-track-color);
}
.chat-box {
  position: relative;
  height: 100%;
  margin: 5px 10px 5px 10px;
  text-align: left;
  .bottomBtn {
    position: absolute;
    left: 50%;
    margin-left: -20px;
    bottom: 210px;
    padding: 0;
    border: 0;
    width: 40px;
    height: 40px;
    border-radius: 50%;
    box-shadow: 0px 8px 10px -5px rgba(0, 0, 0, 0.08), 0px 16px 24px 2px rgba(0, 0, 0, 0.04),
    0px 6px 30px 5px rgba(0, 0, 0, 0.05);
  }
  .to-bottom {
    width: 40px;
    height: 40px;
    border: 1px solid #dcdcdc;
    box-sizing: border-box;
    background: var(--td-bg-color-container);
    border-radius: 50%;
    font-size: 24px;
    line-height: 40px;
    display: flex;
    align-items: center;
    justify-content: center;
    .t-icon {
      font-size: 24px;
    }
  }
}

.model-select {
  display: flex;
  align-items: center;
  .t-select {
    width: 112px;
    height: 32px;
    margin-right: 8px;
    .t-input {
      border-radius: 32px;
      padding: 0 15px;
    }
  }
  .check-box {
    width: 112px;
    height: 32px;
    border-radius: 32px;
    border: 0;
    background: #e7e7e7;
    color: rgba(0, 0, 0, 0.9);
    box-sizing: border-box;
    flex: 0 0 auto;
    .t-button__text {
      display: flex;
      align-items: center;
      justify-content: center;
      span {
        margin-left: 4px;
      }
    }
  }
  .check-box.is-active {
    border: 1px solid #d9e1ff;
    background: #f2f3ff;
    color: var(--td-brand-color);
  }
}


.chat-sender {
  .btn {
    color: var(--td-text-color-disabled);
    border: none;
    &:hover {
      color: var(--td-brand-color-hover);
      border: none;
      background: none;
    }
  }
  .btn.t-button {
    height: var(--td-comp-size-m);
    padding: 0;
  }
  .model-select {
    display: flex;
    align-items: center;
    .t-select {
      width: 112px;
      height: var(--td-comp-size-m);
      margin-right: var(--td-comp-margin-s);
      .t-input {
        border-radius: 32px;
        padding: 0 15px;
      }
      .t-input.t-is-focused {
        box-shadow: none;
      }
    }
    .check-box {
      width: 112px;
      height: var(--td-comp-size-m);
      border-radius: 32px;
      border: 0;
      background: var(--td-bg-color-component);
      color: var(--td-text-color-primary);
      box-sizing: border-box;
      flex: 0 0 auto;
      .t-button__text {
        display: flex;
        align-items: center;
        justify-content: center;
        span {
          margin-left: var(--td-comp-margin-xs);
        }
      }
    }
    .check-box.is-active {
      border: 1px solid var(--td-brand-color-focus);
      background: var(--td-brand-color-light);
      color: var(--td-text-color-brand);
    }
  }
}

</style>
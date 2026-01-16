<script setup>
// import { MdPreview } from 'md-editor-v3';
// preview.css相比style.css少了编辑器那部分样式
import 'md-editor-v3/lib/preview.css';
import {h, onBeforeUnmount, onMounted, ref} from 'vue';
import {CheckUpdate, GetVersionInfo,GetSponsorInfo,OpenURL} from "../../wailsjs/go/main/App";
import {EventsOff, EventsOn,Environment} from "../../wailsjs/runtime";
import {NAvatar, NButton, useNotification,NText} from "naive-ui";
import { addMonths, format ,parse} from 'date-fns';
import { zhCN } from 'date-fns/locale';
const updateLog = ref('');
const versionInfo = ref('');
const icon = ref('https://raw.githubusercontent.com/ArvinLovegood/lumos-stock/master/build/appicon.png');
const alipay =ref('https://github.com/ArvinLovegood/lumos-stock/raw/master/build/screenshot/alipay.jpg')
const wxpay =ref('https://github.com/ArvinLovegood/lumos-stock/raw/master/build/screenshot/wxpay.jpg')
const wxgzh =ref('https://github.com/ArvinLovegood/lumos-stock/raw/dev/build/screenshot/%E6%89%AB%E7%A0%81_%E6%90%9C%E7%B4%A2%E8%81%94%E5%90%88%E4%BC%A0%E6%92%AD%E6%A0%B7%E5%BC%8F-%E7%99%BD%E8%89%B2%E7%89%88.png')
const notify = useNotification()
const vipLevel=ref("");
const vipStartTime=ref("");
const vipEndTime=ref("");
const expired=ref(false)

onMounted(() => {
  document.title = '关于软件';
  GetVersionInfo().then((res) => {
    updateLog.value = res.content;
    versionInfo.value = res.version;
    icon.value = res.icon;
    alipay.value=res.alipay;
    wxpay.value=res.wxpay;
    wxgzh.value=res.wxgzh;

    GetSponsorInfo().then((res) => {
      vipLevel.value = res.vipLevel;
      vipStartTime.value = res.vipStartTime;
      vipEndTime.value = res.vipEndTime;
      //判断时间是否到期
      if (res.vipLevel) {
        if (res.vipEndTime < format(new Date(), 'yyyy-MM-dd HH:mm:ss')) {
          notify.warning({content: 'VIP已到期'})
          expired.value = true;
        }
      }
    })

  });



})
onBeforeUnmount(() => {
  notify.destroyAll()
  EventsOff("updateVersion")
})

EventsOn("updateVersion",async (msg) => {
  const githubTimeStr = msg.published_at;
  // 创建一个 Date 对象
  const utcDate = new Date(githubTimeStr);
// 获取本地时间
  const date = new Date(utcDate.getTime());
  const year = date.getFullYear();
// getMonth 返回值是 0 - 11，所以要加 1
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  const hours = String(date.getHours()).padStart(2, '0');
  const minutes = String(date.getMinutes()).padStart(2, '0');
  const seconds = String(date.getSeconds()).padStart(2, '0');

  const formattedDate = `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;

  //console.log("GitHub UTC 时间:", utcDate);
  //console.log("转换后的本地时间:", formattedDate);
  notify.info({
    avatar: () =>
        h(NAvatar, {
          size: 'small',
          round: false,
          src: icon.value
        }),
    title: '发现新版本: ' + msg.tag_name,
    content: () => {
      //return h(MdPreview, {theme:'dark',modelValue:msg.commit?.message}, null)
      return h('div', {
        style: {
          'text-align': 'left',
          'font-size': '14px',
        }
      }, { default: () => msg.commit?.message })
    },
    duration: 5000,
    meta: "发布时间:"+formattedDate,
    action: () => {
      return h(NButton, {
        type: 'primary',
        size: 'small',
        onClick: () => {
          Environment().then(env => {
            switch (env.platform) {
              case 'windows':
                window.open(msg.html_url)
                break
              default :
                OpenURL(msg.html_url)
                break
            }
          })
        }
      }, { default: () => '查看' })
    }
  })
})

</script>

<template>
      <n-space vertical size="large"  style="--wails-draggable:no-drag">
        <!-- 软件描述 -->
        <n-card size="large">
          <n-divider title-placement="center">关于软件</n-divider>
      
          <n-divider title-placement="center">鸣谢</n-divider>
         
          <n-divider title-placement="center">关于版权和技术支持申明</n-divider>
      

        </n-card>
      </n-space>
</template>

<style scoped>
/* 可以在这里添加一些样式 */
h1, h2 {
  margin: 0;
  padding: 6px 0;
}

p {
  margin: 2px 0;
}

ul {
  list-style-type: disc;
  padding-left: 20px;
}

a {
  color: #18a058;
  text-decoration: none;
}

a:hover {
  text-decoration: underline;
}
</style>

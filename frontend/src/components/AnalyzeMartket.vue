<script setup>

import {AnalyzeSentimentWithFreqWeight} from "../../wailsjs/go/main/App";
import * as echarts from "echarts";
import {onMounted,onUnmounted, ref} from "vue";
import _ from "lodash";
const { name,darkTheme,kDays ,chartHeight} = defineProps({
  name: {
    type: String,
    default: ''
  },
  kDays: {
    type: Number,
    default: 14
  },
  chartHeight: {
    type: Number,
    default: 500
  },
  darkTheme: {
    type: Boolean,
    default: false
  }
})
const chartRef = ref(null);
const gaugeChartRef = ref(null);
let handleChartInterval=null
onMounted(() => {
  handleChart()
  handleChartInterval=setInterval(function () {
    handleChart()
  }, 1000 * 60)
})

onUnmounted(()=>{
  clearInterval(handleChartInterval)
})

function  handleChart(){
  const formatUtil = echarts.format;
  AnalyzeSentimentWithFreqWeight("").then((res) => {
    console.log(res)
    const treemapchart = echarts.init(chartRef.value);
    const gaugeChart=echarts.init(gaugeChartRef.value);
    let option = {
      title: {
        text:name,
        left: 'center'
      },
      legend: {
        show: false
      },
      tooltip: {
        formatter: function (info) {
          var value = info.value;
          var frequency = info.data.frequency;
          var weight = info.data.weight;
          return [
            '<div class="tooltip-title">' + info.name+ '</div>',
            '热度: ' + formatUtil.addCommas(value) + '',
            '<div class="tooltip-title">频次: ' +  formatUtil.addCommas(frequency)+ '</div>',
            '<div class="tooltip-title">权重: ' +  formatUtil.addCommas(weight)+ '</div>',
          ].join('');
        }
      },
      series: [
        {
          type: 'treemap',
          left: '0',
          top: '0',
          right: '0',
          bottom: '0',
          tooltip: {
            show: true
          },
          data: res['frequencies'].map(item => ({
            name: item.Word,
            // value: item.Frequency,
            // value: item.Weight,
            frequency: item.Frequency,
            weight: item.Weight,
            value: item.Score,
          }))
        }
      ]
    };
    treemapchart.setOption(option);



    let option2 = {
      series: [
        {
          type: 'gauge',
          startAngle: 180,
          endAngle: 0,
          center: ['50%', '75%'],
          radius: '90%',
          min: 0,
          max: 1,
          splitNumber: 8,
          axisLine: {
            lineStyle: {
              width: 6,
              color: [
                // [0.25, '#FF6E76'],
                // [0.5, '#FDDD60'],
                // [0.75, '#58D9F9'],
                // [1, '#7CFFB2'],

                [0.25, '#02f423'],
                [0.5, '#58D9F9'],
                [0.75, 'rgb(241,115,14)'],
                [1, '#fa242f']
              ]
            }
          },
          pointer: {
            icon: 'path://M12.8,0.7l12,40.1H0.7L12.8,0.7z',
            length: '12%',
            width: 20,
            offsetCenter: [0, '-60%'],
            itemStyle: {
              color: 'auto'
            }
          },
          axisTick: {
            length: 12,
            lineStyle: {
              color: 'auto',
              width: 2
            }
          },
          splitLine: {
            length: 20,
            lineStyle: {
              color: 'auto',
              width: 5
            }
          },
          axisLabel: {
            color: '#464646',
            fontSize: 20,
            distance: -60,
            rotate: 'tangential',
            formatter: function (value) {
              if (value === 0.875) {
                return '极热';
              } else if (value === 0.625) {
                return '乐观';
              } else if (value === 0.375) {
                return '谨慎';
              } else if (value === 0.125) {
                return '冰点';
              }
              return '';
            }
          },
          title: {
            offsetCenter: [0, '-10%'],
            fontSize: 20
          },
          detail: {
            fontSize: 30,
            offsetCenter: [0, '-35%'],
            valueAnimation: true,
            formatter: function (value) {
              return value.toFixed(2) + '';
            },
            color: 'inherit'
          },
          data: [
            {
              value: res.result.Score/100.0,
              name: '市场情绪'
            }
          ]
        }
      ]
    };
    gaugeChart.setOption(option2);
  })
}
</script>

<template>
  <n-grid :cols="24" :y-gap="0">
    <n-gi span="6">
      <div ref="gaugeChartRef" style="width: 100%;height: auto;--wails-draggable:no-drag" :style="{height:chartHeight+'px'}" ></div>
    </n-gi>
    <n-gi span="18">
      <div ref="chartRef" style="width: 100%;height: auto;--wails-draggable:no-drag" :style="{height:chartHeight+'px'}" ></div>
    </n-gi>
  </n-grid>
</template>

<style scoped>

</style>
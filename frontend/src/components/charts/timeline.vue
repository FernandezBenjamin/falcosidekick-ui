<template>
  <div>
    <canvas
      :id="id"
      height="80"
      class="ml-10 pr-15"
    ></canvas>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useRoute } from 'vue-router';
import { Chart as ChartJS, registerables } from 'chart.js';
import dayjs from 'dayjs';
import 'chartjs-adapter-moment';
import { requests } from '../../http';
import { utils } from '../../utils';

ChartJS.register(...registerables);

const store = useStore();
const route = useRoute();

const props = defineProps({
  id: { type: String, default: 'timeline-chart' },
  width: { type: Number, default: 400 },
  height: { type: Number, default: 400 },
  groupby: { type: String, default: '' },
  filters: {
    type: Object,
    default() {
      return {
        priorities: [],
        rule: [],
        tags: [],
        hostnames: [],
        sources: [],
        search: '',
        since: '',
      };
    },
  },
});

const emit = defineEmits(['picked-item']);

const chart = ref({});
const bgColor = ref('#f00');
const chartData = ref({
  type: 'bar',
  data: {
    datasets: [{
      label: 'test',
      barThickness: 25,
      backgroundColor: '#1976d2',
      data: [],
    }],
  },
  options: {
    responsive: true,
    animation: false,
    onClick: pickItem,
    scales: {
      x: {
        type: 'time',
        display: true,
        stacked: true,
      },
      y: {
        display: true,
        stacked: true,
        ticks: {
          beginAtZero: true,
        },
      },
    },
  },
});
const stats = ref([]);

const ticer = computed(() => store.state.ticer);

function pickItem(event, array) {
  if (array.length > 0) {
    emit('picked-item', props.groupby, chartData.value.data.datasets[array[0].datasetIndex].label);
  }
}

function searchEvents(page, last) {
  const limit = 500;
  let results = [];
  let returned = 0;
  let l = last;
  requests.searchEvents(
    props.filters.sources,
    props.filters.hostnames,
    props.filters.priorities,
    props.filters.rule,
    props.filters.search,
    props.filters.tags,
    props.filters.since,
    page,
    limit,
  )
    .then((response) => {
      results = response.data.results; // eslint-disable-line
      returned = response.data.statistics.returned; // eslint-disable-line
      if (results.length === 0) {
        chart.value.update();
        return;
      }
      let unit = '';
      let delta = '';
      let oldest = '';
      switch (props.filters.since) {
        case '5min':
          chartData.value.options.scales.x.time.unit = 'second';
          unit = 'second'; delta = 5; oldest = 300; break;
        case '15min':
          chartData.value.options.scales.x.time.unit = 'second';
          unit = 'second'; delta = 25; oldest = 1500; break;
        case '30min':
          chartData.value.options.scales.x.time.unit = 'minute';
          unit = 'second'; delta = 48; oldest = 3000; break;
        case '1h':
          chartData.value.options.scales.x.time.unit = 'minute';
          unit = 'minute'; delta = 1; oldest = 60; break;
        case '2h':
          chartData.value.options.scales.x.time.unit = 'minute';
          unit = 'minute'; delta = 2; oldest = 120; break;
        case '5h':
          chartData.value.options.scales.x.time.unit = 'minute';
          unit = 'minute'; delta = 5; oldest = 300; break;
        case '12h':
          chartData.value.options.scales.x.time.unit = 'minute';
          unit = 'minute'; delta = 12; oldest = 720; break;
        case '24h':
          chartData.value.options.scales.x.time.unit = 'hour';
          unit = 'minute'; delta = 24; oldest = 1440; break;
        case '48h':
          chartData.value.options.scales.x.time.unit = 'hour';
          unit = 'minute'; delta = 48; oldest = 2880; break;
        case '1w':
          chartData.value.options.scales.x.time.unit = 'day';
          unit = 'hour'; delta = 3; oldest = 168; break;
        case '2w':
          chartData.value.options.scales.x.time.unit = 'day';
          unit = 'hour'; delta = 6; oldest = 336; break;
        case '1M':
          chartData.value.options.scales.x.time.unit = 'day';
          unit = 'hour'; delta = 12; oldest = 724; break;
        case '3M':
          chartData.value.options.scales.x.time.unit = 'day';
          unit = 'hour'; delta = 36; oldest = 2160; break;
        case '6M':
          chartData.value.options.scales.x.time.unit = 'month';
          unit = 'hour'; delta = 72; oldest = 4320; break;
        case '1y':
          chartData.value.options.scales.x.time.unit = 'month';
          unit = 'day'; delta = 15; oldest = 365; break;
        case '2y':
          chartData.value.options.scales.x.time.unit = 'quarter';
          unit = 'day'; delta = 30; oldest = 730; break;
            default:
              break;
          }
          if (l === undefined) {
            l = dayjs().add(delta, unit).toISOString();
          }
      Object.values(results).forEach((value) => {
        let f = '';
        switch (props.groupby) {
          case 'priority':
            f = value.priority;
            break;
          case 'source':
            f = value.source;
            break;
          default:
            f = 'all';
            break;
        }
        if (stats.value[f] === undefined) {
          stats.value[f] = {
            count: 0,
            data: [{ x: l, y: 0 }],
          };
        }
        stats.value[f].count += 1;
        if (dayjs(value.time)
          .isBefore(dayjs(l).subtract(delta, unit))) {
          Object.keys(stats.value).forEach((key) => {
            stats.value[key].data.push({
              x: l,
              y: stats.value[key].count,
            });
            stats.value[key].count = 0;
          });
          l = value.time;
          stats.value[f].count = 0;
        }
      });
      if (limit === returned) {
        let d = 1;
        if (page === 0) {
          d = 2;
        }
        searchEvents(page + d, l);
      }
      let i = 0;
      Object.keys(stats.value).forEach((key) => {
        stats.value[key].data.push({
          x: dayjs().subtract(oldest - delta, unit).toISOString(),
          y: 0,
        });
        let bgc = '';
        switch (props.groupby) {
          case 'priority':
            bgc = utils.priorityToColor(key);
            break;
          case 'source':
            bgc = utils.stringToColor(key);
            break;
          default:
            bgc = '#1976d2';
            break;
        }
        chartData.value.data.datasets[i] = {
          label: key,
          barThickness: 25,
          backgroundColor: bgc,
          data: stats.value[key].data,
        };
        i += 1;
      });
      chartData.value.data.datasets.sort((data1, data2) => compareDatasets(data1, data2));
      chart.value.update();
    });
}

function compareDatasets(data1, data2) {
  const obj1 = data1.label.toUpperCase();
  const obj2 = data2.label.toUpperCase();
  if (obj1 < obj2) { return -1; }
  if (obj1 > obj2) { return 1; }
  return 0;
}

function updateChart() {
  chartData.value.data.datasets = [];
  stats.value = {};
  searchEvents(0);
}

// Initialize from route query
if (typeof route.query.source !== 'undefined') {
  props.filters.sources = route.query.source;
}
if (typeof route.query.hostname !== 'undefined') {
  props.filters.hostnames = route.query.hostname;
}
if (typeof route.query.priority !== 'undefined') {
  props.filters.priorities = route.query.priority;
}
if (typeof route.query.rule !== 'undefined') {
  props.filters.rule = route.query.rule;
}
if (typeof route.query.tags !== 'undefined') {
  props.filters.tags = route.query.tags;
}
if (typeof route.query.filter !== 'undefined') {
  props.filters.search = route.query.filter;
}
if (typeof route.query.since !== 'undefined') {
  props.filters.since = route.query.since;
}

watch(() => props.filters, () => {
  updateChart();
}, { deep: true });

watch(ticer, () => {
  updateChart();
});

onMounted(() => {
  const ctx = document.getElementById(props.id);
  chart.value = new ChartJS(ctx, chartData.value); // eslint-disable-line
  updateChart();
});
</script>

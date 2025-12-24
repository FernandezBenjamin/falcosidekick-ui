<template>
  <div>
    <canvas
      :id="id"
      height="400"
      class="ml-10 pr-15"
    ></canvas>
  </div>
</template>
<script setup>
import { ref, computed, watch, onMounted, nextTick, shallowRef, toRaw } from 'vue';
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
  filterKey: { type: Number, default: 0 },
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
const chart = shallowRef(null);
const stats = ref({});
const isUpdating = ref(false);
const ticer = computed(() => store.state.ticer);
function pickItem(event, array) {
  if (array.length > 0 && chart.value) {
    const dataset = chart.value.data.datasets[array[0].datasetIndex];
    if (dataset) {
      console.log('[TimelineChart] Item clicked:', dataset.label);
      emit('picked-item', props.groupby, dataset.label);
    }
  }
}
function getTimeConfig(since) {
  const configs = {
    '5min': { unit: 'second', delta: 5, oldest: 300 },
    '15min': { unit: 'second', delta: 25, oldest: 1500 },
    '30min': { unit: 'minute', delta: 48, oldest: 3000, timeUnit: 'second' },
    '1h': { unit: 'minute', delta: 1, oldest: 60 },
    '2h': { unit: 'minute', delta: 2, oldest: 120 },
    '5h': { unit: 'minute', delta: 5, oldest: 300 },
    '12h': { unit: 'minute', delta: 12, oldest: 720 },
    '24h': { unit: 'minute', delta: 24, oldest: 1440, timeUnit: 'hour' },
    '48h': { unit: 'minute', delta: 48, oldest: 2880, timeUnit: 'hour' },
    '1w': { unit: 'hour', delta: 3, oldest: 168, timeUnit: 'day' },
    '2w': { unit: 'hour', delta: 6, oldest: 336, timeUnit: 'day' },
    '1M': { unit: 'hour', delta: 12, oldest: 724, timeUnit: 'day' },
    '3M': { unit: 'hour', delta: 36, oldest: 2160, timeUnit: 'day' },
    '6M': { unit: 'hour', delta: 72, oldest: 4320, timeUnit: 'month' },
    '1y': { unit: 'day', delta: 15, oldest: 365, timeUnit: 'month' },
    '2y': { unit: 'day', delta: 30, oldest: 730, timeUnit: 'quarter' },
  };
  const config = configs[since] || { unit: 'minute', delta: 1, oldest: 60, timeUnit: 'minute' };
  return {
    unit: config.unit,
    delta: config.delta,
    oldest: config.oldest,
    timeUnit: config.timeUnit || config.unit,
  };
}
async function searchEvents(page, last) {
  const limit = 500;
  console.log('[TimelineChart] Fetching events - page:', page, 'last:', last);
  // Unwrap reactive proxies before passing to API
  const sources = toRaw(props.filters.sources) || [];
  const hostnames = toRaw(props.filters.hostnames) || [];
  const priorities = toRaw(props.filters.priorities) || [];
  const tags = toRaw(props.filters.tags) || [];
  try {
    const response = await requests.searchEvents(
      sources,
      hostnames,
      priorities,
      props.filters.rule,
      props.filters.search,
      tags,
      props.filters.since,
      page,
      limit,
    );
    // Normalize results to array - handle both array and object responses
    let results = [];
    if (Array.isArray(response.data.results)) {
      results = response.data.results;
    } else if (response.data.results && typeof response.data.results === 'object') {
      results = Object.values(response.data.results);
    }
    const returned = response.data.statistics?.returned || 0;
    console.log('[TimelineChart] Received', results.length, 'events, returned:', returned);
    if (results.length === 0) {
      if (chart.value) {
        chart.value.update();
      }
      return;
    }
    const timeConfig = getTimeConfig(props.filters.since);
    const { unit, delta, oldest } = timeConfig;
    let l = last;
    if (l === undefined) {
      l = dayjs().add(delta, unit).toISOString();
    }
    // Process events
    results.forEach((value) => {
      // Handle both direct event objects and wrapped ones
      const event = value.raw || value;
      let f = '';
      switch (props.groupby) {
        case 'priority':
          f = event.priority || 'Unknown';
          break;
        case 'source':
          f = event.source || 'Unknown';
          break;
        default:
          f = 'all';
          break;
      }
      if (!stats.value[f]) {
        stats.value[f] = {
          count: 0,
          data: [{ x: l, y: 0 }],
        };
      }
      stats.value[f].count += 1;
      if (dayjs(event.time).isBefore(dayjs(l).subtract(delta, unit))) {
        Object.keys(stats.value).forEach((key) => {
          stats.value[key].data.push({
            x: l,
            y: stats.value[key].count,
          });
          stats.value[key].count = 0;
        });
        l = event.time;
        stats.value[f].count = 0;
      }
    });
    // Fetch more pages if needed
    if (limit === returned) {
      let d = 1;
      if (page === 0) {
        d = 2;
      }
      await searchEvents(page + d, l);
    } else {
      // Final processing
      Object.keys(stats.value).forEach((key) => {
        stats.value[key].data.push({
          x: dayjs().subtract(oldest - delta, unit).toISOString(),
          y: 0,
        });
      });
      // Update chart datasets
      if (chart.value) {
        const datasets = [];
        Object.keys(stats.value).forEach((key) => {
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
          datasets.push({
            label: key,
            barThickness: 25,
            backgroundColor: bgc,
            data: stats.value[key].data,
          });
        });
        // Sort datasets
        datasets.sort((data1, data2) => {
          const obj1 = data1.label.toUpperCase();
          const obj2 = data2.label.toUpperCase();
          if (obj1 < obj2) return -1;
          if (obj1 > obj2) return 1;
          return 0;
        });
        // Update chart data (shallowRef prevents deep reactivity)
        chart.value.data.datasets = datasets.map(ds => ({
          label: ds.label,
          barThickness: ds.barThickness,
          backgroundColor: ds.backgroundColor,
          data: [...ds.data]
        }));
        console.log('[TimelineChart] Updated with', datasets.length, 'datasets');
        chart.value.update();
      }
    }
  } catch (error) {
    console.error('[TimelineChart] Error fetching events:', error);
    if (chart.value) {
      chart.value.update();
    }
  }
}
async function updateChart() {
  if (isUpdating.value) {
    console.log('[TimelineChart] Update already in progress, skipping...');
    return;
  }
  isUpdating.value = true;
  console.log('[TimelineChart] Starting chart update');
  try {
    // Reset chart data
    if (chart.value) {
      chart.value.data.datasets = [];
      // Update time scale configuration
      const timeConfig = getTimeConfig(props.filters.since);
      if (chart.value.options.scales && chart.value.options.scales.x && chart.value.options.scales.x.time) {
        chart.value.options.scales.x.time.unit = timeConfig.timeUnit;
      }
    }
    stats.value = {};
    await searchEvents(0);
  } finally {
    isUpdating.value = false;
  }
}
async function initChart() {
  await nextTick(); // Wait for DOM to be ready
  const ctx = document.getElementById(props.id);
  if (!ctx) {
    console.error('[TimelineChart] Canvas element not found with id:', props.id);
    return;
  }
  console.log('[TimelineChart] Initializing chart on canvas:', props.id);
  try {
    chart.value = new ChartJS(ctx, {
      type: 'bar',
      data: {
        datasets: [],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: false,
        onClick: pickItem,
        scales: {
          x: {
            type: 'time',
            display: true,
            stacked: true,
            time: {
              unit: 'minute',
            },
          },
          y: {
            display: true,
            stacked: true,
            ticks: {
              beginAtZero: true,
            },
          },
        },
        plugins: {
          legend: {
            position: 'bottom',
          },
        },
      },
    });
    console.log('[TimelineChart] Chart initialized successfully');
    await updateChart();
  } catch (error) {
    console.error('[TimelineChart] Error initializing chart:', error);
  }
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
watch(() => props.filterKey, () => {
  console.log('[TimelineChart] FilterKey changed, updating chart');
  updateChart();
});
watch(() => props.filters, () => {
  console.log('[TimelineChart] Filters changed, updating chart');
  updateChart();
}, { deep: true });
watch(ticer, () => {
  console.log('[TimelineChart] Ticer changed, updating chart');
  updateChart();
});
onMounted(() => {
  initChart();
});
</script>

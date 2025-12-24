<template>
  <div>
    <canvas
      :id="canvasId"
      height="400"
      class="ml-10 pr-15"
    ></canvas>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted, nextTick, shallowRef, toRaw } from 'vue';
import { useStore } from 'vuex';
import { Chart as ChartJS, Title, Tooltip, Legend, BarElement, CategoryScale, LinearScale } from 'chart.js';
import { requests } from '../../http';

ChartJS.register(Title, Tooltip, Legend, BarElement, CategoryScale, LinearScale);

const store = useStore();

const props = defineProps({
  id: { type: String, default: '' },
  list: { type: String },
  chartId: { type: String, default: 'bar-chart' },
  width: { type: Number, default: 400 },
  height: { type: Number, default: 400 },
  filterKey: { type: Number, default: 0 },
  filters: {
    type: Object,
    default() {
      return {
        priorities: [],
        rule: [],
        tags: [],
        sources: [],
        hostnames: [],
        search: '',
        since: '',
      };
    },
  },
});

const emit = defineEmits(['picked-item']);

const chart = shallowRef(null);
const values = ref({});
const bgColor = '#1976d2';
const canvasId = computed(() => props.id || props.chartId);

const ticer = computed(() => store.state.ticer);

async function updateChart() {
  console.log('[BarChart] Updating chart for list:', props.list);
  console.log('[BarChart] Current filters:', {
    sources: props.filters.sources,
    hostnames: props.filters.hostnames,
    priorities: props.filters.priorities,
    rule: props.filters.rule,
    tags: props.filters.tags,
    since: props.filters.since
  });

  // Unwrap reactive proxies before passing to API
  const sources = toRaw(props.filters.sources) || [];
  const hostnames = toRaw(props.filters.hostnames) || [];
  const priorities = toRaw(props.filters.priorities) || [];
  const tags = toRaw(props.filters.tags) || [];

  try {
    const response = await requests.countByEvents(
      props.list,
      sources,
      hostnames,
      priorities,
      props.filters.rule,
      props.filters.search,
      tags,
      props.filters.since,
    );

    console.log('[BarChart] Received data:', response.data.results);

    values.value = Object.entries(response.data.results)
      .sort(([, v1], [, v2]) => v2 - v1)
      .reduce((obj, [k, v]) => ({ ...obj, [k]: v }), {});
  } catch (error) {
    console.error('[BarChart] Error fetching data:', error);
    values.value = {};
  }

  // Prepare chart data
  const lb = [];
  const dt = [];

  Object.entries(values.value).forEach(([key, value]) => {
    lb.push(key);
    dt.push(value);
  });

  console.log('[BarChart] Chart update - labels:', lb.length, 'data points:', dt.length);

  // Update chart if it exists
  if (chart.value) {
    try {
      // ShallowRef prevents deep reactivity, so we can assign directly
      chart.value.data.labels = [...lb];
      chart.value.data.datasets[0].data = [...dt];

      chart.value.update();
      console.log('[BarChart] Chart updated successfully');
    } catch (error) {
      console.error('[BarChart] Error updating chart:', error);
    }
  } else {
    console.warn('[BarChart] Chart not initialized yet');
  }
}

async function initChart() {
  await nextTick(); // Wait for DOM to be ready

  const ctx = document.getElementById(canvasId.value);
  if (!ctx) {
    console.error('[BarChart] Canvas element not found with id:', canvasId.value);
    return;
  }

  console.log('[BarChart] Initializing chart on canvas:', canvasId.value);

  try {
    chart.value = new ChartJS(ctx, {
      type: 'bar',
      data: {
        labels: [],
        datasets: [{
          label: props.list,
          backgroundColor: bgColor,
          borderColor: 'rgba(0, 0, 0, 0.1)',
          borderWidth: 1,
          data: [],
        }],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: false,
        indexAxis: 'y',
        plugins: {
          legend: {
            position: 'bottom',
          },
        },
        scales: {
          x: {
            beginAtZero: true,
          },
        },
        onClick: (event, activeElements) => {
          if (activeElements && activeElements.length > 0) {
            const labelIndex = activeElements[0].index;
            if (labelIndex < chart.value.data.labels.length) {
              const selectedLabel = chart.value.data.labels[labelIndex];
              console.log('[BarChart] Item clicked:', selectedLabel);
              emit('picked-item', props.list, selectedLabel);
            }
          }
        },
      },
    });
    console.log('[BarChart] Chart initialized successfully');
    await updateChart();
  } catch (error) {
    console.error('[BarChart] Error initializing chart:', error);
  }
}

watch(() => props.filters, () => {
  console.log('[BarChart] Filters changed, updating chart');
  updateChart();
}, { deep: true });

watch(ticer, () => {
  console.log('[BarChart] Ticer changed, updating chart');
  updateChart();
});

onMounted(() => {
  initChart();
});
</script>

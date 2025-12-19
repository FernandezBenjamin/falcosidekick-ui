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
import { ref, computed, watch, onMounted, nextTick, shallowRef } from 'vue';
import { useStore } from 'vuex';
import { Chart as ChartJS, Title, Tooltip, Legend, ArcElement, CategoryScale } from 'chart.js';
import { requests } from '../../http';
import { utils } from '../../utils';

ChartJS.register(Title, Tooltip, Legend, ArcElement, CategoryScale);

const store = useStore();

const props = defineProps({
  id: { type: String, default: '' },
  list: { type: String },
  chartId: { type: String, default: 'pie-chart' },
  width: { type: Number, default: 400 },
  height: { type: Number, default: 400 },
  filterKey: { type: Number, default: 0 },
  filters: {
    type: Object,
    default() {
      return {
        priorities: [],
        rule: '',
        tags: [''],
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
const canvasId = computed(() => props.id || props.chartId);

const ticer = computed(() => store.state.ticer);

async function updateChart() {
  console.log('[PieChart] Updating chart for list:', props.list);
  console.log('[PieChart] Current filters:', {
    sources: props.filters.sources,
    hostnames: props.filters.hostnames,
    priorities: props.filters.priorities,
    rule: props.filters.rule,
    tags: props.filters.tags,
    since: props.filters.since
  });
  
  try {
    const response = await requests.countByEvents(
      props.list,
      props.filters.sources,
      props.filters.hostnames,
      props.filters.priorities,
      props.filters.rule,
      props.filters.search,
      props.filters.tags,
      props.filters.since,
    );
    
    console.log('[PieChart] Received data:', response.data.results);
    
    values.value = Object.entries(response.data.results)
      .sort(([, v1], [, v2]) => v2 - v1)
      .reduce((obj, [k, v]) => ({ ...obj, [k]: v }), {});
  } catch (error) {
    console.error('[PieChart] Error fetching data:', error);
    values.value = {};
  }

  // Prepare chart data
  const lb = [];
  const bgc = [];
  const bdc = [];
  const dt = [];
  
  Object.entries(values.value).forEach(([key, value]) => {
    lb.push(key);
    if (props.list === 'priority') {
      bgc.push(utils.priorityToColor(key));
    } else {
      bgc.push(utils.stringToColor(key));
    }
    bdc.push('rgba(0, 0, 0, 0.1)');
    dt.push(value);
  });
  
  console.log('[PieChart] Chart update - labels:', lb.length, 'data points:', dt.length);

  // Update chart if it exists
  if (chart.value) {
    try {
      // ShallowRef prevents deep reactivity, so we can assign directly
      chart.value.data.labels = [...lb];
      chart.value.data.datasets[0].data = [...dt];
      chart.value.data.datasets[0].backgroundColor = [...bgc];
      chart.value.data.datasets[0].borderColor = [...bdc];
      
      chart.value.update();
      console.log('[PieChart] Chart updated successfully');
    } catch (error) {
      console.error('[PieChart] Error updating chart:', error);
    }
  } else {
    console.warn('[PieChart] Chart not initialized yet');
  }
}

async function initChart() {
  await nextTick(); // Wait for DOM to be ready
  
  const ctx = document.getElementById(canvasId.value);
  if (!ctx) {
    console.error('[PieChart] Canvas element not found with id:', canvasId.value);
    return;
  }
  
  console.log('[PieChart] Initializing chart on canvas:', canvasId.value);
  
  try {
    chart.value = new ChartJS(ctx, {
      type: 'pie',
      data: {
        labels: [],
        datasets: [{
          label: props.list,
          backgroundColor: [],
          borderColor: [],
          borderWidth: 1,
          data: [],
        }],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: false,
        plugins: {
          legend: {
            position: 'bottom',
          },
        },
        onClick: (event, activeElements) => {
          if (activeElements && activeElements.length > 0) {
            const labelIndex = activeElements[0].index;
            if (labelIndex < chart.value.data.labels.length) {
              const selectedLabel = chart.value.data.labels[labelIndex];
              console.log('[PieChart] Item clicked:', selectedLabel);
              emit('picked-item', props.list, selectedLabel);
            }
          }
        },
      },
    });
    console.log('[PieChart] Chart initialized successfully');
    await updateChart();
  } catch (error) {
    console.error('[PieChart] Error initializing chart:', error);
  }
}

watch(() => props.filters, () => {
  console.log('[PieChart] Filters changed, updating chart');
  updateChart();
}, { deep: true });

watch(ticer, () => {
  console.log('[PieChart] Ticer changed, updating chart');
  updateChart();
});

onMounted(() => {
  initChart();
});
</script>

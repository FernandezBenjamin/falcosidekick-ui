<template>
  <div>
    <Bar
      :chart-options="chartOptions"
      :chart-data="chartData"
      :chart-id="chartId"
      :dataset-id-key="datasetIdKey"
      :width="width"
      :height="height"
      v-if="loaded"
    />
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useRoute } from 'vue-router';
import { Bar } from 'vue-chartjs';
import {
  Chart as ChartJS,
  Title,
  Tooltip,
  Legend,
  BarElement,
  CategoryScale,
  LinearScale,
} from 'chart.js';
import { requests } from '../../http';

ChartJS.register(Title, Tooltip, Legend, BarElement, CategoryScale, LinearScale);

const store = useStore();
const route = useRoute();

const props = defineProps({
  list: { type: String },
  chartId: { type: String, default: 'pie-chart' },
  datasetIdKey: { type: String, default: 'label' },
  width: { type: Number, default: 400 },
  height: { type: Number, default: 400 },
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

const loaded = ref(false);
const values = ref({});
const bgColor = ref('#1976d2');
const chartData = ref({
  labels: [],
  datasets: [],
});

const ticer = computed(() => store.state.ticer);

const chartOptions = ref({
  animation: false,
  responsive: true,
  maintainAspectRatio: false,
  onClick: function(event, activeElements) {
    if (activeElements && activeElements.length > 0) {
      const labelIndex = activeElements[0].index;
      if (labelIndex < chartData.value.labels.length) {
        emit('picked-item', props.list, chartData.value.labels[labelIndex]);
      }
    }
  },
});

async function updateChart() {
  loaded.value = false;
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
    console.log('Bar chart data:', response.data.results);
    values.value = Object.entries(response.data.results)
      .sort(([, v1], [, v2]) => v2 - v1)
      .reduce((obj, [k, v]) => ({ ...obj, [k]: v }), {});
  } catch (error) {
    console.error('Error updating bar chart:', error);
  }

  const lb = [];
  const dt = [];
  Object.entries(values.value).forEach(([key, value]) => {
    lb.push(key);
    dt.push(value);
  });
  chartData.value.labels = lb;
  chartData.value.datasets = [{
    label: props.list,
    backgroundColor: bgColor.value,
    data: dt,
  }];
  console.log('Bar chart labels:', lb, 'data:', dt);
  loaded.value = true;
}

watch(() => props.filters, updateChart, { deep: true, immediate: true });
watch(ticer, updateChart);

onMounted(() => {
  updateChart();
});
</script>

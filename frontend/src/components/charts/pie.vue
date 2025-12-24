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
  // Unwrap reactive proxies before passing to API
  const sources = toRaw(props.filters.sources) || [];
  const hostnames = toRaw(props.filters.hostnames) || [];
  const priorities = toRaw(props.filters.priorities) || [];
  const tags = toRaw(props.filters.tags) || [];
  console.log('[PieChart] Unwrapped tags:', tags, 'Type:', Array.isArray(tags), 'Length:', tags.length);
  // Check if we're filtering by the same dimension we're displaying
  const filteringByTags = props.list === 'tags' && tags.length > 0;
  const filteringBySource = props.list === 'source' && sources.length > 0;
  const filteringByPriority = props.list === 'priority' && priorities.length > 0;
  const filteringByHostname = props.list === 'hostname' && hostnames.length > 0;
  const filteringBySameDimension = filteringByTags || filteringBySource || filteringByPriority || filteringByHostname;
  try {
    let results = {};
    if (filteringBySameDimension) {
      // When filtering by the same dimension, we need to get accurate counts
      // The countByEvents API inflates numbers by counting tag occurrences instead of events
      // So we fetch individual counts for each filtered item
      console.log('[PieChart] Filtering by same dimension, fetching accurate counts');
      const filterArray = filteringByTags ? tags :
                         filteringBySource ? sources :
                         filteringByPriority ? priorities : hostnames;
      // Fetch count for each item in the filter
      for (const item of filterArray) {
        // Build the correct filter arrays - include other dimension filters but set only this item for current dimension
        const itemSources = props.list === 'source' ? [item] : [];
        const itemHostnames = props.list === 'hostname' ? [item] : [];
        const itemPriorities = props.list === 'priority' ? [item] : [];
        const itemTags = props.list === 'tags' ? [item] : [];
        console.log(`[PieChart] Fetching count for ${item} with filters:`, {
          sources: itemSources,
          hostnames: itemHostnames,
          priorities: itemPriorities,
          tags: itemTags
        });
        const countResponse = await requests.countEvents(
          itemSources,
          itemHostnames,
          itemPriorities,
          props.filters.rule,
          props.filters.search,
          itemTags,
          props.filters.since,
        );
        const count = countResponse.data.statistics?.all || 0;
        console.log(`[PieChart] Count for ${item}:`, count, 'Response:', countResponse.data);
        results[item] = count;
      }
      console.log('[PieChart] Accurate results:', results);
    } else {
      // Normal case: fetch grouped counts
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
      console.log('[PieChart] Received data:', response.data.results);
      results = response.data.results || {};
    }
    values.value = Object.entries(results)
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

<template>
  <div>
    <v-chip
    dark
    class="rounded-0"
    color="blue lighten-3">Total
    </v-chip>
    <v-chip
    dark
    class="rounded-0"
    style="margin-right: 5px;">{{countByPriority.statistics.all}}
    </v-chip>
    <span
      v-for="(value,key) in countByPriority.results" :key="key">
      <v-chip
      dark
      @click="addItemToList(key)"
      class="rounded-0"
      :color="priorityToColor(key)">
        {{key}}
      </v-chip>
      <v-chip
      dark
      class="rounded-0"
      style="margin-right: 5px;">
        {{value}}
      </v-chip>
    </span>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { useStore } from 'vuex';
import { requests } from '../http';
import { utils } from '../utils';

const props = defineProps({
  filters: {
    type: Object,
    default() {
      return {
        priorities: [],
        rule: '',
        tags: [],
        sources: [],
        hostnames: [],
        search: '',
        since: '',
      };
    },
  },
});

const emit = defineEmits(['add-item-to-filters']);
const store = useStore();

const countByPriority = ref({
  statistics: {
    all: 0,
  },
});

const ticer = computed(() => store.state.ticer);

const priorityToColor = (prio) => {
  return utils.priorityToColor(prio);
};

const updateChart = async () => {
  const response = await requests.countByEvents(
    'priority',
    props.filters.sources,
    props.filters.hostnames,
    props.filters.priorities,
    props.filters.rule,
    props.filters.search,
    props.filters.tags,
    props.filters.since,
  );
  countByPriority.value = response.data;
};

const addItemToList = (item) => {
  emit('add-item-to-filters', item);
};

watch(() => props.filters, () => {
  updateChart();
}, { deep: true });

watch(ticer, () => {
  updateChart();
});

onMounted(() => {
  updateChart();
});
</script>

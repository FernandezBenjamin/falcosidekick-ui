<template>
  <div id="filters">
    <v-row>
      <v-col class="d-flex ml-4" md="2">
        <v-select
          v-model="filters.sources"
          :items="sources"
          label="Sources"
          multiple
          chips
          closable-chips
          clearable
          variant="outlined"
          density="comfortable"
        ></v-select>
      </v-col>
      <v-col class="d-flex ml-2" md="2">
        <v-select
          v-model="filters.priorities"
          :items="priorities"
          label="Priorities"
          multiple
          chips
          closable-chips
          clearable
          variant="outlined"
          density="comfortable"
        ></v-select>
      </v-col>
      <v-col class="d-flex ml-2" md="2">
        <v-select
          v-model="filters.hostnames"
          :items="hostnames"
          label="Hostnames"
          multiple
          chips
          closable-chips
          clearable
          variant="outlined"
          density="comfortable"
        ></v-select>
      </v-col>
      <v-col class="d-flex ml-2" md="2">
        <v-select
          v-model="filters.rule"
          :items="rules"
          label="Rules"
          clearable
          variant="outlined"
          density="comfortable"
        ></v-select>
      </v-col>
      <v-col class="d-flex ml-2" md="2">
        <v-select
          v-model="filters.tags"
          :items="tags"
          label="Tags"
          multiple
          chips
          closable-chips
          clearable
          variant="outlined"
          density="comfortable"
        ></v-select>
      </v-col>
      <v-spacer>
      </v-spacer>
      <v-col class="d-flex ml-2 mr-5" md="2">
        <v-select
          v-model="filters.since"
          :items="since"
          label="Since"
          variant="outlined"
          density="comfortable"
        ></v-select>
      </v-col>
    </v-row>
    <v-row>
      <v-col
      class="d-flex ml-4 pr-10"
      cols="12"
      sm="12">
        <v-text-field
          v-model="filters.search"
          label="Search"
          variant="outlined"
          density="comfortable"
          hide-details
          :append-inner-icon="'mdi-magnify'"
        ></v-text-field>
        <v-card-actions style="padding-top: 20px; padding-bottom: 0px;">
          <v-spacer></v-spacer>
          <v-icon @click="clearSearch" v-show="filters.search">
            mdi-close-circle-outline
          </v-icon>
        </v-card-actions>
        <v-spacer></v-spacer>
        <Counters
          :filters="filters"
          :ticer="ticer"
          @add-item-to-filters="(item) => addItemToFilters('priorities', item)"
        ></Counters>
      </v-col>
    </v-row>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted, toRaw } from 'vue';
import { useStore } from 'vuex';
import { useRouter, useRoute } from 'vue-router';
import { requests } from '../http';
import { utils } from '../utils';
import Counters from '../components/counters.vue';

const router = useRouter();
const route = useRoute();
const store = useStore();

const props = defineProps({
  addItem: { required: false, type: Object },
});

const emit = defineEmits(['send-filters']);

const priorities = ref([]);
const rules = ref([]);
const sources = ref([]);
const hostnames = ref([]);
const tags = ref([]);
const since = ref(['5min', '15min', '30min', '1h', '2h', '5h', '12h', '24h', '48h', '1w', '2w', '1M', '3M', '6M', '1y', '2y']);
const filters = ref({
  priorities: [],
  rule: [],
  hostnames: [],
  tags: [],
  sources: [],
  search: '',
  since: '24h',
});
const debounce = ref(null);

const ticer = computed(() => store.state.ticer);

const listItems = async (list) => {
  try {
    const response = await requests.countByEvents(list, '', '', '', '', '', '', filters.value.since);
    const values = response.data.results;
    switch (list) {
      case 'source':
      case 'sources':
        Object.keys(values).forEach((value) => {
          sources.value.push(value);
        });
        sources.value = [...new Set(sources.value)];
        break;
      case 'hostname':
      case 'hostnames':
        Object.keys(values).forEach((value) => {
          hostnames.value.push(value);
        });
        hostnames.value = [...new Set(hostnames.value)];
        break;
      case 'priority':
      case 'priorities':
        Object.keys(values).forEach((value) => {
          priorities.value.push(value);
        });
        priorities.value = [...new Set(priorities.value)];
        break;
      case 'rule':
        Object.keys(values).forEach((value) => {
          rules.value.push(value);
        });
        rules.value = [...new Set(rules.value)];
        break;
      case 'tags':
        Object.keys(values).forEach((value) => {
          tags.value.push(value);
        });
        tags.value = [...new Set(tags.value)];
        break;
      default:
        break;
    }
  } catch (error) {
    console.error('Error listing items:', error);
  }
};

const priorityToColor = (prio) => {
  return utils.priorityToColor(prio);
};

const stringToColor = (str) => {
  return utils.stringToColor(str);
};

const unselect = (list) => {
  switch (list) {
    case 'priority':
    case 'priorities':
      filters.value.priorities = [];
      break;
    case 'rule':
      filters.value.rule = [];
      break;
    case 'source':
    case 'sources':
      filters.value.sources = [];
      break;
    case 'hostname':
    case 'hostnames':
      filters.value.hostnames = [];
      break;
    case 'tags':
      filters.value.tags = [];
      break;
    default:
      break;
  }
};

const addItemToFilters = (list, item) => {
  switch (list) {
    case 'priority':
    case 'priorities':
      filters.value.priorities.push(item);
      filters.value.priorities = [...new Set(filters.value.priorities)];
      break;
    case 'rule':
      filters.value.rule = item;
      break;
    case 'source':
    case 'sources':
      filters.value.sources.push(item);
      filters.value.sources = [...new Set(filters.value.sources)];
      break;
    case 'hostname':
    case 'hostnames':
      filters.value.hostnames.push(item);
      filters.value.hostnames = [...new Set(filters.value.hostnames)];
      break;
    case 'search':
    case 'filter':
      filters.value.search = item;
      break;
    case 'tags':
      filters.value.tags.push(item);
      filters.value.tags = [...new Set(filters.value.tags)];
      break;
    default:
      break;
  }
};

const clearSearch = () => {
  filters.value.search = '';
};

// Initialize filters from route query
if (typeof route.query.source !== 'undefined') {
  filters.value.sources = route.query.source;
}
if (typeof route.query.hostname !== 'undefined') {
  filters.value.hostnames = route.query.hostname;
}
if (typeof route.query.priority !== 'undefined') {
  filters.value.priorities = route.query.priority;
}
if (typeof route.query.rule !== 'undefined') {
  filters.value.rule = route.query.rule;
}
if (typeof route.query.tags !== 'undefined') {
  filters.value.tags = route.query.tags;
}
if (typeof route.query.filter !== 'undefined') {
  filters.value.search = route.query.filter;
}
if (typeof route.query.since !== 'undefined') {
  filters.value.since = route.query.since;
}

watch(() => props.addItem, () => {
  if (props.addItem) {
    addItemToFilters(props.addItem.list, props.addItem.item);
  }
}, { deep: true });

// Function to emit filter changes
const emitFilters = () => {
  console.log('[Filters] emitFilters called');
  console.log('[Filters] Current filter values:', {
    priorities: filters.value.priorities,
    sources: filters.value.sources,
    hostnames: filters.value.hostnames,
    tags: filters.value.tags,
    rule: filters.value.rule,
    since: filters.value.since,
    search: filters.value.search
  });
  
  // Build new query params - combine all updates into a single router.push
  const newQuery = { ...route.query, since: filters.value.since };
  
  if (filters.value.priorities.length > 0) {
    newQuery.priority = filters.value.priorities;
  } else {
    delete newQuery.priority;
  }
  
  if (filters.value.sources.length > 0) {
    newQuery.source = filters.value.sources;
  } else {
    delete newQuery.source;
  }
  
  if (filters.value.hostnames.length > 0) {
    newQuery.hostname = filters.value.hostnames;
  } else {
    delete newQuery.hostname;
  }
  
  if (filters.value.rule !== '') {
    newQuery.rule = filters.value.rule;
  } else {
    delete newQuery.rule;
  }
  
  if (filters.value.tags.length > 0) {
    newQuery.tags = filters.value.tags;
  } else {
    delete newQuery.tags;
  }
  
  if (filters.value.search !== '') {
    newQuery.filter = filters.value.search;
  } else {
    delete newQuery.filter;
  }
  
  // Update route with all query params at once
  router.push({ query: newQuery });
  
  // Use toRaw to completely unwrap all Vue reactivity, then create plain copies
  const rawFilters = toRaw(filters.value);
  
  // Create completely plain JavaScript object with no reactivity
  const plainFilters = {
    priorities: Array.isArray(rawFilters.priorities) ? Array.from(rawFilters.priorities) : [],
    sources: Array.isArray(rawFilters.sources) ? Array.from(rawFilters.sources) : [],
    hostnames: Array.isArray(rawFilters.hostnames) ? Array.from(rawFilters.hostnames) : [],
    tags: Array.isArray(rawFilters.tags) ? Array.from(rawFilters.tags) : [],
    rule: typeof rawFilters.rule === 'string' ? rawFilters.rule : (Array.isArray(rawFilters.rule) && rawFilters.rule.length > 0 ? rawFilters.rule[0] : ''),
    since: rawFilters.since || '24h',
    search: rawFilters.search || ''
  };
  
  console.log('[Filters] Plain filters created:', plainFilters);
  console.log('[Filters] Priorities type:', typeof plainFilters.priorities, 'Value:', plainFilters.priorities);
  console.log('[Filters] Emitting send-filters event');
  emit('send-filters', plainFilters);
};

// Watch individual filter properties
watch(() => filters.value.priorities, () => {
  console.log('[Filters] Priorities changed:', filters.value.priorities);
  emitFilters();
}, { deep: true });

watch(() => filters.value.sources, () => {
  console.log('[Filters] Sources changed:', filters.value.sources);
  emitFilters();
}, { deep: true });

watch(() => filters.value.hostnames, () => {
  console.log('[Filters] Hostnames changed:', filters.value.hostnames);
  emitFilters();
}, { deep: true });

watch(() => filters.value.tags, () => {
  console.log('[Filters] Tags changed:', filters.value.tags);
  emitFilters();
}, { deep: true });

watch(() => filters.value.rule, () => {
  console.log('[Filters] Rule changed:', filters.value.rule);
  emitFilters();
});

watch(() => filters.value.search, () => {
  console.log('[Filters] Search changed:', filters.value.search);
  emitFilters();
});

watch(() => filters.value.since, (newSince, oldSince) => {
  console.log('[Filters] Since changed from', oldSince, 'to', newSince);
  if (newSince !== oldSince) {
    listItems('source');
    listItems('hostname');
    listItems('priority');
    listItems('rule');
    listItems('tags');
  }
  emitFilters();
});

watch(ticer, () => {
  listItems('priority');
  listItems('rule');
  listItems('hostname');
  listItems('source');
  listItems('tags');
});

onMounted(() => {
  listItems('priority');
  listItems('rule');
  listItems('source');
  listItems('hostname');
  listItems('tags');
});
</script>

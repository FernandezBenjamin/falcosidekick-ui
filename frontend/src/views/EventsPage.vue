<template>
  <v-card class="elevation-0">
    <v-row class="mt-4">
      <v-col
      cols="12"
      sm="12">
        <Filters
        @send-filters="setFilters"
        :addItem="newItem">
        </Filters>
      </v-col>
    </v-row>
    <v-row>
      <v-col
      align="right"
      cols="12"
      sm="12"
      class="pr-7"
      >
        <v-btn
        color="info"
        small
        @click="saveFile()"
        >
          Export
        </v-btn>
      </v-col>
    </v-row>
    <v-row>
      <v-data-table-server
        class="mt-10 ml-5 mr-5"
        :search="search"
        :headers='headers'
        :items='events'
        item-key="time"
        :items-length='totalEvents'
        v-model:page="page"
        v-model:items-per-page="itemsPerPage"
        :items-per-page-options="itemsPerPageInterval"
        :loading='loading'
        @update:page="searchEvents"
        @update:items-per-page="resetPage(); searchEvents()"
      >
        <template v-slot:item.time="{ item }">
          {{ $filters.formatDate(item.time) }}
        </template>
        <template v-slot:item.source="{ item }">
          <v-chip dark
          @click="addToFilters('sources', item.source)"
          :color="stringToColor(item.source)">
          {{ item.source }}
          </v-chip>
        </template>
        <template v-slot:item.hostname="{ item }">
          <v-chip dark v-if="item.hostname"
          @click="addToFilters('hostnames', item.hostname)"
          :color="stringToColor(item.hostname)">
          {{ item.hostname }}
          </v-chip>
        </template>
        <template v-slot:item.priority="{ item }">
          <v-chip
          @click="addToFilters('priorities', item.priority)"
          :color="priorityToColor(item.priority)"
          dark>
            {{ item.priority }}
          </v-chip>
        </template>
        <template v-slot:item.rule="{ item }">
          {{ item.rule }}
        </template>
        <template v-slot:item.output="{ item }">
          <div>{{ item.output }}</div>
          <div>
            <span
            v-for="(value,key) in item.output_fields" :key="key">
            <v-chip small label
            @click="addToFilters('search', key)"
            class="rounded-0 mb-1"
            color="blue lighten-3">
              {{key}}
            </v-chip>
            <v-chip small label
            @click="addToFilters('search', value)"
            class="rounded-0 mb-1"
            style="margin-left: -4px; margin-right: 5px;">
              {{value}}
            </v-chip>
            </span>
          </div>
        </template>
        <template v-slot:item.tags="{ item }">
          <v-chip
          class="mb-1 mr-1 mt-1"
          @click="addToFilters('tags', tag)"
          v-for="(tag, index) in item.tags" :key="index"
          dark small
          :color="stringToColor(tag)">
          {{tag}}
          </v-chip>
        </template>
        <template v-slot:item.json="{ item }">
          <v-btn
            x-small
            :icon="true"
            @click="showDialog(item);"
          >
            <v-icon>mdi-code-json</v-icon>
          </v-btn>
        </template>
      </v-data-table-server>
    </v-row>
    <v-dialog
      v-model="dialog"
      width="auto"
      >
      <v-tabs
      text
      >
        <v-tab href="#details" @click="dialogDetails = true; dialogJson = false;">
          Details
        </v-tab>
        <v-tab href="#json" @click="dialogDetails = false; dialogJson = true;">
          Json
        </v-tab>
      </v-tabs>
      <v-card>
        <v-card-text v-show="dialogDetails">
          <v-list-item style="padding-top: 10px;">
            <v-list-item-content>
              <v-list-item-title>Time</v-list-item-title>
                <v-list-item-subtitle>{{json.time}}</v-list-item-subtitle>
              <v-list-item-title>Source</v-list-item-title>
                <v-list-item-subtitle>
                  <v-chip dark
                  @click="addToFilters('sources', json.source)"
                  :color="stringToColor(String(json.source))">{{ json.source }}</v-chip>
                </v-list-item-subtitle>
              <v-list-item-title>Hostname</v-list-item-title>
                <v-list-item-subtitle>
                  <v-chip dark
                  @click="addToFilters('hostnames', json.hostname)"
                  :color="stringToColor(String(json.hostname))">{{ json.hostname }}</v-chip>
                </v-list-item-subtitle>
              <v-list-item-title>Priority</v-list-item-title>
                <v-list-item-subtitle>
                  <v-chip dark
                  @click="addToFilters('priorities', json.priority)"
                  :color="priorityToColor(String(json.priority))">{{ json.priority }}</v-chip>
                </v-list-item-subtitle>
              <v-list-item-title>Rule</v-list-item-title>
              <v-list-item-subtitle>{{json.rule}}</v-list-item-subtitle>
              <v-list-item-title>Output</v-list-item-title>
              <v-list-item-subtitle>
                <pre style="white-space: pre-wrap;">{{json.output}}</pre>
              </v-list-item-subtitle>
              <v-list-item-title>Fields</v-list-item-title>
              <v-list-item-subtitle>
                <v-list-item-subtitle>
                  <span style="white-space: pre-wrap;"
                  v-for="(value,key) in json.output_fields" :key="key" :value="value">
                  <v-chip label
                  @click="addToFilters('search', key)"
                  class="rounded-0 mb-1"
                  color="blue lighten-3">
                    {{key}}
                  </v-chip>
                  <v-chip label
                  @click="addToFilters('search', value)"
                  class="rounded-0 mb-1"
                  style="margin-left: -4px; margin-right: 5px;">
                    {{value}}
                  </v-chip>
                  </span>
                </v-list-item-subtitle>
              </v-list-item-subtitle>
              <v-list-item-title>Tags</v-list-item-title>
              <v-list-item-subtitle>
                <v-list-item-subtitle>
                  <v-chip
                  v-for="(tag, index) in json.tags" :key="index"
                  dark
                  @click="addToFilters('tags', tag)"
                  class="mb-1 mr-1 mt-1"
                  :color="stringToColor(String(tag))">{{ tag }}</v-chip>
                </v-list-item-subtitle>
              </v-list-item-subtitle>
            </v-list-item-content>
          </v-list-item>
        </v-card-text>
        <v-card-text v-show="dialogJson">
          <pre style="white-space: pre-wrap;">
            <vue-json-pretty
              :data="json"
              :collapsedOnClickBrackets="false"
            />
          </pre>
        </v-card-text>
        <v-card-actions class="justify-center">
          <v-btn
            style="margin-right: 5px;"
            color="primary" large @click="dialog = false"
          >
            Close
          </v-btn>
          <v-tooltip
          v-model="copied"
          top
          >
            <template v-slot:activator="{ attrs }">
              <v-btn
                color="normal"
                large
                @click="copied = true; copyToClipBoard()"
                v-bind="attrs"
              >
              COPY JSON
              </v-btn>
            </template>
            <span>Copied</span>
          </v-tooltip>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </v-card>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useRouter, useRoute } from 'vue-router';
import 'vue-json-pretty/lib/styles.css';
import VueJsonPretty from 'vue-json-pretty';
import { requests } from '../http';
import { utils } from '../utils';
import Filters from '../components/filters.vue';

const router = useRouter();
const route = useRoute();
const store = useStore();

const search = ref('');
const page = ref(1);
const itemsPerPage = ref(10);
const itemsPerPageInterval = [10, 50, 100, 200, 500, 1000];
const totalEvents = ref(0);
const events = ref([]);
const filters = ref({
  sources: [],
  hostnames: [],
  priorities: [],
  rule: '',
  tags: [],
  since: '24h',
  search: '',
});
const newItem = ref({
  list: '',
  item: '',
});
const loading = ref(true);
const headers = ref([
  { title: 'Timestamp', key: 'time' },
  { title: 'Source', key: 'source' },
  { title: 'Hostname', key: 'hostname' },
  { title: 'Priority', key: 'priority' },
  { title: 'Rule', key: 'rule' },
  { title: 'Output', key: 'output' },
  { title: 'Tags', key: 'tags' },
  { title: '', key: 'json' },
]);
const debounce = ref(null);
const dialog = ref(false);
const dialogDetails = ref(true);
const dialogJson = ref(false);
const json = ref('');
const copied = ref(false);

const ticer = computed(() => store.state.ticer);

const resetPage = () => {
  page.value = 1;
};

const searchEvents = async () => {
  loading.value = true;
  const currentPage = page.value;
  const currentItemsPerPage = itemsPerPage.value;
  router.push({ query: { ...route.query, page: currentPage, limit: currentItemsPerPage } });
  if (route.query.filter !== search.value && search.value !== '') {
    router.push({ query: { ...route.query, filter: search.value } });
  }
  try {
    const response = await requests.searchEvents(
      filters.value.sources,
      filters.value.hostnames,
      filters.value.priorities,
      filters.value.rule,
      filters.value.search,
      filters.value.tags,
      filters.value.since,
      currentPage,
      currentItemsPerPage,
    );
    loading.value = false;
    // Normalize API results to an array for the data table
    const res = response.data.results;
    events.value = Array.isArray(res) ? res : Object.values(res || {});
    totalEvents.value = response.data.statistics.all;
  } catch (error) {
    loading.value = false;
    console.error('Error searching events:', error);
  }
};

const priorityToColor = (prio) => {
  return utils.priorityToColor(prio);
};

const stringToColor = (str) => {
  return utils.stringToColor(str);
};

const setFilters = (f) => {
  filters.value = f;
};

const addToFilters = (l, i) => {
  newItem.value = {
    list: l,
    item: i,
  };
};

const showDialog = (i) => {
  dialog.value = true;
  json.value = i;
};

const copyToClipBoard = () => {
  navigator.clipboard.writeText(JSON.stringify(json.value));
};

const saveFile = async () => {
  try {
    const response = await requests.searchEvents(
      filters.value.sources,
      filters.value.hostnames,
      filters.value.priorities,
      filters.value.rule,
      filters.value.search,
      filters.value.tags,
      filters.value.since,
      0,
      10000,
    );
    const text = JSON.stringify(response.data.results);
    const filename = 'falco_events.json';
    const element = document.createElement('a');
    const href = `data:application/json;charset=utf-8,${encodeURIComponent(text)}`;
    element.setAttribute('href', href);
    element.setAttribute('download', filename);
    element.style.display = 'none';
    document.body.appendChild(element);
    element.click();
    document.body.removeChild(element);
  } catch (error) {
    console.error('Error saving file:', error);
  }
};

watch(page, () => {
  searchEvents();
});

watch(itemsPerPage, () => {
  resetPage();
  searchEvents();
});

watch(() => filters.value, () => {
  resetPage();
  searchEvents();
}, { deep: true });

watch(() => search.value, () => {
  clearTimeout(debounce.value);
  debounce.value = setTimeout(() => {
    resetPage();
    searchEvents();
  }, 600);
});

watch(ticer, () => {
  if (page.value === 1) {
    searchEvents();
  }
});

onMounted(() => {
  searchEvents();
});
</script>

<style>
.vjs-key {
  color: rgb(43, 51, 42);
}
.vjs-value-string {
  color: rgb(73, 105, 247);
}
.v-list-item__subtitle {
  padding-bottom: 15px;
  font-size: 125%;
}
.v-list-item__title {
  padding-bottom: 2px;
}
</style>

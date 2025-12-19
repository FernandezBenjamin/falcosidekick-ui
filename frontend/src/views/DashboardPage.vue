<template>
  <v-card class="elevation-0">
    <v-row>
      <v-col
      cols="12"
      sm="12">
        <Filters
        @send-filters="setFilters"
        :addItem="newItem"
        >
        </Filters>
      </v-col>
    </v-row>
    <v-row>
      <v-col
      cols="12"
      sm="4">
        <v-card class="elevation-0">
          <v-card-title>Sources</v-card-title>
          <PieChart
          id="countBySource"
          list="source"
          :filters="filters"
          :filterKey="filterKey"
          @picked-item="addToFilters">
          </PieChart>
          </v-card>
      </v-col>
      <v-col
      cols="12"
      sm="4">
        <v-card class="elevation-0">
          <v-card-title>Priorities</v-card-title>
          <PieChart
          id="countByPriority"
          list="priority"
          :filters="filters"
          :filterKey="filterKey"
          @picked-item="addToFilters">
          </PieChart>
          </v-card>
      </v-col>
      <v-col
      cols="12"
      sm="4">
        <v-card class="elevation-0">
          <v-card-title>Tags</v-card-title>
          <PieChart
          id="countByTag"
          list="tags"
          :filters="filters"
          :filterKey="filterKey"
          @picked-item="addToFilters">
          </PieChart>
          </v-card>
      </v-col>
    </v-row>
    <v-row>
      <v-col
      cols="12"
      sm="11">
        <v-card class="elevation-0">
          <v-card-title>Rules</v-card-title>
            <BarChart
            id="countByRules"
            list="rule"
            :filters="filters"
            :filterKey="filterKey"
            @picked-item="addToFilters">
            </BarChart>
        </v-card>
      </v-col>
    </v-row>
    <v-row>
      <v-col
      cols="12"
      sm="12">
        <v-card class="elevation-0">
          <v-card-title>Timeline by Priority</v-card-title>
            <TimelineChart
            id="timeline-priority"
            :filters="filters"
            :filterKey="filterKey"
            groupby="priority"
            @picked-item="addToFilters">
            </TimelineChart>
        </v-card>
      </v-col>
    </v-row>
    <v-row>
      <v-col
      cols="12"
      sm="12">
        <v-card class="elevation-0">
          <v-card-title>Timeline by Source</v-card-title>
            <TimelineChart
            id="timeline-source"
            :filters="filters"
            :filterKey="filterKey"
            groupby="source"
            @picked-item="addToFilters">
            </TimelineChart>
        </v-card>
      </v-col>
    </v-row>
  </v-card>
</template>

<script setup>
import { ref } from 'vue';
import BarChart from '../components/charts/bar.vue';
import PieChart from '../components/charts/pie.vue';
import TimelineChart from '../components/charts/timeline.vue';
import Filters from '../components/filters.vue';

const newItem = ref({
  list: '',
  item: '',
});

const filters = ref({
  priorities: [],
  sources: [],
  hostnames: [],
  tags: [],
  rule: '',
  since: '24h',
  search: '',
});

const filterKey = ref(0);

const setFilters = (f) => {
  console.log('[DashboardPage] setFilters called with:', f);
  console.log('[DashboardPage] f.priorities:', f.priorities);
  console.log('[DashboardPage] f.sources:', f.sources);
  console.log('[DashboardPage] f.since:', f.since);
  // Mutate properties individually to trigger Vue reactivity properly
  filters.value.priorities = f.priorities;
  filters.value.sources = f.sources;
  filters.value.hostnames = f.hostnames;
  filters.value.tags = f.tags;
  filters.value.rule = f.rule;
  filters.value.since = f.since;
  filters.value.search = f.search;
  
  // Increment key to force child components to detect the change
  filterKey.value++;
  console.log('[DashboardPage] filterKey incremented to:', filterKey.value);
};

const addToFilters = (l, i) => {
  newItem.value = {
    list: l,
    item: i,
  };
};
</script>


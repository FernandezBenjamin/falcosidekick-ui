<template>
  <v-app>
    <v-app-bar color="blue-darken-2" theme="dark">
      <v-img
        src="https://github.com/falcosecurity/falcosidekick/raw/master/imgs/falcosidekick_color.png"
        max-height="40"
        max-width="40"
        class="ml-4 mr-3">
      </v-img>
      <v-toolbar-title>
        Falcosidekick UI
      </v-toolbar-title>
      <template v-slot:extension>
        <v-tabs color="white">
          <v-tab v-for="(page) in pages" :key="page.title"
          :to="{ path: page.href, query: $route.query }">
            {{ page.title }}
          </v-tab>
        </v-tabs>
        <span class="ml-4">refresh</span>
        <v-select
          class="ml-2"
          style="max-width: 80px;"
          v-model="refresh"
          :items="refreshIntervals"
          density="compact"
          variant="outlined"
          hide-details
        ></v-select>
      </template>
      <v-spacer/>
      <Counters v-if="$store.state.username && $store.state.password"></Counters>
    </v-app-bar>
    <v-main>
      <router-view></router-view>
    </v-main>
    <v-footer color="blue-darken-2" theme="dark" app>
      <span>
        2025 - <a href="https://github.com/falcosecurity/falcosidekick-ui" class="text-white">Falco Authors</a>
      </span>
      <v-spacer/>
      <span v-if="$store.state.username && $store.state.password">
        logged as <b>{{ $store.state.username }}</b>
        <v-btn variant="text" size="small" class="ml-3" @click="logout">
          Logout
        </v-btn>
      </span>
    </v-footer>
  </v-app>
</template>

<script setup>
import { ref, computed, watch, onBeforeUnmount } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { useStore } from 'vuex';
import Counters from './components/counters.vue';

const router = useRouter();
const route = useRoute();
const store = useStore();

const pages = ref([
  {
    href: '/dashboard',
    router: true,
    title: 'Dashboard',
  },
  {
    href: '/events',
    router: true,
    title: 'Events',
  },
  {
    href: '/info',
    router: true,
    title: 'Info',
  },
]);

const timer = ref('');
const refresh = ref('10s');

const refreshInterval = computed(() => store.state.refreshInterval);
const refreshIntervals = computed(() => store.state.refreshIntervals);

const logout = () => {
  store.state.username = '';
  store.state.password = '';
  router.push('/login');
};

const cancelAutoUpdate = () => {
  clearInterval(timer.value);
};

const setTimer = () => {
  clearInterval(timer.value);
  timer.value = setInterval(() => {
    if (refreshInterval.value !== 0) {
      store.commit('increment');
    }
  }, store.state.refreshInterval);
};

watch(refresh, () => {
  store.commit('setRefreshInterval', refresh.value);
  setTimer();
  if (route.query.refresh !== refresh.value || route.query.refresh === '') {
    router.push({ query: { ...route.query, refresh: refresh.value } });
  }
});

// Initialize on component mount
if (typeof route.query.refresh !== 'undefined') {
  refresh.value = route.query.refresh;
  store.commit('setRefreshInterval', refresh.value);
}
setTimer();

onBeforeUnmount(() => {
  cancelAutoUpdate();
});
</script>

<style scoped>
a:link {
  text-decoration: none;
  color: white;
}
a:visited {
  text-decoration: none;
  color: white;
}
a:hover {
  text-decoration: underline;
}
</style>

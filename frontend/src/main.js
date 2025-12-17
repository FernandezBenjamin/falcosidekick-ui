// SPDX-License-Identifier: Apache-2.0
/*
Copyright (C) 2025 The Falco Authors.
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

import { createApp } from 'vue';
import { createVuetify } from 'vuetify';
import * as components from 'vuetify/components';
import * as directives from 'vuetify/directives';
import moment from 'moment';
import 'vuetify/styles';
import '@mdi/font/css/materialdesignicons.css';
import App from './App.vue';
import router from './router';
import store from './store';

// Create Vuetify instance with all components
const vuetify = createVuetify({
  components,
  directives,
  theme: {
    defaultTheme: 'light',
  },
});

// Create Vue app
const app = createApp(App);

// Global filters are removed in Vue 3, convert to global properties
app.config.globalProperties.$filters = {
  formatDate(value) {
    if (!value) return '';
    return moment(String(value)).format('YYYY/MM/DD HH:mm:ss:SSS');
  },
  capitalize(value) {
    if (!value) return '';
    return value.charAt(0).toUpperCase() + value.slice(1);
  },
};

// Use plugins
app.use(vuetify);
app.use(router);
app.use(store);

// Mount app
app.mount('#app');

<template>
  <v-card class="elevation-0">
    <v-row class="mt-4">
      <v-col
      class="ml-5 mt-5"
      cols="3"
      sm="3">
        <v-card class="elevation-0">
          <v-card-title>Outputs</v-card-title>
            <span
            v-for="(value) in outputs" :key="value"
            style="margin-left: 15px;">
            <v-chip
            dark
            color="#1976d2"
            class="rounded-0">
              {{value}}
            </v-chip>
          </span>
        </v-card>
        <v-card class="elevation-0">
          <v-card-title>Configuration</v-card-title>
            <v-simple-table dense>
              <template v-slot:default>
                <tbody>
                  <tr
                    v-for="(value,key) in configuration" :key="key">
                    <td>{{ key }}</td>
                    <td>{{ value }}</td>
                  </tr>
                </tbody>
              </template>
            </v-simple-table>
        </v-card>
        <v-card class="elevation-0">
          <v-card-title>Version</v-card-title>
            <v-simple-table dense>
              <template v-slot:default>
                <tbody>
                  <tr
                    v-for="(value,key) in version" :key="key">
                    <td>{{ key }}</td>
                    <td>{{ value }}</td>
                  </tr>
                </tbody>
              </template>
            </v-simple-table>
        </v-card>
        <v-card class="elevation-0">
          <v-card-title>
            API<br>
            <v-btn
            href="docs"
            elevation="0"
            class="ml-2"
            color="#1976d2"
            dark icon>
            <v-icon>mdi-link</v-icon>
            </v-btn>
          </v-card-title>
        </v-card>
      </v-col>
    </v-row>
  </v-card>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { useStore } from 'vuex';
import { requests } from '../http';

const store = useStore();

const outputs = ref([]);
const version = ref({});
const configuration = ref({});

const ticer = computed(() => store.state.ticer);

const listOutputs = async () => {
  try {
    const response = await requests.listOutputs();
    outputs.value = response.data;
  } catch (error) {
    console.error('Error listing outputs:', error);
  }
};

const getConfiguration = async () => {
  try {
    const response = await requests.getConfiguration();
    configuration.value = response.data;
  } catch (error) {
    console.error('Error getting configuration:', error);
  }
};

const getVersion = async () => {
  try {
    const response = await requests.getVersion();
    version.value = response.data;
  } catch (error) {
    console.error('Error getting version:', error);
  }
};

watch(ticer, () => {
  listOutputs();
});

onMounted(() => {
  listOutputs();
  getConfiguration();
  getVersion();
});
</script>


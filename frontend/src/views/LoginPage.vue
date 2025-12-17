<template>
  <v-container fluid class="fill-height">
    <v-row align="center" justify="center">
      <v-col cols="12" sm="8" md="4">
        <v-card elevation="4">
          <v-card-text>
            <v-form ref="form">
              <v-text-field
                label="Login"
                v-model="username"
                required
                variant="outlined"
              ></v-text-field>
              <v-text-field
                label="Password"
                v-model="password"
                required
                type="password"
                variant="outlined"
              ></v-text-field>
            </v-form>
            <v-row justify="space-between">
              <v-btn @click="authenticate" color="blue-darken-2" variant="flat" block>Login</v-btn>
            </v-row>
            <v-alert 
              v-if="failedAuth === true"
              class="mt-5"
              type="error"
              variant="outlined"
              density="compact"
            >{{ failMsg }}</v-alert>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>
  </v-container>
</template>

<script setup>
import { ref } from 'vue';
import { useStore } from 'vuex';
import { requests } from '../http';
import { useRouter } from 'vue-router';

const router = useRouter();
const store = useStore();

const username = ref('');
const password = ref('');
const failedAuth = ref(false);
const failMsg = ref('');

const authenticate = async () => {
  failedAuth.value = false;
  failMsg.value = '';

  if (username.value === '' || password.value === '') {
    failedAuth.value = true;
    failMsg.value = "login and password can't be empty";
    return;
  }

  try {
    const response = await requests.authenticate(username.value, password.value);
    if (response.status === 200) {
      const payload = {
        username: username.value,
        password: password.value,
      };
      store.commit('setCredentials', payload);
      router.push('/dashboard');
    }
  } catch (error) {
    failedAuth.value = true;
    failMsg.value = error;
  }
};

// Auto-login disabled - user must login manually
</script>


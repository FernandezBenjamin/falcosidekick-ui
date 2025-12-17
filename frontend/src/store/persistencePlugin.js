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

/**
 * Custom persistence plugin for Vuex 4
 * Replaces deprecated vuex-persistedstate dependency
 * Persists store state to sessionStorage
 */
export const createPersistencePlugin = (storageKey = 'vuex') => {
  return (store) => {
    // Load persisted state from sessionStorage on initialization
    const loadPersistedState = () => {
      try {
        const savedState = window.sessionStorage.getItem(storageKey);
        if (savedState) {
          const parsedState = JSON.parse(savedState);
          store.replaceState(Object.assign(store.state, parsedState));
        }
      } catch (error) {
        console.error(`Failed to load persisted state from ${storageKey}:`, error);
      }
    };

    // Save state to sessionStorage on every mutation
    const persistState = (mutation, state) => {
      try {
        window.sessionStorage.setItem(storageKey, JSON.stringify(state));
      } catch (error) {
        console.error(`Failed to persist state to ${storageKey}:`, error);
      }
    };

    // Initialize
    loadPersistedState();

    // Subscribe to mutations
    store.subscribe(persistState);
  };
};

export default createPersistencePlugin;

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

// Simple hash function for browser (replaces Node.js crypto)
function simpleHash(str) {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash; // Convert to 32bit integer
  }
  // Convert to positive hex and pad to 6 characters
  return Math.abs(hash).toString(16).padStart(6, '0').substring(0, 6);
}

export const utils = {
  priorityToColor(priority) {
    switch (priority) {
      case 'Emergency':
        return '#C62828';
      case 'Alert':
        return '#D32F2F';
      case 'Critical':
        return '#E53935';
      case 'Error':
        return '#FF5252';
      case 'Warning':
        return '#FB8C00';
      case 'Notice':
        return '#1976D2';
      case 'Informational':
        return '#03A9F4';
      case 'Debug':
        return '#29B6F6';
      default:
        return '#555';
    }
  },
  stringToColor(str) {
    return `#${simpleHash(str)}`;
  },
};

export default {
};

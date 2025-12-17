# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2025 The Falco Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
# the License. You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
# specific language governing permissions and limitations under the License.
#

# Ensure Make is run with bash shell as some syntax below is bash-specific
SHELL=/bin/bash -o pipefail

.DEFAULT_GOAL:=help

GOPATH  := $(shell go env GOPATH)
GOARCH  := $(shell go env GOARCH)
GOOS    := $(shell go env GOOS)
GOPROXY := $(shell go env GOPROXY)
ifeq ($(GOPROXY),)
GOPROXY := https://proxy.golang.org
endif
export GOPROXY
GO ?= go
DOCKER ?= docker
TEST_FLAGS ?= -v -race

# Directories.
TOOLS_DIR := tools
TOOLS_BIN_DIR := $(abspath $(TOOLS_DIR)/bin)
GO_INSTALL = tools/go_install.sh

# Binaries.
GOLANGCI_LINT_VER := v2.7.2
GOLANGCI_LINT_BIN := golangci-lint
GOLANGCI_LINT := $(TOOLS_BIN_DIR)/$(GOLANGCI_LINT_BIN)-$(GOLANGCI_LINT_VER)

SWAG_VER := v1.16.6
SWAG_BIN := swag
SWAG := $(TOOLS_BIN_DIR)/$(SWAG_BIN)-$(SWAG_VER)

GIT_HASH ?= $(shell git rev-parse HEAD)
GIT_SHORT ?= $(shell git rev-parse --short HEAD)
GIT_TAG := $(shell git describe --tags --exact-match 2>/dev/null)
GIT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
# Allow overriding the displayed version via BUILD_VERSION, otherwise:
# - If on a tag, use the tag
# - Else use branch-shortsha, and append -dirty when there are local changes
GIT_VERSION ?= $(if $(BUILD_VERSION),$(BUILD_VERSION),$(if $(GIT_TAG),$(GIT_TAG),$(GIT_BRANCH)-$(GIT_SHORT)$(if $(DIFF),-dirty)))
DATE_FMT = +'%Y-%m-%dT%H:%M:%SZ'
# Prefer current UTC time for BuildDate unless USE_SOURCE_DATE_EPOCH=1 is set
USE_SOURCE_DATE_EPOCH ?= 0
ifeq ($(USE_SOURCE_DATE_EPOCH),1)
	SOURCE_DATE_EPOCH := $(shell git log -1 --pretty=%ct)
	BUILD_DATE ?= $(shell date -u -d "@$(SOURCE_DATE_EPOCH)" "$(DATE_FMT)" 2>/dev/null || date -u -r "$(SOURCE_DATE_EPOCH)" "$(DATE_FMT)" 2>/dev/null || date -u "$(DATE_FMT)")
else
	BUILD_DATE ?= $(shell date -u "$(DATE_FMT)")
endif
GIT_TREESTATE = "clean"
DIFF = $(shell git diff --quiet >/dev/null 2>&1; if [ $$? -eq 1 ]; then echo "1"; fi)
ifeq ($(DIFF), 1)
    GIT_TREESTATE = "dirty"
endif

PKG = github.com/falcosecurity/falcosidekick-ui/configuration
LDFLAGS=-X $(PKG).GitVersion=$(GIT_VERSION) -X $(PKG).GitCommit=$(GIT_HASH) -X $(PKG).GitTreeState=$(GIT_TREESTATE) -X $(PKG).BuildDate=$(BUILD_DATE)

## --------------------------------------
## Dev
## --------------------------------------

.PHONY: server
server:
	cd ./frontend && yarn serve

## --------------------------------------
## Docs
## --------------------------------------

.PHONY: docs
docs: $(SWAG)
	$(SWAG) fmt
	$(SWAG) init

## --------------------------------------
## Build
## --------------------------------------

.PHONY: frontend
frontend:
	cd frontend \
	&& yarn install \
	&& yarn build

.PHONY: falcosidekick-ui
falcosidekick-ui: frontend
	$(GO) mod download
	$(GO) build -trimpath -ldflags "$(LDFLAGS)" -o falcosidekick-ui .

.PHONY: falcosidekick-ui-linux-amd64
falcosidekick-ui-linux-amd64: frontend
	$(GO) mod download
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 $(GO) build -gcflags all=-trimpath=/src -asmflags all=-trimpath=/src -a -installsuffix cgo -ldflags "$(LDFLAGS) -extldflags '-static'" -o falcosidekick-ui .

.PHONY: falcosidekick-ui-backend-only
falcosidekick-ui-backend-only:
	$(GO) mod download
	$(GO) build -trimpath -ldflags "$(LDFLAGS)" -o falcosidekick-ui .

.PHONY: falcosidekick-ui-linux-amd64-backend-only
falcosidekick-ui-linux-amd64-backend-only:
	$(GO) mod download
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 $(GO) build -gcflags all=-trimpath=/src -asmflags all=-trimpath=/src -a -installsuffix cgo -ldflags "$(LDFLAGS) -extldflags '-static'" -o falcosidekick-ui .

.PHONY: build-image
build-image:
	$(DOCKER) build -t falcosecurity/falcosidekick-ui:latest . --no-cache

## --------------------------------------
## Test
## --------------------------------------

.PHONY: test
test:
	$(GO) vet ./...
	$(GO) test ${TEST_FLAGS} ./...

.PHONY: test-coverage
test-coverage:
	$(GO) test ./outputs -count=1 -cover -v ./...

## --------------------------------------
## Linting
## --------------------------------------

.PHONY: lint
lint: $(GOLANGCI_LINT) ## Lint codebase
	$(GOLANGCI_LINT) run -v

lint-full: $(GOLANGCI_LINT) ## Run slower linters to detect possible issues
	$(GOLANGCI_LINT) run -v --fast=false

## --------------------------------------
## Release
## --------------------------------------

.PHONY: goreleaser
goreleaser: ## Release using goreleaser
	LDFLAGS="$(LDFLAGS)" goreleaser release --clean

.PHONY: goreleaser-snapshot
goreleaser-snapshot: ## Release snapshot using goreleaser
	LDFLAGS="$(LDFLAGS)" goreleaser --snapshot --skip=sign --clean

## --------------------------------------
## Tooling Binaries
## --------------------------------------

$(GOLANGCI_LINT): ## Install golangci-lint prebuilt binary
	@mkdir -p $(TOOLS_BIN_DIR)
	bash tools/install_golangci.sh $(GOLANGCI_LINT_VER) $(TOOLS_BIN_DIR)

$(SWAG): ## Install swag from source
	@mkdir -p $(TOOLS_BIN_DIR)
	GOBIN=$(TOOLS_BIN_DIR) $(GO) install github.com/swaggo/swag/cmd/swag@$(SWAG_VER)
	@mv $(TOOLS_BIN_DIR)/$(SWAG_BIN) $(TOOLS_BIN_DIR)/$(SWAG_BIN)-$(SWAG_VER)
	@ln -sf $(SWAG_BIN)-$(SWAG_VER) $(TOOLS_BIN_DIR)/$(SWAG_BIN)

## --------------------------------------
## Cleanup / Verification
## --------------------------------------

.PHONY: clean
clean:
	rm -rf hack/tools/bin
	rm -rf dist
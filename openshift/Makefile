RELEASE_TAG  ?= $(shell grep FROM Dockerfile.openshift |grep -v ' AS builder' |sed -e 's;.*/;v;' -e 's;:.*;;')
OCP_REGISTRY ?= registry.redhat.io/openshift4
IMAGE_NAME   ?= ose-cluster-kube-cluster-api-rhel9-operator

BIN_DIR := bin
TOOLS_DIR := tools

KUSTOMIZE := tools/bin/kustomize
ROOT:=$(shell dirname $(realpath ../$(firstword $(MAKEFILE_LIST))))
YQ := $(ROOT)/hack/tools/bin/yq
HELM := $(ROOT)/hack/tools/bin/helm
MAKE := make

$(KUSTOMIZE):
	./tools/ensure-kustomize.sh

.PHONY: ocp-manifests
ocp-manifests: $(KUSTOMIZE) ## Builds openshift specific manifests
	$(KUSTOMIZE) build ../config/default > operator-components.yaml

HELM_CHART_TAG := $(shell echo $(RELEASE_TAG) | cut -c 2-)
RELEASE_DIR := $(ROOT)/out
CHART_DIR := $(RELEASE_DIR)/charts/cluster-api-operator
CHART_PACKAGE_DIR := $(RELEASE_DIR)/package
CHART_VALUES_FILE := $(CHART_DIR)/values.yaml
CHART_TEMPLATE_FILE := $(CHART_DIR)/templates/deployment.yaml
OC_CHART_DIR := $(ROOT)/openshift/charts/cluster-api-operator
OC_CHART_YAML := $(OC_CHART_DIR)/Chart.yaml

.PHONY: release-chart
release-chart:
	$(MAKE) -C .. release-chart RELEASE_TAG=$(RELEASE_TAG)
	$(MAKE) -C .. set-manifest-image-chart \
		MANIFEST_IMG=$(OCP_REGISTRY)/$(IMAGE_NAME) MANIFEST_TAG=$(RELEASE_TAG) \
	        TARGET_RESOURCE="$(CHART_VALUES_FILE)"
	$(MAKE) -C .. set-manifest-pull-policy-chart \
	        PULL_POLICY=IfNotPresent \
	        TARGET_RESOURCE="$(CHART_VALUES_FILE)"
	sed -i -e 's;^\([[:space:]]*-[[:space:]]*\)/manager;\1/bin/cluster-api-operator;' $(CHART_TEMPLATE_FILE)
	mkdir -p $(OC_CHART_DIR)
	tar cf - -C $(CHART_DIR) --exclude templates/\* ./ | tar xf - -C $(OC_CHART_DIR)
	tar cf - -C $(CHART_DIR) templates/deployment.yaml templates/operator-components.yaml templates/_helpers.tpl  | tar xf - -C $(OC_CHART_DIR)
	$(YQ) eval '.version      = $(HELM_CHART_TAG)' $(OC_CHART_YAML) -i
	$(YQ) eval '.appVersion = "$(HELM_CHART_TAG)"' $(OC_CHART_YAML) -i

.PHONY: release-chart-package
ifeq (,$(wildcard $(OC_CHART_YAML)))
release-chart-package: release-chart
else
release-chart-package: $(OC_CHART_YAML)
endif
	$(HELM) package $(OC_CHART_DIR) --destination=$(CHART_PACKAGE_DIR)

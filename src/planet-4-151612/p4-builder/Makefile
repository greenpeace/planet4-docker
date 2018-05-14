SHELL := /bin/bash

################################################################################
MAINTAINER        ?= Raymond Walker <raymond.walker@greenpeace.org>

# https://github.com/greenpeace/planet4-docker
INFRA_VERSION     ?= v0.8.2

# Use current folder name as prefix for built containers,
# eg planet4-gpi-app planet4-gpi-openresty
CONTAINER_PREFIX  ?= planet4-test

################################################################################

# Configure composer source and merge repository data

# Base composer project repository
# FIXME change this to greenpeace/planet4-base once things are settled
GIT_SOURCE        ?= https://github.com/greenpeace/planet4-base-fork

# The branch to checkout of GIT_SOURCE, eg:
# Use local branch name if not set
GIT_REF           ?= develop

# Merge composer project directory (NRO)
MERGE_SOURCE      ?= $(CIRCLE_REPOSITORY_URL)

# The branch to checkout of MERGE_SOURCE, eg:
# Use CIRCLE_TAG > CIRLCE_BRANCH >
MERGE_REF         ?= $(CIRCLE_TAG)

# If the current commit does not have a tag, use the branch
ifeq ($(strip $(MERGE_REF)),)
# Default to git tag on current commit
MERGE_REF         := $(CIRCLE_BRANCH)
endif

# No tag or branch? ...  hope for the best
ifeq ($(strip $(MERGE_REF)),)
MERGE_REF         := $(shell git rev-parse --abbrev-ref HEAD)
endif

################################################################################

# Tag to use on built containers

# Stips away unwanted characters from current branch or tag
BUILD_TAG          := $(shell echo $(MERGE_REF) | tr -c '[[:alnum:]]._-' '-' | sed 's/-$$//')

################################################################################
#
# Helm deploy configuration
#
# Default and derived values

APP_HOSTNAME        ?= greenpeace.org
APP_HOSTPATH        ?= test
APP_ENVIRONMENT     ?= production
BUILD_NAMESPACE     ?= gcr.io
GOOGLE_PROJECT_ID   ?= planet-4-151612
NEWRELIC_APPNAME    ?= Greenpeace Planet4 Wordpress Test
OPENRESTY_IMAGE     ?= $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/$(CONTAINER_PREFIX)-openresty
PHP_IMAGE           ?= $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/$(CONTAINER_PREFIX)-app

WP_STATELESS_BUCKET ?= $(CONTAINER_PREFIX)-stateless-$(HELM_NAMESPACE)
WP_STATELESS_OWNER  ?= cloudstorage@planet-4-151612.iam.gserviceaccount.com

HELM_NAMESPACE      ?= $(APP_HOSTPATH)
HELM_RELEASE        ?= $(CONTAINER_PREFIX)

CLOUDSQL_INSTANCE   ?= p4-develop-k8s

GCLOUD_CLUSTER      ?= p4-development
GCLOUD_REGION       ?= us-central1
GCLOUD_ZONE         ?= us-central1-a

# Secrets
# Values are expected to be stored in Circle build environment

NEWRELIC_LICENSE    := $(NEWRELIC_LICENSE)
SQLPROXY_KEY        := $(SQLPROXY_KEY)
WP_AUTH_KEY         := $(WP_AUTH_KEY)
WP_AUTH_SALT        := $(WP_AUTH_SALT)
WP_DB_USERNAME      ?= $(CONTAINER_PREFIX)
WP_DB_NAME          ?= $(WP_DB_USERNAME)_wordpress
WP_DB_PASSWORD      := $(WP_DB_PASSWORD)
WP_LOGGED_IN_KEY    := $(WP_LOGGED_IN_KEY)
WP_LOGGED_IN_SALT   := $(WP_LOGGED_IN_SALT)
WP_NONCE_KEY        := $(WP_NONCE_KEY)
WP_NONCE_SALT       := $(WP_NONCE_SALT)
WP_SECURE_AUTH_KEY  := $(WP_SECURE_AUTH_KEY)
WP_SECURE_AUTH_SALT := $(WP_SECURE_AUTH_SALT)
WP_STATELESS_KEY    := $(WP_STATELESS_KEY)

################################################################################
#
# Google Cloud Storage Bucket configuration
# Stores built artifacts
#
# GCS bucket to store built source
SOURCE_BUCKET       := $(CONTAINER_PREFIX)-source
SOURCE_BUCKET_PATH  ?= $(BUILD_TAG)

################################################################################


.PHONY: clean test rewrite checkout bake build build-app build-openresty pull push save

all: clean test rewrite checkout bake build push save

dev: clean rewrite checkout bake build

test:
  set -eu
  @echo "Building $(CONTAINER_PREFIX) containers..."
    @echo "APP_HOSTNAME:      $(APP_HOSTNAME)"
    @echo "APP_HOSTPATH:      $(APP_HOSTPATH)"
    @echo "NEWRELIC_APPNAME:  $(NEWRELIC_APPNAME)"
    @echo "INFRA_VERSION:     $(INFRA_VERSION)"
    @echo "BUILD_TAG:         $(BUILD_TAG)"
    @echo "MERGE_REF:         $(MERGE_REF)"
    @echo "GIT_REF:           $(GIT_REF)"
  @echo ""

clean:
  rm -fr source
  docker-compose -p build down -v

checkout:
  GIT_SOURCE=$(GIT_SOURCE) \
  GIT_REF=$(GIT_REF) \
  MERGE_SOURCE=$(MERGE_SOURCE) \
  MERGE_REF=$(MERGE_REF) \
  ./checkout.sh
  @echo "Source directory:"
  ls -al source
  @echo "Merge directory:"
  ls -al merge

rewrite:
  GIT_REF=$(GIT_REF) \
  GIT_SOURCE=$(GIT_SOURCE) \
  GOOGLE_PROJECT_ID=$(GOOGLE_PROJECT_ID) \
  INFRA_VERSION=$(INFRA_VERSION) \
  MAINTAINER="$(MAINTAINER)" \
  MERGE_REF=$(MERGE_REF) \
  MERGE_SOURCE=$(MERGE_SOURCE) \
  ./rewrite_dockerfiles.sh

bake:
  mkdir -p source/public
  ./bake.sh | tee source/bake.log

build: rewrite build-app build-openresty

build-app:
  mkdir -p app/source/public
  rsync -a --delete source/public/ app/source/public
  pushd app && \
  docker build \
  -t $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/$(CONTAINER_PREFIX)-app:$(BUILD_TAG) \
  -t $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/$(CONTAINER_PREFIX)-app:build-$(CIRCLE_BUILD_NUM) \
  . && \
  popd

build-openresty:
  INFRA_VERSION=$(INFRA_VERSION) \
  GIT_REF=$(GIT_REF) \
  MAINTAINER="$(MAINTAINER)" \
  GIT_SOURCE=$(GIT_SOURCE) \
  GIT_REF=$(GIT_REF) \
  GOOGLE_PROJECT_ID=$(GOOGLE_PROJECT_ID) \
  ./rewrite_dockerfiles.sh
  mkdir -p openresty/source/public
  rsync -a --delete source/public/ openresty/source/public
  pushd openresty && \
  docker build \
  -t $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/$(CONTAINER_PREFIX)-openresty:$(BUILD_TAG) \
  -t $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/$(CONTAINER_PREFIX)-openresty:build-$(CIRCLE_BUILD_NUM) \
  . && \
  popd

push:
  gcloud auth configure-docker
  docker push $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/$(CONTAINER_PREFIX)-openresty:$(BUILD_TAG)
  docker push $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/$(CONTAINER_PREFIX)-app:$(BUILD_TAG)
  docker push $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/$(CONTAINER_PREFIX)-openresty:build-$(CIRCLE_BUILD_NUM)
  docker push $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/$(CONTAINER_PREFIX)-app:build-$(CIRCLE_BUILD_NUM)

save:
  gsutil ls gs://$(SOURCE_BUCKET) || gsutil mb gs://$(SOURCE_BUCKET)
  gsutil -m rsync -d -r source gs://$(SOURCE_BUCKET)/$(SOURCE_BUCKET_PATH)
  @echo "Source files available at:"
  @echo "- gs://$(SOURCE_BUCKET)/$(SOURCE_BUCKET_PATH)"
  @echo "- https://console.cloud.google.com/storage/browser/$(SOURCE_BUCKET)/$(SOURCE_BUCKET_PATH)?project=planet-4-151612"
  TYPE="Source Build" EXTRA_TEXT="View built source files: https://console.cloud.google.com/storage/browser/$(SOURCE_BUCKET)/$(SOURCE_BUCKET_PATH)?project=planet-4-151612" "${HOME}/scripts/notify-job-success.sh"

pull:
    docker pull $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/$(CONTAINER_PREFIX)-app:$(BUILD_TAG) &
    docker pull $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/$(CONTAINER_PREFIX)-openresty:$(BUILD_TAG) &
  wait

deploy:
  # Update Helm repositories
  helm repo update

  # Create WP-Stateless bucket if it doesn't exist
  WP_STATELESS_OWNER=$(WP_STATELESS_OWNER) \
  WP_STATELESS_BUCKET=$(WP_STATELESS_BUCKET) \
  ./make_bucket.sh

  # Connect to cluster
  gcloud container clusters get-credentials $(GCLOUD_CLUSTER) \
  --zone $(GCLOUD_ZONE) \
  --project $(GOOGLE_PROJECT_ID)

    # Make Kubernetes namespace for the release if not exist
  APP_ENVIRONMENT=$(APP_ENVIRONMENT) \
  HELM_NAMESPACE=$(HELM_NAMESPACE) \
  APP_HOSTPATH=$(APP_HOSTPATH) \
  ./make_namespace.sh

  # Create Helm deploy secrets file from environment
  envsubst < secrets.yaml.in > secrets.yaml

  # Ensure Helm release is in a usable state
  # See: https://github.com/kubernetes/helm/issues/4004
  HELM_RELEASE=$(HELM_RELEASE) ./helm_prepare.sh

  # Upgrade or install deployment to cluster
  APP_HOSTNAME="$(APP_HOSTNAME)" \
  APP_HOSTPATH="$(APP_HOSTPATH)" \
  BUILD_TAG="$(BUILD_TAG)" \
  CLOUDSQL_INSTANCE="$(CLOUDSQL_INSTANCE)" \
  GCLOUD_REGION="$(GCLOUD_REGION)" \
  GOOGLE_PROJECT_ID="$(GOOGLE_PROJECT_ID)" \
  HELM_NAMESPACE="$(HELM_NAMESPACE)" \
  HELM_RELEASE="$(HELM_RELEASE)" \
  INFRA_VERSION="$(INFRA_VERSION)" \
  NEWRELIC_APPNAME="$(NEWRELIC_APPNAME)" \
  OPENRESTY_IMAGE="$(OPENRESTY_IMAGE)" \
  PHP_IMAGE="$(PHP_IMAGE)" \
  WP_STATELESS_BUCKET="$(WP_STATELESS_BUCKET)" \
  ./helm_deploy.sh

  rm -f secrets.yaml

  HELM_NAMESPACE=$(HELM_NAMESPACE) \
  HELM_RELEASE=$(HELM_RELEASE) \
  BUILD_TAG=$(BUILD_TAG) \
  OPENRESTY_IMAGE=$(OPENRESTY_IMAGE) \
  PHP_IMAGE=$(PHP_IMAGE) \
  ./helm_confirm.sh

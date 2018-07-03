VERSION ?= $(shell git describe --tags)
NAME := bandwagon
PACKAGE := gravitational.io/$(NAME):$(VERSION)
PACKAGE_FILENAME := $(NAME)-$(VERSION).tar.gz
OPS_URL ?= https://opscenter.localhost.localdomain:33009
GRAVITY ?= gravity
STATE_DIR ?=

CURRENT_DIR := $(shell pwd)
BUILD_DIR := $(CURRENT_DIR)/build
WEB_APP_DIR := $(CURRENT_DIR)/web

BUILDBOX_IMAGE := quay.io/gravitational/debian-venti:go1.10.3-stretch
BUILDBOX_DIR := /gopath/src/github.com/gravitational/$(NAME)


.PHONY: all
all: build


.PHONY: build
build: web-build go-build
	docker build -t $(NAME):$(VERSION) .


.PHONY: push
push:
	docker tag $(NAME):$(VERSION) apiserver:5000/$(NAME):$(VERSION) && \
		docker push apiserver:5000/$(NAME):$(VERSION)


.PHONY: run
run: build
	docker run -p 8000:8000 $(NAME):$(VERSION)


#
# The 'app' target builds bandwagon Telekube package in the current directory, for example:
#
#   $ VERSION=1.2.0 make app
#
# will produce 'bandwagon-1.2.0.tar.gz'.
#
.PHONY: app
app: TMPDIR := $(shell mktemp -d)
app:
	$(MAKE) import OPS_URL= STATE_DIR=$(TMPDIR) && \
	$(GRAVITY) package export $(PACKAGE) $(PACKAGE_FILENAME) --state-dir=$(TMPDIR) && \
	rm -rf $(TMPDIR)


.PHONY: import
import: build
	$(GRAVITY) --insecure app delete $(PACKAGE) --force --ops-url=$(OPS_URL) --state-dir=$(STATE_DIR) && \
	$(GRAVITY) --insecure app import ./app --vendor --ops-url=$(OPS_URL) --state-dir=$(STATE_DIR) \
		--version=$(VERSION) --set-image=$(NAME):$(VERSION)


.PHONY: web-build
web-build:
	$(MAKE) -C $(WEB_APP_DIR) docker-build


.PHONY: go-build
go-build:
	mkdir -p build
	docker run -i --rm=true -v $(CURRENT_DIR):$(BUILDBOX_DIR) \
		$(BUILDBOX_IMAGE) /bin/bash -c "make -C $(BUILDBOX_DIR) go-build-in-buildbox"


.PHONY: go-build-in-buildbox
go-build-in-buildbox:
	cd $(BUILDBOX_DIR) && \
		go build -o ./build/$(NAME)


.PHONY: clean
clean:
	rm -rf build

VER := 1.0.0
NAME := bandwagon
PACKAGE := gravitational.io/$(NAME):$(VER)
BUILD_DIR := ./build
OPS_URL ?= https://opscenter.localhost.localdomain:33009
GRAVITY ?= gravity
WEB_APP_DIR := ./web

.PHONY: all
all: build


.PHONY: build
build: web-build go-build
	docker build -t $(NAME):$(VER) .


.PHONY: run
run: build
	docker run -p 8000:8000 $(NAME):$(VER)


.PHONY: import
import: build
	$(GRAVITY) --insecure app delete $(PACKAGE) --force --ops-url=$(OPS_URL) && \
	$(GRAVITY) --insecure app import ./app --vendor --ops-url=$(OPS_URL)

.PHONY: web-build
web-build:
	$(MAKE) -C $(WEB_APP_DIR) docker-build

.PHONY: go-build
go-build:
	go build -o $(BUILD_DIR)/$(NAME)

REPO			= docker.io
IMG_NAME		= yidigun/bind9-dlz-mariadb

TAG				= 9.18.28-0ubuntu0.24.04.1
EXTRA_TAGS		= latest
TEST_ARGS		= -v `pwd`/cache:/var/cache/bind \
				  -v `pwd`/data:/var/lib/bind \
				  -p 53:53/tcp \
				  -p 53:53/udp \
				  -e MYSQL_HOST=dbserver \
				  -e LANG=ko_KR.UTF-8 \
				  -e TZ=Asia/Seoul

IMG_TAG			= $(TAG)
PUSH			= yes
BUILDER			= crossbuilder
PLATFORM		= linux/amd64,linux/arm64

.PHONEY: $(BUILDER) $(TAG) all test

all:
	@if [ -z "$(TAG)" ]; then \
	  echo "usage: make TAG=tagname [ BUILD_ARGS=\"NAME=value NAME=value ...\" ] [ PUSH=no ]" >&2; \
	else \
	  $(MAKE) $(TAG); \
	fi

test:
	BUILD_ARGS=; \
	for a in $(BUILD_ARGS); do \
	  BUILD_ARGS="$$BUILD_ARGS --build-arg \"$$a\""; \
	done; \
	docker build --progress=plain \
	  --build-arg IMG_NAME=$(IMG_NAME) --build-arg IMG_TAG=$(IMG_TAG) $$BUILD_ARGS \
	  -t $(REPO)/$(IMG_NAME):test . && \
	docker run -d --rm --name=`basename $(IMG_NAME)` \
	  $(TEST_ARGS) \
	  $(REPO)/$(IMG_NAME):test \
	  /bin/sh -c 'while true;do sleep 1;done'

$(TAG): $(BUILDER)
	@BUILD_ARGS=; \
	PUSH=; \
	for a in $(BUILD_ARGS); do \
	  BUILD_ARGS="$$BUILD_ARGS --build-arg \"$$a\""; \
	done; \
	if [ "$(PUSH)" = "yes" ]; then \
	  PUSH="--push"; \
	fi; \
	TAGS="-t $(REPO)/$(IMG_NAME):$(TAG)"; \
	for t in $(EXTRA_TAGS); do \
	  TAGS="$$TAGS -t $(REPO)/$(IMG_NAME):$$t"; \
	done; \
	CMD="docker buildx build \
	    --builder $(BUILDER) --platform "$(PLATFORM)" \
	    --build-arg IMG_NAME=$(IMG_NAME) --build-arg IMG_TAG=$(IMG_TAG) \
	    $$BUILD_ARGS $$PUSH $$TAGS \
	    ."; \
	echo $$CMD; \
	eval $$CMD

$(BUILDER):
	@if docker buildx ls | grep -q ^$(BUILDER); then \
	  : do nothing; \
	else \
	  CMD="docker buildx create --name $(BUILDER) \
	    --driver docker-container \
	    --platform \"$(PLATFORM)\""; \
	  echo $$CMD; \
	  eval $$CMD; \
	fi

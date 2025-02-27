VERSION:=$(shell ./.version/calculate-version.sh)

# Git version information
GIT_COMMIT ?= $(shell git rev-parse --short HEAD)
GIT_DESCRIBE ?= $(shell git describe --tags --always --match "v*")
GIT_DIRTY=$(shell test -n "`git status --porcelain`" && echo "+CHANGES" || true)
VERSION_LABEL=$(shell ./.version/calculate-version.sh)

# Docker image information
REGISTRY?=comet.docker.com
REPO_PREFIX?=comet-deployment
IMAGE_NAME=iops
IMAGE_REPO=$(REPO_PREFIX)/$(IMAGE_NAME)
IMAGE_TAG=$(IMAGE_REPO):$(VERSION)

#:help: help        | Displays the GNU makefile help
.PHONY: help
help: ; @sed -n 's/^#:help://p' Makefile

#:help: all         | Builds the Docker image and publishes it
.PHONY: all
all: build publish

#:help: build       | Builds the Docker image
.PHONY: build
build:
	@docker build --build-arg VERSION=$(VERSION_LABEL) --no-cache -t $(IMAGE_REPO):$(GIT_COMMIT) .

#:help: changelog   | Build the changelog
.PHONY: changelog
changelog:
	@git-chglog -o CHANGELOG.md --next-tag $(VERSION)
	@git add CHANGELOG.md && git commit -m "Updated CHANGELOG"
	@git push

#:help: clean       | Cleans the Docker
.PHONY: clean
clean:
	@rm -f $(IMAGE_NAME).tar

#:help: precommit   | Lint the project files using pre-commit
.PHONY: precommit
precommit:
	@pre-commit run --all-files

#:help: publish     | Publishes the Docker image
.PHONY: publish
publish:
	@docker build --build-arg VERSION=$(VERSION_LABEL) --no-cache -t $(IMAGE_TAG) .
	@docker tag $(IMAGE_TAG) $(IMAGE_REPO):latest
	@docker push $(REGISTRY)/$(IMAGE_TAG)

#:help: release     | Release the product, setting the tag and pushing.
.PHONY: release
release:
	@semtag final -s minor
	@git push --follow-tags

#:help: load        | Loads the Docker image from a tar-file
.PHONY: load
load:
	@docker load < $(IMAGE_NAME).tar

#:help: save        | Saves the Docker image to a tar-file
.PHONY: save
save:
	@docker save $(IMAGE_REPO) > $(IMAGE_NAME).tar

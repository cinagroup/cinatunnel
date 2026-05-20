# The targets cannot be run in parallel
.NOTPARALLEL:

VERSION       := $(shell git describe --tags --always --match "[0-9][0-9][0-9][0-9].*.*")
MSI_VERSION   := $(shell git tag -l --sort=v:refname | grep "w" | tail -1 | cut -c2-)

ifeq ($(ORIGINAL_NAME), true)
	BINARY_NAME := cinatunnel
else ifeq ($(FIPS), true)
	BINARY_NAME := cinatunnel-fips
else
	BINARY_NAME := cinatunnel
endif

ifeq ($(NIGHTLY), true)
	DEB_PACKAGE_NAME := $(BINARY_NAME)-nightly
	NIGHTLY_FLAGS := --conflicts cinatunnel --replaces cinatunnel
else
	DEB_PACKAGE_NAME := $(BINARY_NAME)
endif

ifeq ($(TARGET_OS), windows)
	DATE := $(shell git log -1 --format="%ad" --date=format-local:'%Y-%m-%dT%H:%M UTC' -- RELEASE_NOTES)
else
	DATE := $(shell date -u -r RELEASE_NOTES '+%Y-%m-%d-%H:%M UTC')
endif

VERSION_FLAGS := -X "main.Version=$(VERSION)" -X "main.BuildTime=$(DATE)"
ifdef PACKAGE_MANAGER
	VERSION_FLAGS := $(VERSION_FLAGS) -X "github.com/cinagroup/cinatunnel/cmd/cinatunnel/updater.BuiltForPackageManager=$(PACKAGE_MANAGER)"
endif

ifdef CONTAINER_BUILD
	VERSION_FLAGS := $(VERSION_FLAGS) -X "github.com/cinagroup/cinatunnel/metrics.Runtime=virtual"
endif

LINK_FLAGS :=
ifeq ($(FIPS), true)
	LINK_FLAGS := -linkmode=external -extldflags=-static $(LINK_FLAGS)
	GO_BUILD_TAGS := $(GO_BUILD_TAGS) osusergo netgo fips
	VERSION_FLAGS := $(VERSION_FLAGS) -X "main.BuildType=FIPS"
endif

LDFLAGS := -ldflags='$(VERSION_FLAGS) $(LINK_FLAGS)'
ifneq ($(GO_BUILD_TAGS),)
	GO_BUILD_TAGS := -tags "$(GO_BUILD_TAGS)"
endif

ifeq ($(debug), 1)
	GO_BUILD_TAGS += -gcflags="all=-N -l"
endif

IMPORT_PATH    := github.com/cinagroup/cinatunnel
PACKAGE_DIR    := $(CURDIR)/packaging
PREFIX         := /usr
INSTALL_BINDIR := $(PREFIX)/bin/
INSTALL_MANDIR := $(PREFIX)/share/man/man1/

LOCAL_ARCH ?= $(shell uname -m)
ifneq ($(GOARCH),)
    TARGET_ARCH ?= $(GOARCH)
else ifeq ($(LOCAL_ARCH),x86_64)
    TARGET_ARCH ?= amd64
else ifeq ($(LOCAL_ARCH),amd64)
    TARGET_ARCH ?= amd64
else ifeq ($(LOCAL_ARCH),i686)
    TARGET_ARCH ?= amd64
else ifeq ($(shell echo $(LOCAL_ARCH) | head -c 5),armv8)
    TARGET_ARCH ?= arm64
else ifeq ($(LOCAL_ARCH),aarch64)
    TARGET_ARCH ?= arm64
else ifeq ($(LOCAL_ARCH),arm64)
    TARGET_ARCH ?= arm64
else ifeq ($(shell echo $(LOCAL_ARCH) | head -c 4),armv)
    TARGET_ARCH ?= arm
else ifeq ($(LOCAL_ARCH),s390x)
    TARGET_ARCH ?= s390x
else
    $(error This system's architecture $(LOCAL_ARCH) isn't supported)
endif

LOCAL_OS ?= $(shell go env GOOS)
ifeq ($(LOCAL_OS),linux)
    TARGET_OS ?= linux
else ifeq ($(LOCAL_OS),darwin)
    TARGET_OS ?= darwin
else ifeq ($(LOCAL_OS),windows)
    TARGET_OS ?= windows
else ifeq ($(LOCAL_OS),freebsd)
    TARGET_OS ?= freebsd
else ifeq ($(LOCAL_OS),openbsd)
    TARGET_OS ?= openbsd
else
    $(error This system's OS $(LOCAL_OS) isn't supported)
endif

ifeq ($(TARGET_OS), windows)
	EXECUTABLE_PATH=./$(BINARY_NAME).exe
else
	EXECUTABLE_PATH=./$(BINARY_NAME)
endif

ifeq ($(TARGET_ARM), 7)
	PACKAGE_ARCH := armhf
else
	PACKAGE_ARCH := $(TARGET_ARCH)
endif

RPM_DIGEST := --rpm-digest sha256

GO_TEST_LOG_OUTPUT = /tmp/gotest.log

.PHONY: all
all: cinatunnel test

.PHONY: clean
clean:
	go clean

.PHONY: cinatunnel
cinatunnel:
	GOOS=$(TARGET_OS) GOARCH=$(TARGET_ARCH) $(ARM_COMMAND) go build -mod=vendor $(GO_BUILD_TAGS) $(LDFLAGS) $(IMPORT_PATH)/cmd/cinatunnel

.PHONY: container
container:
	docker build --build-arg=TARGET_ARCH=$(TARGET_ARCH) --build-arg=TARGET_OS=$(TARGET_OS) -t cinagroup/cinatunnel-$(TARGET_OS)-$(TARGET_ARCH):"$(VERSION)" .

.PHONY: generate-docker-version
generate-docker-version:
	echo latest $(VERSION) > versions

.PHONY: test
test: vet
	go test -v -mod=vendor -race $(LDFLAGS) ./...

.PHONY: cover
cover:
	@echo ""
	@echo "=====> Total test coverage: <====="
	@echo ""
	go tool cover -func ".cover/c.out" | grep "total:" | awk '{print $$3}'
	go tool cover -html ".cover/c.out" -o .cover/all.html

.PHONY: fuzz
fuzz:
	go test -fuzz=FuzzIPDecoder -fuzztime=600s ./packet
	go test -fuzz=FuzzICMPDecoder -fuzztime=600s ./packet
	go test -fuzz=FuzzSessionWrite -fuzztime=600s ./quic/v3
	go test -fuzz=FuzzSessionRead -fuzztime=600s ./quic/v3
	go test -fuzz=FuzzRegistrationDatagram -fuzztime=600s ./quic/v3
	go test -fuzz=FuzzPayloadDatagram -fuzztime=600s ./quic/v3
	go test -fuzz=FuzzRegistrationResponseDatagram -fuzztime=600s ./quic/v3
	go test -fuzz=FuzzNewIdentity -fuzztime=600s ./tracing
	go test -fuzz=FuzzNewAccessValidator -fuzztime=600s ./validation

cinatunnel.1: cinatunnel_man_template
	sed -e 's/\$\${VERSION}/$(VERSION)/; s/\$\${DATE}/$(DATE)/' cinatunnel_man_template > cinatunnel.1

install: cinatunnel cinatunnel.1
	mkdir -p $(DESTDIR)$(INSTALL_BINDIR) $(DESTDIR)$(INSTALL_MANDIR)
	install -m755 cinatunnel $(DESTDIR)$(INSTALL_BINDIR)/cinatunnel
	install -m644 cinatunnel.1 $(DESTDIR)$(INSTALL_MANDIR)/cinatunnel.1

.PHONY: capnp
capnp:
	which capnp
	which capnpc-go
	capnp compile -ogo tunnelrpc/proto/tunnelrpc.capnp tunnelrpc/proto/quic_metadata_protocol.capnp

.PHONY: vet
vet:
	go vet -mod=vendor github.com/cinagroup/cinatunnel/...

.PHONY: fmt
fmt:
	goimports -l -w -local github.com/cinagroup/cinatunnel $$(go list -mod=vendor -f '{{.Dir}}' -a ./... | fgrep -v tunnelrpc/proto)
	go fmt $$(go list -mod=vendor -f '{{.Dir}}' -a ./... | fgrep -v tunnelrpc/proto)

.PHONY: lint
lint:
	golangci-lint run

.PHONY: mocks
mocks:
	go generate mocks/mockgen.go

.PHONY: ci-build
ci-build:
	GOOS=linux GOARCH=amd64 go build -mod=vendor $(GO_BUILD_TAGS) $(LDFLAGS) $(IMPORT_PATH)/cmd/cinatunnel
	mkdir -p artifacts
	mv cinatunnel artifacts/cinatunnel

.PHONY: install-hooks
install-hooks:
	git config core.hooksPath .githooks
	@echo "Git hooks installed from .githooks/"


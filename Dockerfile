# use a builder image for building cinatunnel
ARG TARGET_GOOS
ARG TARGET_GOARCH
FROM golang:1.24 AS builder
ENV GO111MODULE=on \
  CGO_ENABLED=0 \
  TARGET_GOOS=${TARGET_GOOS} \
  TARGET_GOARCH=${TARGET_GOARCH} \
  CONTAINER_BUILD=1

WORKDIR /go/src/github.com/cinagroup/cinatunnel/

# copy our sources into the builder image
COPY . .

# compile cinatunnel
RUN make cinatunnel

# use a distroless base image with glibc
FROM gcr.io/distroless/base-debian13:nonroot

LABEL org.opencontainers.image.source="https://github.com/cinagroup/cinatunnel"

# copy our compiled binary
COPY --from=builder --chown=nonroot /go/src/github.com/cinagroup/cinatunnel/cinatunnel /usr/local/bin/

USER 65532:65532

ENTRYPOINT ["cinatunnel", "--no-autoupdate"]
CMD ["version"]

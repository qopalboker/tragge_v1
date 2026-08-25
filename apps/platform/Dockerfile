# ARCH-001: one versioned Platform image; deploy with --mode=api|realtime|worker.
FROM golang:1.24-alpine AS builder
RUN apk add --no-cache ca-certificates tzdata
ENV GOPROXY=https://goproxy.io,https://proxy.golang.org,direct
ENV GOSUMDB=sum.golang.org
WORKDIR /build

ARG VERSION=dev

COPY go.work go.work.sum ./
COPY packages/config/ packages/config/
COPY packages/observability/ packages/observability/
COPY apps/platform/go.mod apps/platform/go.sum* apps/platform/
RUN cd apps/platform && go mod download

COPY apps/platform/ apps/platform/
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags="-s -w -X main.Version=${VERSION}" -trimpath \
    -o /platform ./apps/platform/cmd/platform

RUN echo "nonroot:x:65534:65534:nonroot:/:/sbin/nologin" > /etc/passwd.minimal

FROM busybox:stable-musl
COPY --from=builder /etc/passwd.minimal /etc/passwd
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=builder /platform /platform
USER 65534:65534
EXPOSE 8080
# Same image; select mode at deploy time (ADR-0001).
ENV PLATFORM_MODE=api
ENV PLATFORM_ADDR=:8080
ENTRYPOINT ["/platform"]

# ARCH-007: independent Market Data image (market_data schema role).
FROM golang:1.24-alpine AS builder
RUN apk add --no-cache ca-certificates tzdata
ENV GOPROXY=https://goproxy.io,https://proxy.golang.org,direct
ENV GOSUMDB=sum.golang.org
WORKDIR /build

ARG VERSION=dev

COPY go.work go.work.sum ./
COPY packages/ packages/
COPY apps/market-ingestor/go.mod apps/market-ingestor/go.sum* apps/market-ingestor/
RUN cd apps/market-ingestor && go mod download

COPY apps/market-ingestor/ apps/market-ingestor/
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags="-s -w" -trimpath \
    -o /market-ingestor ./apps/market-ingestor/cmd/market-ingestor

RUN echo "nonroot:x:65534:65534:nonroot:/:/sbin/nologin" > /etc/passwd.minimal

FROM busybox:stable-musl
COPY --from=builder /etc/passwd.minimal /etc/passwd
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=builder /market-ingestor /market-ingestor
USER 65534:65534
EXPOSE 8084
ENV POSTGRES_USER=market_data
ENTRYPOINT ["/market-ingestor"]

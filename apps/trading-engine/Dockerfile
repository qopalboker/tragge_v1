# ENG-001: independent Trading Engine image (engine schema role only).
FROM golang:1.24-alpine AS builder
RUN apk add --no-cache ca-certificates tzdata
ENV GOPROXY=https://goproxy.io,https://proxy.golang.org,direct
ENV GOSUMDB=sum.golang.org
WORKDIR /build

ARG VERSION=dev

COPY go.work go.work.sum ./
COPY packages/ packages/
COPY apps/trading-engine/go.mod apps/trading-engine/go.sum* apps/trading-engine/
RUN cd apps/trading-engine && go mod download

COPY apps/trading-engine/ apps/trading-engine/
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags="-s -w" -trimpath \
    -o /trading-engine ./apps/trading-engine/cmd/trading-engine

RUN echo "nonroot:x:65534:65534:nonroot:/:/sbin/nologin" > /etc/passwd.minimal

FROM busybox:stable-musl
COPY --from=builder /etc/passwd.minimal /etc/passwd
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=builder /trading-engine /trading-engine
USER 65534:65534
EXPOSE 8085
# Engine runtime must not carry Market Data provider or Platform JWT secrets.
ENV POSTGRES_USER=engine
ENTRYPOINT ["/trading-engine"]

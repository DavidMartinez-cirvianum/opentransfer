FROM golang:1.24-alpine AS builder
WORKDIR /src
COPY go.mod ./
COPY cmd ./cmd
COPY internal ./internal
ARG VERSION=dev
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w -X main.version=${VERSION}" -o /out/opentransfer ./cmd/opentransfer

FROM alpine:3.21
RUN addgroup -S -g 10001 opentransfer && adduser -S -D -H -u 10001 -G opentransfer opentransfer \
    && mkdir -p /var/lib/opentransfer/files \
    && chown -R 10001:10001 /var/lib/opentransfer
COPY --from=builder /out/opentransfer /usr/local/bin/opentransfer
USER 10001:10001
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/opentransfer"]

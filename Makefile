BINARY ?= bin/opentransfer
VERSION ?= dev

.PHONY: test build run check

test:
	go test ./...

build:
	mkdir -p bin
	CGO_ENABLED=0 go build -trimpath -ldflags="-s -w -X main.version=$(VERSION)" -o $(BINARY) ./cmd/opentransfer

run:
	go run ./cmd/opentransfer

check:
	bash -n install.sh actualizador.sh
	go vet ./...
	go test ./...

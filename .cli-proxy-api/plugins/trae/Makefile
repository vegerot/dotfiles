.PHONY: build test clean

OUT_DIR := $(HOME)/.cli-proxy-api/plugins/darwin/arm64
OUT := $(OUT_DIR)/trae.dylib

build:
	mkdir -p $(OUT_DIR)
	CGO_ENABLED=1 go build -buildmode=c-shared -o $(OUT) ./cmd/trae

test:
	go test -v ./...

clean:
	rm -f $(OUT) $(OUT_DIR)/trae.h

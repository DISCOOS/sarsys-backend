# Default host IP
HOST = 0.0.0.0

# Detect operating system in Makefile.
ifeq ($(OS),Windows_NT)
	OSNAME = WIN32
else
	UNAME_S := $(shell uname -s)
	ifeq ($(UNAME_S),Linux)
		OSNAME = LINUX
	endif
	ifeq ($(UNAME_S),Darwin)
		OSNAME = OSX
		# Mac OSX workaround
		HOST = host.docker.internal
	endif
endif

.PHONY: \
	test models

.SILENT: \
	test models

test:
	dart --no-sound-null-safety test -j 1

models:
	echo "Generating models..."; \
	mkdir  -p "lib/src/generated"
	protoc --dart_out="generate_kythe_info,grpc:lib/src/generated" \
		--proto_path protos \
		any.proto \
		json.proto \
		timestamp.proto \
		event.proto \
		file.proto \
		metric.proto \
		aggregate.proto \
		repository.proto \
		snapshot.proto
	dartfmt -w lib/src/generated
	echo "[✓] Generating models complete."

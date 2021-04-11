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
	configure pub_get pub_upgrade docker_is_up models check commit test \

.SILENT: \
	configure pub_get pub_upgrade docker_is_up models check commit test \

configure:
	pub global activate protoc_plugin

check:
	if [[ `git status --porcelain` ]]; then echo 'You have changes, aborting.'; exit 1; else echo "No changes"; fi

commit:
	if [[ `git status --porcelain` ]]; then git commit -am "Generated OpenAPI document"; fi

test:
	echo "Testing..."
	echo "event_source..."; cd event_source; dart --no-sound-null-safety test -j 1
	echo "event_source_grpc..."; cd event_source_grpc; dart --no-sound-null-safety test -j 1
	echo "sarsys_core..."; cd sarsys_core; dart --no-sound-null-safety test -j 1
	echo "sarsys_domain..."; cd sarsys_domain; dart --no-sound-null-safety test -j 1
	echo "sarsys_app_server..."; cd sarsys_app_server; dart --no-sound-null-safety test -j 1
	echo "sarsys_tracking_server..."; cd sarsys_tracking_server; dart --no-sound-null-safety test -j 1
	echo "sarsys_ops_server..."; cd sarsys_ops_server; dart --no-sound-null-safety test -j 1
	echo "[✓] Testing complete."

models:
	echo "Generating models..."
	echo "event_source..."; cd event_source; pub run build_runner build --delete-conflicting-outputs
	echo "event_source_grpc..."; cd event_source_grpc; \
	mkdir  -p "lib/src/generated"; \
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
		snapshot.proto; \
	dartfmt -w lib/src/generated
	echo "sarsys_tracking_server..."; cd sarsys_tracking_server; \
	mkdir  -p "lib/src/generated"; \
	protoc --dart_out="generate_kythe_info,grpc:lib/src/generated" \
		--proto_path ../event_source_grpc/protos \
		any.proto \
		json.proto \
		event.proto \
		metric.proto \
		timestamp.proto \
		repository.proto \
		--proto_path protos \
		tracking_service.proto; \
	dartfmt -w lib/src/generated
	echo "[✓] Generating models complete."

docker_is_up:
	docker info >/dev/null 2>&1
	echo "Docker is running"

pub_get:
	echo "Get dependencies..."
	echo "event_source..."; cd event_source; pub get
	echo "event_source_test..."; cd event_source_test; pub get
	echo "event_source_grpc..."; cd event_source_grpc; pub get
	echo "event_source_grpc_test..."; cd event_source_grpc_test; pub get
	echo "sarsys_core..."; cd sarsys_core; pub get
	echo "sarsys_domain..."; cd sarsys_domain; pub get
	echo "sarsys_app_server..."; cd sarsys_app_server; pub get
	echo "sarsys_app_server_test..."; cd sarsys_app_server_test; pub get
	echo "sarsys_tracking_server..."; cd sarsys_tracking_server; pub get
	echo "sarsys_tracking_server_test..."; cd sarsys_tracking_server_test; pub get
	echo "sarsys_ops_server..."; cd sarsys_ops_server; pub get
	echo "sarsys_ops_server_test..."; cd sarsys_ops_server_test; pub get
	echo "[✓] Get dependencies finished"

pub_upgrade:
	echo "Upgrade dependencies..."
	echo "event_source..."; cd event_source; pub upgrade
	echo "event_source_test..."; cd event_source_test; pub upgrade
	echo "event_source_grpc..."; cd event_source_grpc; pub upgrade
	echo "event_source_grpc_test..."; cd event_source_grpc_test; pub upgrade
	echo "sarsys_core..."; cd sarsys_core; pub upgrade
	echo "sarsys_domain..."; cd sarsys_domain; pub upgrade
	echo "sarsys_app_server..."; cd sarsys_app_server; pub upgrade
	echo "sarsys_app_server_test..."; cd sarsys_app_server_test; pub upgrade
	echo "sarsys_tracking_server..."; cd sarsys_tracking_server; pub upgrade
	echo "sarsys_tracking_server_test..."; cd sarsys_tracking_server_test; pub upgrade
	echo "sarsys_ops_server..."; cd sarsys_ops_server; pub upgrade
	echo "sarsys_ops_server_test..."; cd sarsys_ops_server_test; pub upgrade
	echo "[✓] Upgrade dependencies finished"

eventstore:
	echo "Starting eventstore..."
	docker run -d --rm --name eventstore -p 2113:2113 -p 1113:1113 eventstore/eventstore
	echo "[✓] Eventstore started"

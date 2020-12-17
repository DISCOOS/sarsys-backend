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
	check commit test serve document models snapshot localhost \
	build push publish install delete restart rollback status eventstore \
    docker_is_up #verify_image

.SILENT: \
	check commit test serve document models snapshot localhost \
	build push publish install delete restart rollback status eventstore \
	docker_is_up #verify_image

check:
	if [[ `git status --porcelain` ]]; then echo 'You have changes, aborting.'; exit 1; else echo "No changes"; fi

commit:
	if [[ `git status --porcelain` ]]; then git commit -am "Generated OpenAPI document"; fi

test:
	pub run test -j 1

models:
	echo "Generating models..."; \
	protoc --dart_out=grpc:lib/src/generated -Iprotos protos/sarsys_tracking_service.proto
#	rm lib/src/generated/metadata.pb{enum,json}.dart
	dartfmt -w lib/src/generated
	echo "[✓] Generating models complete."

snapshot:
	echo "Build dart JIT snapshot of bin/main.dart (faster boot and less memory usage) ..."
	dart --snapshot=bin/main.snapshot --snapshot-kind=app-jit bin/main.dart \
		--port 8082 --config config.src.yaml --training=true
	echo "[✓] Building dart snapshot bin/main.snapshot finished"

docker_is_up:
	docker info >/dev/null 2>&1
	echo "Docker is running"

build: docker_is_up models test snapshot
	echo "Build docker image..."
	docker build --no-cache -t discoos/sarsys_tracking_server:latest .
	echo "[✓] Build docker image finished"

localhost:
	echo "Start SarSys Tracking Server as docker container ..."
	echo "$(OSNAME): Host IP available using $(HOST)"
	docker run -d -i -t -p 80:8082 --env EVENTSTORE_HOST=http://$(HOST) --env EVENTSTORE_PORT=2113 --env EVENTSTORE_LOGIN=admin --env EVENTSTORE_PASSWORD=changeit --env TENANT=discoos --rm --name sarsys_tracking_server discoos/sarsys_tracking_server:latest
	echo "[✓] SarSys Tracking Server listening at $(HOST)"

push:
	echo "Push changes to github..."
	git push
	git push --tags
	echo "[✓] Push changes to github"
	echo "Push docker image..."
	docker push discoos/sarsys_tracking_server:latest
	echo "[✓] Deploy docker image finished"

publish: check build commit push
	echo "Applying SARSys Tracking server..."
	kubectl apply -f ../k8s/ns.yaml; \
	kubectl apply -f ../k8s/tracking/rbac.yaml; \
	kubectl apply -f ../k8s/tracking/config.yaml; \
	if cat ../k8s/tracking/server.yaml | kubectl diff -f - > /dev/null 2>&1; then \
	    echo "StatefulSet unchanged, restart using rollout (k8s version 1.15 or higher)"; \
	    kubectl -n sarsys rollout restart statefulset sarsys-tracking-server; \
	else \
	    echo "StatefulSet changed"; \
	    kubectl apply -f ../k8s/tracking/server.yaml; \
	fi
	if ! kubectl -n sarsys rollout status statefulset sarsys-tracking-server; then \
        kubectl -n sarsys rollout undo statefulset sarsys-tracking-server; \
        kubectl -n sarsys rollout status statefulset sarsys-tracking-server; \
		echo "[!] Publish to kubernetes failed"; \
	    exit 1; \
    fi
	echo "[✓] Publish to kubernetes finished"

install:
	echo "Applying SARSys Tracking server..."
	kubectl apply -f ../k8s/ns.yaml; \
	kubectl apply -f ../k8s/rbac.yaml; \
	kubectl apply -f ../k8s/tracking/config.yaml; \
	kubectl apply -f ../k8s/tracking/server.yaml; \
    kubectl -n sarsys rollout status statefulset sarsys-tracking-server; \
	echo "[✓] SARSys applied"

delete:
	echo "Deleting SARSys server..."
	# DO NOT DELETE NAMESPACE AND RBACK unless you know what you are doing!
	# kubectl apply -f ../k8s/ns.yaml;
	# kubectl delete -f ../k8s/rbac.yaml; \
	kubectl delete -f ../k8s/tracking/rbac.yaml; \
	kubectl delete -f ../k8s/tracking/config.yaml; \
	kubectl delete -f ../k8s/tracking/server.yaml; \
	echo "1) Manually delete PersistentVolumeClaims"; \
	kubectl -n sarsys get pvc | grep data-sarsys-tracking-server-; \
	echo "2) Manually delete PersistentVolumes"; \
	kubectl -n sarsys get pv | grep sarsys/data-sarsys-tracking-server-
	echo "[✓] SARSys server deleted"

restart:
	echo "Restarting using rollout (k8s version 1.15 or higher)"
	kubectl -n sarsys rollout restart statefulset sarsys-tracking-server
	kubectl -n sarsys rollout status statefulset sarsys-tracking-server
	echo "[✓] Restart finished"

rollback:
	echo "Rolling back last publish to kubernetes..."
	kubectl -n sarsys rollout undo statefulset sarsys-tracking-server
	kubectl -n sarsys rollout status statefulset sarsys-tracking-server
	echo "[✓] Rollback finished"

status:
	echo "Fetching rollout status from kubernetes..."
	kubectl -n sarsys rollout status statefulset sarsys-tracking-server
	echo "Fetching rollout history from kubernetes..."
	kubectl -n sarsys rollout history statefulset sarsys-tracking-server
	echo "Fetching resource usage from kubernetes..."
	kubectl top pod sarsys-tracking-server-0 -n sarsys --containers
	kubectl top pod sarsys-tracking-server-1 -n sarsys --containers
	kubectl top pod sarsys-tracking-server-2 -n sarsys --containers

	echo "[✓] Status finished"

eventstore:
	echo "Starting eventstore..."
	docker run -d --rm --name eventstore -p 2113:2113 -p 1113:1113 eventstore/eventstore
	echo "[✓] Eventstore started"

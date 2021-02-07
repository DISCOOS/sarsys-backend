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
	echo "Generating SARSys Ops models..."; \
	pub run build_runner build --delete-conflicting-outputs; \
	echo "[✓] Generating models complete."

document:
	echo "Generate OpenAPI document..."
	aqueduct document --title "SarSys Ops Server" --host https://sarsys.app \
		--host http://localhost --machine | tail -1 > web/sarsys-ops.json
	echo "[✓] Generate OpenAPI document"

snapshot:
	echo "Build dart JIT snapshot of bin/main.dart (faster boot and less memory usage) ..."
	dart --snapshot=bin/main.snapshot --snapshot-kind=app-jit bin/main.dart \
		--port 8082 --config config.src.yaml --training=true
	echo "[✓] Building dart snapshot bin/main.snapshot finished"

docker_is_up:
	docker info >/dev/null 2>&1
	echo "Docker is running"

build: docker_is_up models document test snapshot
	echo "Build docker image..."
	docker build --no-cache -t discoos/sarsys_ops_server:latest .
	echo "[✓] Build docker image finished"

localhost:
	echo "Start SarSys ops Server as docker container ..."
	echo "$(OSNAME): Host IP available using $(HOST)"
	docker run -d -i -t -p 80:8082 --env EVENTSTORE_HOST=http  --env EVENTSTORE_HOST=$(HOST) --env EVENTSTORE_PORT=2113 --env EVENTSTORE_LOGIN=admin --env EVENTSTORE_PASSWORD=changeit --env TENANT=discoos --rm --name sarsys_ops_server discoos/sarsys_ops_server:latest
	echo "[✓] SARSys Ops Server listening at $(HOST)"

push:
	echo "Push changes to github..."
	git push
	git push --tags
	echo "[✓] Push changes to github"
	echo "Push docker image..."
	docker push discoos/sarsys_ops_server:latest
	echo "[✓] SARSys Ops Server deploy docker image finished"

publish: check build commit push
	echo "Applying SARSys Ops server..."
	kubectl apply -f ../k8s/ns.yaml; \
	kubectl apply -f ../k8s/ops/rbac.yaml; \
	kubectl apply -f ../k8s/ops/config.yaml; \
	if cat ../k8s/ops/server.yaml | kubectl diff -f - > /dev/null 2>&1; then \
	    echo "StatefulSet unchanged, restart using rollout (k8s version 1.15 or higher)"; \
	    kubectl -n sarsys rollout restart statefulset sarsys-ops-server; \
	else \
	    echo "StatefulSet changed"; \
	    kubectl apply -f ../k8s/ops/server.yaml; \
	fi
	if ! kubectl -n sarsys rollout status statefulset sarsys-ops-server; then \
        kubectl -n sarsys rollout undo statefulset sarsys-ops-server; \
        kubectl -n sarsys rollout status statefulset sarsys-ops-server; \
		echo "[!] Publish to kubernetes failed"; \
	    exit 1; \
    fi
	echo "[✓] SARSys Ops Server publish to kubernetes finished"

install:
	echo "Applying SARSys Ops server..."
	kubectl apply -f ../k8s/ns.yaml; \
	kubectl apply -f ../k8s/rbac.yaml; \
	kubectl apply -f ../k8s/ops/config.yaml; \
	kubectl apply -f ../k8s/ops/server.yaml; \
    kubectl -n sarsys rollout status statefulset sarsys-ops-server; \
	echo "[✓] SARSys applied"

delete:
	echo "Deleting SARSys Ops server..."
	# DO NOT DELETE NAMESPACE AND RBAC unless you know what you are doing!
	# kubectl apply -f ../k8s/ns.yaml;
	# kubectl delete -f ../k8s/rbac.yaml; \
	kubectl delete -f ../k8s/ops/rbac.yaml; \
	kubectl delete -f ../k8s/ops/config.yaml; \
	kubectl delete -f ../k8s/ops/server.yaml; \
	echo "1) Manually delete PersistentVolumeClaims"; \
	kubectl -n sarsys get pvc | grep data-sarsys-ops-server-; \
	echo "2) Manually delete PersistentVolumes"; \
	kubectl -n sarsys get pv | grep sarsys/data-sarsys-ops-server-
	echo "[✓] SARSys Ops Server deleted"

restart:
	echo "Restarting using rollout (k8s version 1.15 or higher)"
	kubectl -n sarsys rollout restart statefulset sarsys-ops-server
	kubectl -n sarsys rollout status statefulset sarsys-ops-server
	echo "[✓] SARSys Ops Server restart finished"

rollback:
	echo "Rolling back last publish to kubernetes..."
	kubectl -n sarsys rollout undo statefulset sarsys-ops-server
	kubectl -n sarsys rollout status statefulset sarsys-ops-server
	echo "[✓] SARSys Ops Server rollback finished"

status:
	echo "Fetching rollout status from kubernetes..."
	kubectl -n sarsys rollout status statefulset sarsys-ops-server
	echo "Fetching rollout history from kubernetes..."
	kubectl -n sarsys rollout history statefulset sarsys-ops-server
	echo "Fetching resource usage from kubernetes..."
	kubectl top pod sarsys-ops-server-0 -n sarsys --containers
	kubectl top pod sarsys-ops-server-1 -n sarsys --containers
	kubectl top pod sarsys-ops-server-2 -n sarsys --containers

	echo "[✓] SARSys Ops Server status finished"

eventstore:
	echo "Starting eventstore..."
	docker run -d --rm --name eventstore -p 2113:2113 -p 1113:1113 eventstore/eventstore
	echo "[✓] Eventstore started"

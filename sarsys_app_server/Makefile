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
	check commit test serve document snapshot localhost \
	build push publish install delete restart rollback status eventstore \
    docker_is_up download-snapshots

.SILENT: \
	check commit test serve document snapshot localhost \
	build push publish install delete restart rollback status eventstore \
	docker_is_up download-snapshots

check:
	if [[ `git status --porcelain` ]]; then echo 'You have changes, aborting.'; exit 1; else echo "No changes"; fi

commit:
	if [[ `git status --porcelain` ]]; then git commit -am "Generated OpenAPI document"; fi

test:
	echo "Testing..."
	dart --no-sound-null-safety test -j 1
	echo "[✓] Testing complete"

serve:
	pub run aqueduct:aqueduct serve --port 80 --isolates 1

document:
	echo "Generate OpenAPI document..."
	aqueduct document --title "SarSys App Server" --host https://sarsys.app \
		--host http://localhost --machine | tail -1 > web/sarsys-app.json
	echo "[✓] Generate OpenAPI document"

snapshot:
	echo "Build dart JIT snapshot of bin/main.dart (faster boot and less memory usage) ..."
	dart --no-sound-null-safety --snapshot=bin/main.snapshot --snapshot-kind=app-jit bin/main.dart \
		--port 8082 --instances 1 --config config.src.yaml --training=true
	echo "[✓] Building dart snapshot bin/main.snapshot finished"

docker_is_up:
	docker info >/dev/null 2>&1
	echo "Docker is running"

build: docker_is_up test document snapshot
	echo "Build docker image..."
	docker build --no-cache -t discoos/sarsys_app_server:latest .
	echo "[✓] Build docker image finished"

localhost:
	echo "Start SarSys App Server as docker container ..."
	echo "$(OSNAME): Host IP available using $(HOST)"
	docker run -d -i -t -p 80:8082 --env EVENTSTORE_HOST=http --env EVENTSTORE_HOST=$(HOST) --env EVENTSTORE_PORT=2113 --env EVENTSTORE_LOGIN=admin --env EVENTSTORE_PASSWORD=changeit --env TENANT=discoos --rm --name sarsys_app_server discoos/sarsys_app_server:latest
	echo "[✓] SarSys App Server listening at $(HOST)"

push:
	echo "Push changes to github..."
	git push
	git push --tags
	echo "[✓] Push changes to github"
	echo "Push docker image..."
	docker push discoos/sarsys_app_server:latest
	echo "[✓] SARSys App Server deploy docker image finished"

publish: check build commit push
	echo "Applying SARSys App server..."
	kubectl apply -f ../k8s/ns.yaml; \
	kubectl apply -f ../k8s/app/rbac.yaml; \
	kubectl apply -f ../k8s/app/config.yaml; \
	if cat ../k8s/app/server.yaml | kubectl diff -f - > /dev/null 2>&1; then \
	    echo "StatefulSet unchanged, restart using rollout (k8s version 1.15 or higher)"; \
	    kubectl -n sarsys rollout restart statefulset sarsys-app-server; \
	else \
	    echo "StatefulSet changed"; \
	    kubectl apply -f ../k8s/app/server.yaml; \
	fi
	if ! kubectl -n sarsys rollout status statefulset sarsys-app-server; then \
        kubectl -n sarsys rollout undo statefulset sarsys-app-server; \
        kubectl -n sarsys rollout status statefulset sarsys-app-server; \
		echo "[!] Publish to kubernetes failed"; \
	    exit 1; \
    fi
	echo "[✓] SARSys App Server publish to kubernetes finished"

install:
	echo "Applying SARSys App server..."; \
	kubectl apply -f ../k8s/ns.yaml; \
	kubectl apply -f ../k8s/rbac.yaml; \
	kubectl apply -f ../k8s/app/config.yaml; \
	kubectl apply -f ../k8s/app/server.yaml; \
    kubectl -n sarsys rollout status statefulset sarsys-app-server; \
	echo "[✓] SARSys App Server applied"

delete:
	echo "Deleting SARSys App Server..."; \
	kubectl delete -f ../k8s/app/config.yaml; \
	kubectl delete -f ../k8s/app/server.yaml; \
	echo "1) Manually delete PersistentVolumeClaims"; \
	kubectl -n sarsys get pvc | grep data-sarsys-app-server-; \
	echo "2) Manually delete PersistentVolumes"; \
	kubectl -n sarsys get pv | grep sarsys/data-sarsys-app-server-
	echo "[✓] SARSys App Server deleted"

restart:
	echo "Restarting using rollout (k8s version 1.15 or higher)"
	kubectl -n sarsys rollout restart statefulset sarsys-app-server
	kubectl -n sarsys rollout status statefulset sarsys-app-server
	echo "[✓] SARSys App Server restart finished"

rollback:
	echo "Rolling back last publish to kubernetes..."
	kubectl -n sarsys rollout undo statefulset sarsys-app-server
	kubectl -n sarsys rollout status statefulset sarsys-app-server
	echo "[✓] SARSys App Server rollback finished"

status:
	echo "Fetching rollout status from kubernetes..."
	kubectl -n sarsys rollout status statefulset sarsys-app-server
	echo "Fetching rollout history from kubernetes..."
	kubectl -n sarsys rollout history statefulset sarsys-app-server
	echo "Fetching resource usage from kubernetes..."
	kubectl top pod sarsys-app-server-0 -n sarsys --containers
	kubectl top pod sarsys-app-server-1 -n sarsys --containers
	kubectl top pod sarsys-app-server-2 -n sarsys --containers

	echo "[✓] SARSys App Server status finished"

download-snapshots:
	echo "Downloading SARSys App Snapshots ..."
	mkdir -p .data
	kubectl -n sarsys cp sarsys/sarsys-app-server-0:/var/lib/sarsys/ .data/server-0
	kubectl -n sarsys cp sarsys/sarsys-app-server-0:/var/lib/sarsys/ .data/server-1
	kubectl -n sarsys cp sarsys/sarsys-app-server-0:/var/lib/sarsys/ .data/server-2
	echo "Analysing folder '.data'"
	ls -al .data
	echo "[✓] SARSys App Server snapshots downloading finished"

eventstore:
	echo "Starting eventstore..."
	docker run -d --rm --name eventstore -p 2113:2113 -p 1113:1113 eventstore/eventstore
	echo "[✓] Eventstore started"

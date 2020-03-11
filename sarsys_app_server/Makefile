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
	check commit test serve document models snapshot localhost build push publish restart rollback status eventstore
.SILENT: \
	check commit test serve document models snapshot localhost build push publish restart rollback status eventstore

check:
	if [[ `git status --porcelain` ]]; then echo 'You have changes, aborting.'; exit 1; else echo "No changes"; fi

commit:
	if [[ `git status --porcelain` ]]; then git commit -am "Generated OpenAPI document"; fi

test:
	cd ../event_source; pub run test -j 1
	cd ../sarsys_domain; pub run test -j 1
	cd ../sarsys_app_server; pub run test -j 1

serve:
	pub run aqueduct:aqueduct serve --port 80 --isolates 1

document:
	echo "Generate OpenAPI document..."
	aqueduct document --title "SarSys App Server" --host https://sarsys.app \
		--host http://localhost --machine | tail -1 > web/sarsys.json
	echo "[✓] Generate OpenAPI document"

models:
	echo "Generating models..."; \
	pub run build_runner build --delete-conflicting-outputs; \
	echo "[✓] Generating models complete."

snapshot:
	echo "Build dart JIT snapshot of bin/main.dart (faster boot and less memory usage) ..."
	dart --snapshot=bin/main.snapshot --snapshot-kind=app-jit bin/main.dart \
		--port 8082 --instances 1 --config config.src.yaml --training=true
	echo "[✓] Building dart snapshot bin/main.snapshot finished"

build: test document snapshot
	echo "Build docker image..."
	docker pull google/dart
	docker build --no-cache -t discoos/sarsys_app_server:latest .
	echo "[✓] Build docker image finished"

localhost:
	echo "Start SarSys App Server as docker container ..."
	echo "$(OSNAME): Host IP available using $(HOST)"
	docker run -d -i -t -p 80:8082 --env EVENTSTORE_HOST=http://$(HOST) --env EVENTSTORE_PORT=2113 --env EVENTSTORE_LOGIN=admin --env EVENTSTORE_PASSWORD=changeit --env TENANT=discoos --rm --name sarsys_app_server discoos/sarsys_app_server:latest
	echo "[✓] SarSys App Server listening at $(HOST)"

push:
	echo "Push changes to github..."
	git push
	git push --tags
	echo "[✓] Push changes to github"
	echo "Push docker image..."
	docker push discoos/sarsys_app_server:latest
	echo "[✓] Deploy docker image finished"

publish: check build commit push
	echo "Publish to kubernetes..."
	if cat k8s/sarsys.yaml | kubectl diff -f - > /dev/null 2>&1; then \
	    echo "Deployment unchanged, restart using rollout (k8s version 1.15 or higher)"; \
	    kubectl -n sarsys rollout restart deployment sarsys-app-server; \
	else \
	    echo "Deployment changed"; \
	    kubectl apply -f k8s/sarsys.yaml; \
	fi
	if ! kubectl -n sarsys rollout status deployment sarsys-app-server; then \
        kubectl -n sarsys rollout undo deployment sarsys-app-server; \
        kubectl -n sarsys rollout status deployment sarsys-app-server; \
		echo "[!] Publish to kubernetes failed"; \
	    exit 1; \
    fi
	echo "[✓] Publish to kubernetes finished"

restart:
	echo "Restarting using rollout (k8s version 1.15 or higher)"
	kubectl -n sarsys rollout restart deployment sarsys-app-server
	kubectl -n sarsys rollout status deployment sarsys-app-server
	echo "[✓] Restart finished"

rollback:
	echo "Rolling back last publish to kubernetes..."
	kubectl -n sarsys rollout undo deployment sarsys-app-server
	kubectl -n sarsys rollout status deployment sarsys-app-server
	echo "[✓] Rollback finished"

status:
	echo "Fetching rollout status from kubernetes..."
	kubectl -n sarsys rollout status deployment sarsys-app-server
	echo "Fetching rollout history from kubernetes..."
	kubectl -n sarsys rollout history deployment sarsys-app-server
	echo "[✓] Status finished"

eventstore:
	echo "Starting eventstore..."
	docker run -d --rm --name eventstore -p 2113:2113 -p 1113:1113 eventstore/eventstore
	echo "[✓] Eventstore started"

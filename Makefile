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
	endif
endif

.PHONY: \
	test serve document models build push publish
.SILENT: \
	test serve document models build push publish

test:
	pub run test

serve:
	pub run aqueduct:aqueduct serve --port 80 --isolates 1

document:
	echo "Generate OpenAPI document..."
	if [[ `git status --porcelain` ]]; then echo 'You have changes, aborting.'; exit 1; fi
	aqueduct document --title "SarSys App Server" --host https://sarsys.app --machine > web/sarsys.json
	if [[ `git status --porcelain` ]]; then git commit -am "Generated OpenAPI document"; fi
	echo "[✓] Generate OpenAPI document"

models:
	echo "Generating models..."; \
	pub run build_runner build --delete-conflicting-outputs; \
	echo "[✓] Generating models complete."

build: test document
	echo "Build docker image..."
	docker build --no-cache -t discoos/sarsys_app_server:latest .
	echo "[✓] Build docker image finished"

push:
	echo "Push changes to github..."
	git push
	git push --tags
	echo "[✓] Push changes to github"
	echo "Push docker image..."
	docker push discoos/sarsys_app_server:latest
	echo "[✓] Deploy docker image finished"

publish: build push
	echo "Publish to kubernetes..."
	kubectl apply -f k8s.yaml
	if ! kubectl -n sarsys rollout status deployment sarsys-app-server; then \
        kubectl -n sarsys rollout undo deployment sarsys-app-server; \
        kubectl -n sarsys rollout status deployment sarsys-app-server; \
		echo "[!] Publish to kubernetes failed"; \
	    exit 1; \
    fi
	echo "[✓] Publish to kubernetes finished"
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
	test serve document build push publish
.SILENT: \
	test serve document build push publish

test:
	pub run test

serve:
	pub run aqueduct:aqueduct serve --port 80 --isolates 2

document:
	echo "Generate OpenAPI document..."
	aqueduct document --title "SarSys App Server" --host https://sarsys.app > web/sarsys.json
	if [[ `git status --porcelain` ]]; then git commit -am "Generated OpenAPI document"; fi
	echo "[✓] Generate OpenAPI document"

build: test document
	echo "Build docker image..."
	docker build -t discoos/sarsys_app_server:latest .
	echo "[✓] Build docker image"

push:
	echo "Push changes to github..."
	git push
	git push --tags
	echo "[✓] Push changes to github"
	echo "Push docker image..."
	docker push discoos/sarsys_app_server:latest
	echo "[✓] Deploy docker image"

publish: build push
	echo "Publish to kubernetes..."
	kubectl apply -f k8s.yaml
	kubectl -n sarsys get pods
	echo "[✓] Publish to kubernetes"
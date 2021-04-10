
.PHONY: \
	models test
.SILENT: \
	models test

models:
	echo "Generating models..."; \
	pub run build_runner build --delete-conflicting-outputs; \
	echo "[✓] Generating models complete."

test:
	dart --no-sound-null-safety test -j 1

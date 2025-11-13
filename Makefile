 
APP_NAME=tilt-logs

# Build the release binary
build:
	cargo build --release

# Install the binary locally for quick testing
install-local:
	cp target/release/$(APP_NAME) /usr/local/bin/$(APP_NAME)

# Trigger a release through the release script
# Usage: make release VERSION=v0.1.0
release:
	./release.sh $(VERSION)

.PHONY: bump audit dev tap-init tap-sync fmt clippy

# Auto-increment the patch version in Cargo.toml (e.g., 0.1.0 -> 0.1.1)
bump:
	@set -e; \
	current=$$(sed -n 's/^version = "\(.*\)"/\1/p' Cargo.toml | head -n1); \
	if ! printf "%s" "$$current" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$$'; then \
		echo "Current version '$$current' is not semver (x.y.z). Aborting."; \
		exit 1; \
	fi; \
	major=$${current%%.*}; rest=$${current#*.}; minor=$${rest%%.*}; patch=$${current##*.}; \
	new_patch=$$((patch + 1)); new_version="$$major.$$minor.$$new_patch"; \
	echo "Bumping version: $$current -> $$new_version"; \
	sed -i '' -E "s/^version = \"[0-9]+\.[0-9]+\.[0-9]+\"/version = \"$$new_version\"/" Cargo.toml; \
	echo "Updated Cargo.toml to version $$new_version"

# Format, Clippy and Security audit
audit: fmt clippy
	@set -e; \
	if ! command -v cargo-audit >/dev/null 2>&1; then \
		echo "Installing cargo-audit..."; \
		cargo install cargo-audit --locked; \
	fi; \
	echo "Running cargo audit"; \
	cargo audit

# Format check (no changes)
fmt:
	@echo "Running cargo fmt --check"
	@cargo fmt --all -- --check

# Clippy with warnings as errors
clippy:
	@echo "Running cargo clippy"
	@cargo clippy --all-targets --all-features -D warnings

# Dev watch/rebuild loop (requires cargo-watch). Pass app args via ARGS="...".
dev:
	@set -e; \
	if ! command -v cargo-watch >/dev/null 2>&1; then \
		echo "Installing cargo-watch..."; \
		cargo install cargo-watch --locked; \
	fi; \
	echo "Starting cargo watch (build, test, run)"; \
	cargo watch -q -c -x "build" -x "test" -x "run -- $${ARGS}"

# Simple Brew tap repo generator/sync
# TAP_DIR is a local folder scaffold you can push to GitHub as your tap repo.
TAP_DIR ?= brew-tap
tap-init:
	@set -e; \
	mkdir -p "$(TAP_DIR)/Formula"; \
	if [ ! -f "$(TAP_DIR)/README.md" ]; then \
		cat > "$(TAP_DIR)/README.md" <<'EOF' \
# Homebrew Tap \
 \
This is a Homebrew tap for $(APP_NAME). \
 \
Usage: \
  brew tap YOUR_GITHUB_USERNAME/homebrew-tap \
  brew install $(APP_NAME) \
 \
Copy or update the formula under Formula/ and push this repository to GitHub. \
EOF \
	; fi; \
	cp -f Formula/$(APP_NAME).rb "$(TAP_DIR)/Formula/$(APP_NAME).rb" 2>/dev/null || true; \
	echo "Initialized tap skeleton in $(TAP_DIR)/"; \
	echo "Next steps (example):"; \
	echo "  cd $(TAP_DIR) && git init && git branch -m main"; \
	echo "  git remote add origin git@github.com:YOUR_GITHUB_USERNAME/homebrew-tap.git"; \
	echo "  git add . && git commit -m 'init tap' && git push -u origin main"

tap-sync:
	@mkdir -p "$(TAP_DIR)/Formula"
	@cp -f Formula/*.rb "$(TAP_DIR)/Formula/" || true
	@echo "Synced formula(s) to $(TAP_DIR)/Formula/"
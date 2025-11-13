 
#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Usage: ./release.sh v0.1.0"
  exit 1
fi

VERSION="$1"

echo "🔧 Updating version in Cargo.toml..."
sed -i '' "s/^version = \".*\"/version = \"${VERSION#v}\"/" Cargo.toml

echo "🔧 Updating version in Homebrew formula..."
sed -i '' "s/version \".*\"/version \"${VERSION}\"/" Formula/tilt-logs.rb
sed -i '' "s|releases/download/v[0-9.]*|releases/download/${VERSION}|g" Formula/tilt-logs.rb
# Reset SHA256 placeholders (they'll be computed during GitHub Actions)
sed -i '' 's/sha256 "[^"]*"/sha256 "REPLACE_WITH_REAL_SHA256"/' Formula/tilt-logs.rb

echo "🔧 Committing version bump..."
git add Cargo.toml Formula/tilt-logs.rb
git commit -m "Bump version to $VERSION"

echo "🔧 Tagging..."
git tag "$VERSION"

echo "🚀 Pushing tag..."
git push origin "$VERSION"

echo "✨ Release process started! GitHub Actions will build & publish binaries, update the Homebrew formula, and upload assets."
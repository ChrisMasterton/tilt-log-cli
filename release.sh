 
#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Usage: ./release.sh v0.1.0"
  exit 1
fi

VERSION="$1"

echo "🔧 Updating version in Cargo.toml..."
sed -i '' "s/^version = \".*\"/version = \"${VERSION#v}\"/" Cargo.toml

echo "🔧 Committing version bump..."
git add Cargo.toml
git commit -m "Bump version to $VERSION"

echo "🔧 Tagging..."
git tag "$VERSION"

echo "🚀 Pushing tag..."
git push origin "$VERSION"

echo "✨ Release process started! GitHub Actions will build & publish binaries, update the Homebrew formula, and upload assets."
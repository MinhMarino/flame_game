#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Encode iOS signing files for GitHub Actions secrets.

Usage:
  ./scripts/prepare-ios-secrets.sh certificate <path-to.p12>
  ./scripts/prepare-ios-secrets.sh profile <path-to.mobileprovision>

Examples:
  ./scripts/prepare-ios-secrets.sh certificate ~/Downloads/distribution.p12
  ./scripts/prepare-ios-secrets.sh profile ~/Downloads/FlameGame.mobileprovision

Then add the printed base64 values to GitHub:
  Settings -> Secrets and variables -> Actions -> New repository secret
EOF
}

if [ $# -ne 2 ]; then
  usage
  exit 1
fi

kind="$1"
file="$2"

if [ ! -f "$file" ]; then
  echo "File not found: $file" >&2
  exit 1
fi

case "$kind" in
  certificate)
    secret_name="IOS_DISTRIBUTION_CERTIFICATE_BASE64"
    ;;
  profile)
    secret_name="IOS_PROVISIONING_PROFILE_BASE64"
    if command -v /usr/libexec/PlistBuddy >/dev/null 2>&1; then
      profile_name=$(/usr/libexec/PlistBuddy -c "Print Name" /dev/stdin <<< "$(security cms -D -i "$file")")
      team_id=$(/usr/libexec/PlistBuddy -c "Print TeamIdentifier:0" /dev/stdin <<< "$(security cms -D -i "$file")")
      echo "Profile name (use for IOS_PROVISIONING_PROFILE_NAME): $profile_name"
      echo "Team ID (use for IOS_DEVELOPMENT_TEAM): $team_id"
      echo
    fi
    ;;
  *)
    usage
    exit 1
    ;;
esac

echo "Secret name: $secret_name"
echo "Base64 value:"
base64 < "$file" | tr -d '\n'
echo

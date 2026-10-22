FROM nginx:1.27-alpine

COPY index.html /usr/share/nginx/html/index.html

# The Nginx image runs executable scripts in /docker-entrypoint.d before it serves traffic.
RUN cat > /docker-entrypoint.d/40-clouddeploy.sh << 'ENDSCRIPT'
#!/bin/sh
set -eu
color=$(printf '%s' "${DEPLOY_COLOR:-BLUE}" | tr '[:lower:]' '[:upper:]')
case "$color" in
  BLUE|GREEN) ;;
  *) echo "DEPLOY_COLOR must be BLUE or GREEN" >&2; exit 1 ;;
esac
version=$(printf '%s' "${APP_VERSION:-v1.0}" | tr -cd 'A-Za-z0-9._-')
build=$(printf '%s' "${BUILD_ID:-local}" | tr -cd 'A-Za-z0-9._-')
pod=$(printf '%s' "${POD_NAME:-}" | tr -cd 'A-Za-z0-9._-')
status=$(printf '%s' "${DEPLOY_STATUS:-healthy}" | tr -cd 'A-Za-z0-9._-')
if [ -z "$pod" ]; then pod=$(hostname | tr -cd 'A-Za-z0-9._-'); fi
if [ -z "$version" ] || [ -z "$build" ] || [ -z "$pod" ] || [ -z "$status" ]; then
  echo "Version, build, status, and pod name must use letters, numbers, dots, underscores, or hyphens." >&2
  exit 1
fi
cat > /usr/share/nginx/html/config.js << ENDCONFIG
window.CLOUDDEPLOY_CONFIG = {
  deployColor: "${color}",
  version: "${version}",
  buildId: "${build}",
  podName: "${pod}",
  status: "${status}"
};
ENDCONFIG
ENDSCRIPT
RUN chmod 755 /docker-entrypoint.d/40-clouddeploy.sh

EXPOSE 80

FROM nginx:alpine

ARG DEPLOY_COLOR=BLUE
ARG APP_VERSION=v1.0
ARG BUILD_ID=local

RUN printf '<!DOCTYPE html>\n<html lang="en">\n<head>\n<meta charset="UTF-8">\n<meta name="viewport" content="width=device-width, initial-scale=1.0">\n<title>CloudDeploy</title>\n<style>body{font-family:Arial,sans-serif;text-align:center;padding:60px;background:#101827;color:white} .card{max-width:650px;margin:auto;padding:40px;border-radius:18px;background:#1e293b}h1{color:#38bdf8}.tag{display:inline-block;padding:8px 14px;border-radius:20px;background:#334155}p{color:#cbd5e1}</style>\n</head>\n<body>\n<div class="card">\n<h1>CloudDeploy</h1>\n<p>CI/CD with Jenkins, Docker and Kubernetes</p>\n<p class="tag">Deployment: %s</p>\n<p>Version: %s</p>\n<p>Build: %s</p>\n<p>Automated Blue-Green Deployment Demo</p>\n</div>\n</body>\n</html>\n' "$DEPLOY_COLOR" "$APP_VERSION" "$BUILD_ID" > /usr/share/nginx/html/index.html

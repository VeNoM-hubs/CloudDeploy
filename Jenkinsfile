// Runs on the same EC2 host as Docker and K3s.
// Jenkins needs the docker group, KUBECONFIG=/var/lib/jenkins/.kube/config,
// and passwordless sudo for: k3s ctr images import -
pipeline {
    agent any
    options {
        skipDefaultCheckout(true)
        disableConcurrentBuilds()
        timeout(time: 20, unit: 'MINUTES')
    }
    parameters {
        choice(name: 'DEPLOY_COLOR', choices: ['BLUE', 'GREEN'], description: 'Deployment that receives this version, then live traffic.')
        string(name: 'APP_VERSION', defaultValue: 'v1.0', trim: true, description: 'Image tag and version shown on the page.')
        string(name: 'BUILD_ID', defaultValue: '', trim: true, description: 'Optional. Blank uses the Jenkins build number.')
    }
    environment {
        PATH = "/usr/local/bin:${env.PATH}"
        KUBECONFIG = '/var/lib/jenkins/.kube/config'
    }
    stages {
        stage('Checkout') {
            steps { checkout scm }
        }
        stage('Build image') {
            steps { sh 'docker build -t "clouddeploy:${APP_VERSION}" .' }
        }
        stage('Smoke test') {
            steps {
                sh '''
                    set -eu
                    name=clouddeploy-smoke
                    build_id="${BUILD_ID:-jenkins-$BUILD_NUMBER}"
                    docker rm -f "$name" >/dev/null 2>&1 || true
                    docker run -d --name "$name" -p 127.0.0.1:18080:80 \
                      -e DEPLOY_COLOR="$DEPLOY_COLOR" \
                      -e APP_VERSION="$APP_VERSION" \
                      -e BUILD_ID="$build_id" \
                      -e DEPLOY_STATUS=healthy \
                      "clouddeploy:${APP_VERSION}"
                    trap 'docker rm -f "$name" >/dev/null 2>&1 || true' EXIT
                    ok=0
                    for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
                      if curl -fsS http://127.0.0.1:18080/ | grep -q CloudDeploy; then ok=1; break; fi
                      sleep 1
                    done
                    test "$ok" -eq 1
                    body=$(curl -fsS http://127.0.0.1:18080/)
                    echo "$body" | grep -q "CloudDeploy"
                    echo "$body" | grep -q "Automated Blue-Green Deployment Demo"
                '''
            }
        }
        stage('Deploy') {
            steps {
                sh '''
                    set -eu
                    case "$DEPLOY_COLOR" in
                      BLUE) label=blue ;;
                      GREEN) label=green ;;
                      *) echo "DEPLOY_COLOR must be BLUE or GREEN" >&2; exit 1 ;;
                    esac
                    build_id="${BUILD_ID:-jenkins-$BUILD_NUMBER}"
                    image="clouddeploy:${APP_VERSION}"
                    if command -v k3s >/dev/null 2>&1; then
                      docker save "$image" | sudo -n k3s ctr images import -
                    fi
                    kubectl apply -f "k8s/${label}-deployment.yaml"
                    kubectl get service clouddeploy >/dev/null 2>&1 || kubectl apply -f k8s/service.yaml
                    kubectl set image "deployment/clouddeploy-${label}" "web=${image}"
                    kubectl set env "deployment/clouddeploy-${label}" \
                      DEPLOY_COLOR="$DEPLOY_COLOR" \
                      APP_VERSION="$APP_VERSION" \
                      BUILD_ID="$build_id" \
                      DEPLOY_STATUS=healthy
                    kubectl rollout status "deployment/clouddeploy-${label}" --timeout=180s
                '''
            }
        }
        stage('Switch service') {
            steps {
                sh '''
                    set -eu
                    case "$DEPLOY_COLOR" in
                      BLUE) label=blue ;;
                      GREEN) label=green ;;
                      *) exit 1 ;;
                    esac
                    build_id="${BUILD_ID:-jenkins-$BUILD_NUMBER}"
                    ready=$(kubectl get "deployment/clouddeploy-${label}" -o jsonpath='{.status.readyReplicas}')
                    test "${ready:-0}" -ge 1
                    pod=$(kubectl get pods -l "app=clouddeploy,color=${label}" -o jsonpath='{.items[0].metadata.name}')
                    body=$(kubectl exec "$pod" -- cat /usr/share/nginx/html/config.js)
                    printf '%s\n' "$body" | grep -q "deployColor: \"${DEPLOY_COLOR}\""
                    printf '%s\n' "$body" | grep -q "version: \"${APP_VERSION}\""
                    printf '%s\n' "$body" | grep -q "buildId: \"${build_id}\""
                    kubectl patch service clouddeploy --type merge \
                      -p "{\"spec\":{\"selector\":{\"app\":\"clouddeploy\",\"color\":\"${label}\"}}}"
                '''
            }
        }
    }
}

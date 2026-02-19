pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Determine Version') {
            steps {
                script {
                    // Get the latest git tag, default to 0.0.0 if none exists
                    def latestTag = sh(
                        script: "git describe --tags --abbrev=0 2>/dev/null || echo '0.0.0'",
                        returnStdout: true
                    ).trim()

                    // Remove 'v' prefix if present (v1.0.0 -> 1.0.0)
                    env.IMAGE_TAG = latestTag.replaceFirst('^v', '')
                    echo "Building version: ${env.IMAGE_TAG}"
                }
            }
        }

        stage('Setup Buildx') {
            steps {
                sh '''
                    docker buildx create --name multiplatform --use || true
                    docker buildx inspect --bootstrap
                '''
            }
        }

        stage('Login to DockerHub') {
            steps {
                sh '''
                    echo "$DOCKERHUB_CREDENTIALS_PSW" | docker login -u "$DOCKERHUB_CREDENTIALS_USR" --password-stdin
                '''
            }
        }

        stage('Build & Push Multi-Platform Image') {
            steps {
                sh """
                    docker buildx build \
                        --platform linux/amd64,linux/arm64 \
                        -t ${DOCKERHUB_CREDENTIALS_USR}/static-site:${IMAGE_TAG} \
                        -t ${DOCKERHUB_CREDENTIALS_USR}/static-site:latest \
                        --push \
                        .
                """
            }
        }
    }

    post {
        always {
            sh 'docker logout'
            cleanWs()
        }
        success {
            echo "Image pushed: ${DOCKERHUB_CREDENTIALS_USR}/static-site:${IMAGE_TAG}"
        }
        failure {
            echo 'Build failed!'
        }
    }
}
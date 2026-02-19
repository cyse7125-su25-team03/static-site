pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: scm.branches,
                    extensions: [
                        [$class: 'CloneOption', noTags: false, shallow: false]
                    ],
                    userRemoteConfigs: scm.userRemoteConfigs
                ])
            }
        }

        stage('Determine Next Version') {
            steps {
                script {
                    // Use Conventional Commits plugin to calculate next version
                    def nextVersion = nextVersion()
                    env.IMAGE_TAG = nextVersion.toString()
                    echo "Next version determined by Conventional Commits plugin: ${env.IMAGE_TAG}"
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

        stage('Tag Release') {
            steps {
                sh """
                    git config user.email "mavureddysenthilve.m@northeastern.edu"
                    git config user.name "Manikhandan3"
                    git tag -a v${IMAGE_TAG} -m "Release v${IMAGE_TAG}"
                    git push origin v${IMAGE_TAG}
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

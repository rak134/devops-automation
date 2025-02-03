@Library('Jenkins-Shared-library@main') _

pipeline {
    agent { label 'Slave' }

    environment {
        // Access constants from the shared library
        constants = constants()  // Fetch constants from the shared library

        AWS_ACCOUNT_ID = "${constants.AWS_ACCOUNT_ID}"
        AWS_DEFAULT_REGION = "${constants.AWS_DEFAULT_REGION}"
        IMAGE_REPO_NAME = "${constants.IMAGE_REPO_NAME}"
        IMAGE_TAG = "latest"
        REPOSITORY_URI = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${IMAGE_REPO_NAME}"
        GIT_REPO_URL = "${constants.GIT_REPO_URL}"
        GIT_CREDENTIALS_ID = "${constants.GIT_CREDENTIALS_ID}"
        ECR_CREDENTIALS_ID = "${constants.ECR_CREDENTIALS_ID}"
    }

    stages {
        stage('Cleanup Docker Environment') {
            steps {
                script {
                    sh 'docker system prune -af || true'
                }
            }
        }

        stage('Login into AWS ECR') {
            steps {
                script {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: ECR_CREDENTIALS_ID]]) {
                        sh """
                            aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | \
                            docker login --username AWS --password-stdin ${REPOSITORY_URI}
                        """
                    }
                }
            }
        }

        stage('Cloning Git Repository') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[
                        url: GIT_REPO_URL,
                        credentialsId: GIT_CREDENTIALS_ID
                    ]]
                ])
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t ${IMAGE_REPO_NAME}:${IMAGE_TAG} ."
                }
            }
        }

        stage('Tag Docker Image') {
            steps {
                script {
                    sh "docker tag ${IMAGE_REPO_NAME}:${IMAGE_TAG} ${REPOSITORY_URI}:${IMAGE_TAG}"
                }
            }
        }

        stage('Push Image to ECR') {
            steps {
                script {
                    sh "docker push ${REPOSITORY_URI}:${IMAGE_TAG}"
                }
            }
        }

        stage('Run Docker Container on Slave') {
            steps {
                script {
                    def containerName = "${IMAGE_REPO_NAME}-container"

                    echo "Checking for existing container: ${containerName}"
                    sh """
                        if docker ps -a --format '{{.Names}}' | grep -q '^${containerName}$'; then
                            echo "Stopping and removing existing container: ${containerName}"
                            docker stop ${containerName} || true
                            docker rm ${containerName} || true
                        fi
                    """

                    echo "Running Docker container on Slave node (port 9000)"
                    sh """
                        docker run -d -p 9000:9000 --name ${containerName} ${REPOSITORY_URI}:${IMAGE_TAG}
                    """
                }
            }
        }
    }
}

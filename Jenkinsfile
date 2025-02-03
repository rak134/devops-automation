@Library('Jenkins-Shared-library@main') _

pipeline {
    agent any

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
        stage('Run Docker Container') {
            steps {
                script {
                    echo "Running Docker container on port 8080"
                    // Run the container in detached mode and map port 8080 to the host
                    sh 'docker run -d -p 8080:8080 --name ${IMAGE_REPO_NAME}-container ${IMAGE_REPO_NAME}:latest'
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

    }
}

@Library('jenkins-shared-library') _

pipeline {
    agent { label 'Slave' }
    environment {
        AWS_ACCOUNT_ID = 'your-aws-account-id'
        AWS_DEFAULT_REGION = 'your-region'
        IMAGE_REPO_NAME = 'your-repo-name'
        IMAGE_TAG = "latest"
        REPOSITORY_URI = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${IMAGE_REPO_NAME}"
        GIT_REPO_URL = 'https://your-repo-url.git'
        GIT_CREDENTIALS_ID = 'your-credentials-id'
        ECR_CREDENTIALS_ID = 'your-ecr-credentials-id'
    }

    stages {
        stage('Cleanup Docker Environment') {
            steps {
                script {
                    sh 'docker system prune -af || true'
                }
            }
        }

        stage('Logging into AWS ECR') {
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

        stage('Building Docker Image') {
            steps {
                script {
                    sh "docker build -t ${IMAGE_REPO_NAME}:${IMAGE_TAG} ."
                }
            }
        }

        stage('Tagging Docker Image') {
            steps {
                script {
                    sh "docker tag ${IMAGE_REPO_NAME}:${IMAGE_TAG} ${REPOSITORY_URI}:${IMAGE_TAG}"
                }
            }
        }

        stage('Pushing Image to ECR') {
            steps {
                script {
                    sh "docker push ${REPOSITORY_URI}:${IMAGE_TAG}"
                }
            }
        }

        stage('Final Cleanup') {
            steps {
                script {
                    sh "docker rmi -f ${IMAGE_REPO_NAME}:${IMAGE_TAG} || true"
                    sh "docker rmi -f ${REPOSITORY_URI}:${IMAGE_TAG} || true"
                }
            }
        }
    }
}

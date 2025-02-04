@Library('jenkins-shared-library') _

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
        stage('Clone Git Repository') {
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

        stage('Cleanup Docker Environment') {
            steps {
                script {
                    sh """
                        docker system prune -af || true
                        docker stop ${IMAGE_REPO_NAME}-container || true
                        docker rm ${IMAGE_REPO_NAME}-container || true
                    """
                }
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

        stage('Run Docker Container') {
            steps {
                script {
                    echo "Running Docker container on port 8080"

                    sh """
                        docker run -d -p 8080:8080 --name ${IMAGE_REPO_NAME}-container ${IMAGE_REPO_NAME}:${IMAGE_TAG}
                        sleep 10  # Allow Tomcat time to initialize
                    """
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
    }

    post {
        success {
            echo "Deployment successful! Access Tomcat at http://localhost:8080/sample-webapp"
        }
        failure {
            echo "Deployment failed. Check Jenkins logs for errors."
        }
    }
}

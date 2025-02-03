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

        stage('Pulling Docker Image from ECR') {
            steps {
                script {
                    sh "docker pull ${REPOSITORY_URI}:${IMAGE_TAG}"
                }
            }
        }

        stage('Running Docker Container on Slave EC2') {
            steps {
                script {
                    sh """
                        docker run -d --name ${IMAGE_REPO_NAME} -p 9000:9000 ${REPOSITORY_URI}:${IMAGE_TAG}
                    """
                }
            }
        }
    }
}

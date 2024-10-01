pipeline {
    agent any
    environment {
        AWS_DEFAULT_REGION = 'us-east-1' // Specify your region here
        EKS_CLUSTER_NAME = 'main-eks-cluster' // Your EKS cluster name
    }
    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/ShaikhImtiarRahaman/AWS-CI-CD-Project.git'
            }
        }

        stage('Verify Permissions') {
            steps {
                sh 'aws eks list-clusters'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t myapp:latest .'
            }
        }
        
        stage('Check Files') {
            steps {
                sh 'ls -l'
            }
        }
        
        stage('Configure Kubeconfig') {
            steps {
                sh "aws eks update-kubeconfig --region ${AWS_DEFAULT_REGION} --name ${EKS_CLUSTER_NAME}"
            }
        }
        
        stage('Check Installations') {
            steps {
                sh 'aws --version'
                sh 'kubectl version --client'
            }
        }
        
        stage('Deploy to EKS') {
            steps {
                script {
                    def result = sh(script: 'kubectl apply -f deployment.yaml --validate=false', returnStatus: true)
                    if (result != 0) {
                        error("Deployment failed with exit code: ${result}")
                    }
                }
            }
        }
    }
}

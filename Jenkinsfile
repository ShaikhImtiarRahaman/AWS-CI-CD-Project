pipeline {
    agent any
    stages {
        stage('Build Docker Image') {
            steps {
                sh 'docker build -t myapp:latest .'
            }
        }
        stage('Deploy to EKS') {
            steps {
                sh 'kubectl apply -f deployment.yaml'
            }
        }
    }
}
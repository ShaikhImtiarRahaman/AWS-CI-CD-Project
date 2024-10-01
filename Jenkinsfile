pipeline {
    agent any
    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/ShaikhImtiarRahaman/AWS-CI-CD-Project.git'
            }
        }
        stage('Build Docker Image') {
            steps {
                sh 'docker build -t myapp:latest .'
            }
        }
        stage('Check Files') {
            steps {
                sh 'ls -l'  // Check if deployment.yaml exists
            }
        }
        stage('Deploy to EKS') {
            steps {
                // Ensure kubeconfig is set correctly before this step
                sh 'kubectl apply -f deployment.yaml --validate=false'
            }
        }
    }
}

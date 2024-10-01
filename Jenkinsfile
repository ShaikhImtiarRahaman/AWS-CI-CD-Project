pipeline {
    agent any
    environment {
        AWS_DEFAULT_REGION = 'us-east-1' // Specify your region here
        EKS_CLUSTER_NAME = 'main-eks-cluster' // Your EKS cluster name
    }
    stages {
        stage('Checkout') {
            steps {
                // Checkout code from the specified Git repository
                git 'https://github.com/ShaikhImtiarRahaman/AWS-CI-CD-Project.git'
            }
        }

        stage('Verify Permissions') {
            steps {
                // Verify that the AWS CLI can list the EKS clusters
                sh 'aws eks list-clusters'
            }
        }

        stage('Build Docker Image') {
            steps {
                // Build the Docker image from the Dockerfile in the current directory
                sh 'docker build -t myapp:latest .'
            }
        }
        
        stage('Check Files') {
            steps {
                // List the files in the current directory for verification
                sh 'ls -l'
            }
        }
        
        stage('Configure Kubeconfig') {
            steps {
                // Update kubeconfig to use the specified EKS cluster
                sh "aws eks update-kubeconfig --region ${AWS_DEFAULT_REGION} --name ${EKS_CLUSTER_NAME}"
            }
        }
        
        stage('Check Installations') {
            steps {
                // Check the installed versions of AWS CLI and kubectl
                sh 'aws --version'
                sh 'kubectl version --client' // Removed --short
            }
        }
        
        stage('Deploy to EKS') {
            steps {
                script {
                    // Deploy the application to EKS and check for errors
                    def result = sh(script: 'kubectl apply -f deployment.yaml --validate=false', returnStatus: true)
                    if (result != 0) {
                        error("Deployment failed with exit code: ${result}")
                    }
                }
            }
        }
    }
}

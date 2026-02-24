pipeline {
    agent any
    parameters {
        string(name: 'ENTREPRISE', defaultValue: 'acme', description: 'Nom du client')
        string(name: 'ENVIRONMENT', defaultValue: 'dev', description: 'Environnement')
    }
    stages {
        stage('Terraform Init') {
            steps {
                sh 'terraform init'
            }
        }
        stage('Terraform Plan') {
            steps {
                // Utilisation des variables Jenkins dans la commande Terraform
                sh "terraform plan -var='entreprise=${params.ENTREPRISE}' -var='environment=${params.ENVIRONMENT}'"
            }
        }
        stage('Terraform Apply') {
            steps {
                sh "terraform apply -var='entreprise=${params.ENTREPRISE}' -var='environment=${params.ENVIRONMENT}' --auto-approve"
            }
        }
    }
}
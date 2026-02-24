pipeline {
    agent any

    parameters {
        // Définit le nom du client
        string(name: 'CLIENT', defaultValue: 'nom-du-client', description: 'Nom du client pour le déploiement')
        
        // Définit l'environnement cible
        choice(name: 'ENV', choices: ['dev', 'staging', 'prod'], description: 'Environnement cible')
    }

    environment {
        TF_IN_AUTOMATION = 'true'
    }

    stages {
        stage('Initialisation') {
            steps {
                echo "Déploiement pour le client : ${params.CLIENT} en environnement : ${params.ENV}"
                sh 'terraform init'
            }
        }

        stage('Terraform Plan') {
            steps {
                // On passe les paramètres Jenkins aux variables Terraform
                sh "terraform plan -var='client=${params.CLIENT}' -var='env=${params.ENV}' -out=tfplan"
            }
        }

        stage('Terraform Apply') {
            steps {
                sh 'terraform apply -input=false tfplan'
            }
        }
    }
}
post{
    always{
        cleanWs()
}}
    
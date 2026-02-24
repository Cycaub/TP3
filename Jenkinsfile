pipeline {
    agent any

    environment {
        // Désactive l'interactivité pour Terraform en mode CI
        TF_IN_AUTOMATION = 'true'
    }

    stages {
        stage('Checkout') {
            steps {
                // Récupère le code depuis votre dépôt Git
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                // Initialise le backend et les plugins
                sh 'terraform init'
            }
        }

        stage('Terraform Plan') {
            steps {
                // Génère le plan de modification
                sh 'terraform plan -out=tfplan'
            }
        }

        stage('Terraform Apply') {
            steps {
                // Applique les changements sans demander de confirmation manuelle
                // car nous utilisons le fichier de plan généré précédemment
                sh 'terraform apply -input=false tfplan'
            }
        }
    }

    post {
        success {
            echo "L'infrastructure a été déployée avec succès !"
        }
        failure {
            echo "Le déploiement a échoué. Vérifiez les logs."
        }
    }
}
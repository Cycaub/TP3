pipeline {
    agent any

    //  environment {
    //    TF_IN_AUTOMATION = 'true'
    // }



stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                sh 'terraform init'
            }
        }

        // stage('Terraform Format & Validate') {
        //     steps {
        //         sh 'terraform fmt -check'
        //         sh 'terraform validate'
        // }
        }

        stage('Terraform Plan') {
            steps {
                // Génère un plan de sauvegarde pour l'exécution
                sh 'terraform plan -out=tfplan'
            }
        }

        // stage('Approval') {
        //     // Cette étape met la pipeline en pause pour une validation humaine
        //     steps {
        //         input message: "Voulez-vous appliquer ces changements sur l'infrastructure ?"
        //     }
        // }

        stage('Terraform Apply') {
            steps {
                sh 'terraform apply -input=false tfplan'
            }
        }
    }
    
    post {
        always {
            cleanWs() // Nettoie l'espace de travail après l'exécution
        }
    }

pipeline {
    agent any

    //  environment {
    //    TF_IN_AUTOMATION = 'true'
    // }


    stages {


        stage('Terraform Init') {
            steps {
                echo 'Building..'
            }
        }
        stage('Test') {
            steps {
                echo 'Testing..'
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying....'
            }
        }
    }
}
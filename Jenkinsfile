pipeline {
    agent none 
    stages {
        stage('Build') { 
            agent {
                docker {
                    image 'docker:dind' 
                }
            }
            steps {
                sh 'docker build . ' 
                sh 'docker image ls ' 
            }
        }
    }
}

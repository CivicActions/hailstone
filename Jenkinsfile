pipeline {
    agent any


    options {
        buildDiscarder(logRotator(numToKeepStr:'10'))
        timeout(time: 15, unit: 'MINUTES')
        ansiColor('xterm')
    }
    environment {
                SSH_CREDS = credentials('halistone-aws-creds')
            }

    stages {
        stage('Build Image') {
            steps {
                    sh 'env'

            }
        }
    }
}

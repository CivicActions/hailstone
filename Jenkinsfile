pipeline {
    agent any

    options {
        buildDiscarder(logRotator(numToKeepStr:'10'))
        timeout(time: 15, unit: 'MINUTES')
        ansiColor('xterm')
    }
    
    stages {
        stage('Build Image') {
            steps {
                script {
                    sh "ls"
                    
                    sh "packer build -var-file=variables.json packer-rhel7-ami.json"
                    
                }
            }
        }
    }
}

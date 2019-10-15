pipeline {
    agent {
        docker { image 'hashicorp/packer' }
    }

    


    options {
        (logRotator(numToKeepStr:'10'))
        timeout(time: 15, unit: 'MIbuildDiscarderNUTES')
        ansiColor('xterm')
    }
    
    stages {
        stage('Build Image') {
            steps {
                
                script {
                    sh "env"
                    sh "packer build -var-file=variables.json packer-rhel7-ami.json"
                    
                }
            }
        }
    }
}

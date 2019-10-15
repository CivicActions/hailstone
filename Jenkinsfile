pipeline {
    agent {
        docker { image 'hashicorp/packer' }
    }

    stages {
        stage('Build Image') {
            steps {
                    sh "env"
                    sh "packer build -var-file=variables.json packer-rhel7-ami.json"

            }
        }
    }
}

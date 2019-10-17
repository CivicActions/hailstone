pipeline {
    agent any


    
    environment {
                SSH_CREDS = credentials('halistone-aws-creds')
            }

    stages {
        stage('Build Image') {
            steps {
                    sh 'env'
                    sh 'docker run --env-file=env-create.sh -it -v /Users/ashish/.ssh:/root/.ssh -v /var/run/docker.sock:/var/run/docker.sock -v $(pwd):/packer hashicorp/packer:light build -var-file=/packer/variables.json /packer/packer-rhel7-ami.json'
            }
        }
    }
}

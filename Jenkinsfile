pipeline {
    agent any


    
    

    stages {
        stage('Build Image') {
            withCredentials([file(credentialsId: 'secretcred', variable: 'FILE')]) {
                    sh 'env'
                    sh "docker run --env-file=$FILE -it -v /Users/ashish/.ssh:/root/.ssh -v /var/run/docker.sock:/var/run/docker.sock -v $(pwd):/packer hashicorp/packer:light build -var-file=/packer/variables.json /packer/packer-rhel7-ami.json"
            }
        }
    }
}

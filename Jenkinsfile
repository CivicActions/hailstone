pipeline {
    agent any
    
    stages {
        stage('Build Image') {
            steps {
            withCredentials([file(credentialsId: 'secretcred', variable: 'sec')]) {
                    sh 'env'
                    sh 'whoami'
                    sh "docker run --env-file=$sec -i -v /var/run/docker.sock:/var/run/docker.sock -v \$(pwd)/setup.sh:/setup.sh -v \$(pwd)/packer-rhel7-ami.json:/packer-rhel7-ami.json -v \$(pwd)/variables.json:/variables.json hashicorp/packer:light build -var-file=variables.json packer-rhel7-ami.json"
                    //sh "docker run --env-file=$sec -i -v /var/run/docker.sock:/var/run/docker.sock -v \$(pwd)/setup.sh:/setup.sh hashicorp/packer:light build -var-file=/packer/variables.json /packer/packer-rhel7-ami.json"
            }}
        }
    }
}

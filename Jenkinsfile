pipeline {
    agent any
    
    environment {
        region = 'us-east-1'
        validation_tag = sh (returnStdout: true, script: '[ "$GIT_BRANCH" = "master" ] && echo development || echo ""').trim()
    }
    stages {
        stage('Build Rhel7 Image') {
            steps {
                echo "{env.validation_tag}"
                withCredentials([file(credentialsId: 'hailstone_secrets', variable: 'secrets')]) {

                   // sh 'docker run -e REGION=$region --env-file=$secrets -i -v /var/run/docker.sock:/var/run/docker.sock -v $(pwd)/setup.sh:/setup.sh -v $(pwd)/packer-rhel7-ami.json:/template.json -v $(pwd)/variables.json:/variables.json hashicorp/packer:light build -var-file=variables.json template.json'
                    sh 'docker run -e REGION=$region -e validation_tag=$validation_tag --env-file="$secrets" -i -v /var/run/docker.sock:/var/run/docker.sock -v "$(pwd)"/:/workspace/ -w /workspace/ hashicorp/packer:light build -var-file=variables.json packer-rhel7-ami.json'
                    sh 'docker run -e REGION=$region --env-file="$secrets" -i -v /var/run/docker.sock:/var/run/docker.sock -v "$(pwd)"/:/workspace/ -w /workspace/ python:alpine sh /workspace/add-kernel-tag.sh'

                }
            }
        }
    }
}

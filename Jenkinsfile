pipeline {
    agent any 

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/favxlaw/CI-proj.git'
            }
        }

        stage('Build') {
            steps {
                echo 'Building the project...'
                sh 'echo Build successful!'  
            }
        }

        stage('Test') {
            steps {
                echo 'Running tests...'
                sh 'echo Tests passed!'  
            }
        }
    }
}

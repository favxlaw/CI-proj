pipeline {
    agent any 

    environment {
        SONAR_SCANNER_HOME = tool 'SonarQube-Scanner'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/favxlaw/CI-proj.git'
            }
        }

        stage('Build') {
            steps {
                echo 'Building the project...'
                sh 'mvn clean package'  
            }
        }

        stage('Test') {
            steps {
                echo 'Running tests...'
                sh 'mvn test'  
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarCloud') {
                    sh '''
                    ${SONAR_SCANNER_HOME}/bin/sonar-scanner \
                      -Dsonar.projectKey=favxlaw_CI-proj \
                      -Dsonar.organization=favxlaw \
                      -Dsonar.sources=. \
                      -Dsonar.host.url=https://sonarcloud.io \
                      -Dsonar.login=${SONAR_TOKEN}
                    '''
                }
            }
        }

        stage('Upload to JFrog') {
            steps {
                script {
                    rtUpload (
                        serverId: 'jfrog-prod',
                        spec: '''{
                            "files": [
                                {
                                    "pattern": "target/*.jar",
                                    "target": "libs-release-local/my-app/release/"
                                }
                            ]
                        }'''
                    )
                }
            }
        }

        stage('Download from JFrog') {
            steps {
                script {
                    rtDownload (
                        serverId: 'jfrog-prod',
                        spec: '''{
                            "files": [
                                {
                                    "pattern": "libs-release-local/my-app/release/*.jar",
                                    "target": "downloads/"
                                }
                            ]
                        }'''
                    )
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}

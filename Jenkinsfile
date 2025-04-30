pipeline {
    agent any

    environment {
        FLUTTER_HOME = 'C:/flutter'
        ANDROID_SDK_ROOT = 'C:/Users/BHAVANA/AppData/Local/Android/Sdk'
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
            }
        }

        stage('Set PATH for Windows') {
            when {
                expression { !isUnix() }
            }
            environment {
                PATH = "C:/flutter/bin;C:/Users/BHAVANA/AppData/Local/Android/Sdk/platform-tools;C:/Users/BHAVANA/AppData/Local/Android/Sdk/cmdline-tools/latest/bin;${env.PATH}"
            }
            steps {
                echo 'Updated PATH for Windows'
            }
        }

        stage('Setup & Verify Environment') {
            steps {
                script {
                    if (isUnix()) {
                        sh 'echo "Verifying prerequisites..."'
                        sh 'flutter --version'
                        sh 'python --version || python3 --version'
                        sh 'pip --version || python -m pip --version || python3 -m pip --version'
                    } else {
                        bat 'echo "Verifying prerequisites..."'
                        bat 'flutter --version'
                        bat 'python --version'
                        bat 'python -m pip --version'
                    }
                }
            }
        }

        stage('Install Pre-commit Tools') {
            steps {
                echo 'Installing pre-commit and detect-secrets...'
                script {
                    if (isUnix()) {
                        sh 'python -m pip install --user pre-commit detect-secrets || python3 -m pip install --user pre-commit detect-secrets'
                    } else {
                        bat 'python -m pip install --user pre-commit detect-secrets'
                    }
                }
            }
        }

        stage('Run Pre-commit Hooks') {
            steps {
                echo 'Running pre-commit checks...'
                script {
                    if (isUnix()) {
                        sh 'pre-commit run --all-files'
                    } else {
                        bat '''
                        set PATH=%USERPROFILE%\\AppData\\Roaming\\Python\\Python312\\Scripts;%PATH%
                        pre-commit run --all-files
                        '''
                    }
                }
            }
        }

        stage('Build Flutter App') {
            steps {
                echo 'Building Flutter application...'
                script {
                    if (isUnix()) {
                        sh 'flutter build apk --release'
                    } else {
                        bat 'flutter build apk --release'
                    }
                }
            }
        }

        stage('Test') {
            steps {
                echo 'Running Flutter tests...'
                script {
                    if (isUnix()) {
                        sh 'flutter test'
                    } else {
                        bat 'flutter test'
                    }
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline finished.'
        }
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}

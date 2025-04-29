// Jenkinsfile (Declarative Pipeline)

pipeline {
    agent any // Or specify an agent label with Flutter/Python prerequisites: agent { label 'flutter-agent' }

    environment {
        FLUTTER_HOME = 'C:/flutter'
        ANDROID_SDK_ROOT = 'C:/Users/BHAVANA/AppData/Local/Android/Sdk'
        // Do NOT define PATH here to avoid parsing errors
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
            steps {
                script {
                    env.PATH = "C:/flutter/bin;C:/Users/BHAVANA/AppData/Local/Android/Sdk/platform-tools;C:/Users/BHAVANA/AppData/Local/Android/Sdk/cmdline-tools/latest/bin;" + env.PATH
                }
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
                        bat 'pip --version'
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
                        bat 'pre-commit run --all-files'
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

        // Add more stages for deployment or post-build steps as needed
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

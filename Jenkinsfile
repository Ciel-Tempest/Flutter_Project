pipeline {
    agent any

    environment {
        FLUTTER_HOME = 'C:/flutter'
        ANDROID_SDK_ROOT = 'E:/Sdk'
        PYTHON_SCRIPTS = 'C:/Users/BHAVANA/AppData/Local/Programs/Python/Python313/Scripts'
        PATH = "${FLUTTER_HOME}/bin;" +
               "${ANDROID_SDK_ROOT}/platform-tools;" +
               "${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin;" +
               "${PYTHON_SCRIPTS};" +
               "${env.PATH}"
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
            }
        }

        stage('Debug Python Path') {
            when {
                expression { !isUnix() }
            }
            steps {
                script {
                    bat 'echo Checking Python location...'
                    bat 'where python'
                    bat 'where pip'
                }
            }
        }

        stage('Setup & Verify Environment') {
            steps {
                script {
                    if (isUnix()) {
                        sh 'flutter --version'
                        sh 'python3 --version'
                        sh 'pip3 --version'
                    } else {
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
                        sh 'python3 -m pip install --user pre-commit detect-secrets'
                    } else {
                        bat 'python -m pip install --user pre-commit detect-secrets'
                    }
                }
            }
        }

        stage('Run Pre-commit Hooks') {
            steps {
                bat '''
                   where pre-commit
                   pre-commit run --all-files
               '''
            }
        }

        // stage('Accept Android Licenses') {
        //     steps {
        //         script {
        //             if (isUnix()) {
        //                 sh 'flutter doctor --android-licenses'
        //             } else {
        //                 bat 'flutter doctor --android-licenses'
        //             }
        //         }
        //     }
        // }
        // stage('Analyze Flutter Project') {
        //     steps {
        //         script {
        //             // Run flutter analyze through pre-commit hook
        //             bat '''
        //                 pre-commit run flutter-analyze --all-files || echo "Flutter Analyze warnings are ignored"
        //             '''
        //         }
        //     }
        // }

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

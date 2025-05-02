pipeline {
    agent any

    environment {
        FLUTTER_HOME = 'C:/flutter'
        ANDROID_SDK_ROOT = 'C:/Users/BHAVANA/AppData/Local/Android/Sdk'
        PYTHON_SCRIPTS = 'C:/Users/BHAVANA/Scripts'
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

        stage('Set PATH for Windows') {
            when {
                expression { !isUnix() }
            }
            environment {
                PATH = "C:/flutter/bin;" +
                       "C:/Users/BHAVANA/AppData/Local/Android/Sdk/platform-tools;" +
                       "C:/Users/BHAVANA/AppData/Local/Android/Sdk/cmdline-tools/latest/bin;" +
                       "C:/Users/BHAVANA/Scripts;" +
                       "${env.PATH}"
            }
            steps {
                echo 'Updated PATH for Windows'
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
                   echo Adding Python scripts to PATH...
                   set "OLD_PATH=%PATH%"
                   set "PY_SCRIPT_PATH=C:\\Users\\BHAVANA\\AppData\\Roaming\\Python\\Python313\\Scripts"
                   set "PATH=%PY_SCRIPT_PATH%;%OLD_PATH%"
                   where pre-commit
                   pre-commit run --all-files
               '''
            }
        }

        // stage('Clean Gradle Folder') {
        //     steps {
        //         echo 'Deleting .gradle folder...'
        //         script {
        //             if (isUnix()) {
        //                 sh 'rm -rf $HOME/.gradle'
        //             } else {
        //                 bat 'rmdir /s /q C:\\Users\\BHAVANA\\.gradle'
        //             }
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

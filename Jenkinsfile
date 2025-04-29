// Jenkinsfile (Declarative Pipeline)

pipeline {
    agent any // Or specify an agent label with Flutter/Python prerequisites: agent { label 'flutter-agent' }

    // environment {
        // Define Flutter SDK path if it's not in the system PATH (Adjust path as needed)
        // FLUTTER_HOME = '/path/to/flutter/sdk'
        // PATH = "${env.FLUTTER_HOME}/bin:${env.PATH}"

        // Define Python path if needed (less common)
        // PYTHON_HOME = '/path/to/python'
    //     // PATH = "${env.PYTHON_HOME}/bin:${env.PATH}"
    // }
    environment {
           FLUTTER_HOME = 'C:/flutter'
           PATH = "${env.FLUTTER_HOME}\\bin;${env.PATH}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                // Uses the SCM configuration from the Jenkins job
                checkout scm
            }
        }

        stage('Setup & Verify Environment') {
            steps {
                 // Use 'bat' for Windows agents, 'sh' for Linux/macOS
                 script {
                    if (isUnix()) {
                        sh 'echo "Verifying prerequisites..."'
                        sh 'flutter --version'
                        sh 'python --version || python3 --version' // Check for python
                        sh 'pip --version || python -m pip --version || python3 -m pip --version' // Check for pip
                    } else {
                        bat 'echo "Verifying prerequisites..."'
                        bat 'flutter --version'
                        bat 'python --version' // Might need adjustment for Windows python install
                        bat 'pip --version' // Might need adjustment for Windows pip install
                    }
                }
            }
        }

        stage('Install Pre-commit Tools') {
            steps {
                echo 'Installing pre-commit and detect-secrets...'
                 // Use 'bat' for Windows agents, 'sh' for Linux/macOS
                script {
                    if (isUnix()) {
                        // Using python -m pip is often more robust
                        sh 'python -m pip install --user pre-commit detect-secrets || python3 -m pip install --user pre-commit detect-secrets'
                        // Ensure the user bin directory is in PATH if using --user
                        // You might need to adjust PATH or install globally depending on agent setup
                    } else {
                        // Using python -m pip is often more robust
                        bat 'python -m pip install --user pre-commit detect-secrets'
                        // Ensure user scripts directory is in PATH if needed
                    }
                }
            }
        }

        stage('Run Pre-commit Hooks') {
            steps {
                echo 'Running pre-commit checks...'
                // Use 'bat' for Windows agents, 'sh' for Linux/macOS
                 script {
                    if (isUnix()) {
                        // Run pre-commit. It will use the .pre-commit-config.yaml
                        // Its exit code will determine stage success/failure
                        sh 'pre-commit run --all-files'
                    } else {
                        bat 'pre-commit run --all-files'
                    }
                }
            }
        }

        // --- Add subsequent stages for your Flutter project below ---

        stage('Build Flutter App') {
            steps {
                echo 'Building Flutter application...'
                 script {
                    if (isUnix()) {
                        sh 'flutter build apk --release' // Example: Build Android release
                        // sh 'flutter build ios --release --no-codesign' // Example: Build iOS release (needs macOS agent)
                    } else {
                        bat 'flutter build apk --release' // Example: Build Android release
                        // bat 'flutter build windows --release' // Example: Build Windows release
                    }
                }
                // Archive artifacts if needed
                // archiveArtifacts artifacts: 'build/app/outputs/**/*.apk', allowEmptyArchive: true
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
                 // Publish test results if needed
                 // junit 'build/test-results/**/*.xml'
             }
         }

        // Add stages for Deploy, etc.

    }

    post {
        always {
            echo 'Pipeline finished.'
            // Clean up workspace etc.
            // cleanWs()
        }
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed!'
            // Send notifications etc.
        }
    }
}

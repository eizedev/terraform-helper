// make sure to install .NET Core and PowerShell Core on Jenkins before running.
// Also ensure to install PS Module PSScriptAnalyzer (specifically for Jenkins
// user)

pipeline {
  agent any
  environment {
    API_KEY = credentials('nuget-api-key')
  }
  stages {
        stage('Run Analyzer') {
            steps {
                script {
                    String results = sh(
                        returnStdout: true,
                        script: "pwsh -Command 'Invoke-ScriptAnalyzer .'"
                    )

                    echo "Script analyzer results"
                    echo results

                    if (results != "") {
                        currentBuild.result = 'FAILED'
                        error 'Error when analyzing script.'
                    }
                }
            }
        }
        stage('Set Version') {
            when { branch 'master' }
            steps {
                sh "sed -e 's/\${VERSION}/${currentBuild.number}/' tf.ps1 > temp.ps1"
                sh "rm tf.ps1"
                sh "mv temp.ps1 tf.ps1"
            }
        }
        stage('Deploy to PowerShell Gallery') {
            when { branch 'master' }
            steps {
                script {
                    String status = sh(
                        returnStdout: true,
                        script: "pwsh -Command 'Publish-Script -Path ./tf.ps1 -NuGetApiKey $API_KEY' 2>&1"
                    )

                    echo "Publish script output"
                    echo status

                    if (status != "") {
                        currentBuild.result = 'FAILED'
                        error 'Error when publishing script.'
                    }
                }
            }
        }
    }
}
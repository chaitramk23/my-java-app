pipeline {
    agent {
        kubernetes {
            label 'javaapp-agent-test'
            defaultContainer 'maven'
            yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    jenkins: slave
spec:
  containers:
  - name: maven
    image: maven:3.9.6-openjdk-21-slim
    command:
    - cat
    tty: true
    volumeMounts:
    - mountPath: /home/jenkins/agent
      name: workspace
  - name: kaniko
    image: gcr.io/kaniko-project/executor:v1.9.0-debug
    command:
    - cat
    tty: true
    env:
    - name: DOCKER_CONFIG
      value: /kaniko/.docker
    volumeMounts:
    - mountPath: /home/jenkins/agent
      name: workspace
    - mountPath: /kaniko/.docker
      name: docker-config
  - name: helm
    image: alpine/helm:3.11.2
    command:
    - cat
    tty: true
    volumeMounts:
    - mountPath: /home/jenkins/agent
      name: workspace
  volumes:
  - name: workspace
    emptyDir: {}
  - name: docker-config
    secret:
      secretName: regcred
"""
        }
    }

    stages {
        stage('Checkout SCM') {
            steps {
                git url: 'https://github.com/chaitramk23/my-java-app.git', branch: 'main'
            }
        }

        stage('Build JAR') {
            steps {
                container('maven') {
                    sh 'mvn clean package'
                }
            }
        }

        stage('Build Docker Image & Push') {
            steps {
                container('kaniko') {
                    sh '''
                    /kaniko/executor \
                        --dockerfile=Dockerfile \
                        --context=./ \
                        --destination=<your-dockerhub-username>/my-java-app:latest
                    '''
                }
            }
        }

        stage('Deploy with Helm') {
            steps {
                container('helm') {
                    sh 'helm upgrade --install my-java-app ./helm-chart --namespace my-app --create-namespace'
                }
            }
        }
    }
}

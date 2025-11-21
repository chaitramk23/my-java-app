pipeline {
    agent {
        kubernetes {
            label 'javaapp-agent'
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
      image: maven:3.9.6-eclipse-temurin-21
      command:
        - sleep
      args:
        - "99999"
      tty: true
      volumeMounts:
        - mountPath: /home/jenkins/agent
          name: workspace
    - name: kaniko
      image: gcr.io/kaniko-project/executor:v1.9.0-debug
      command:
        - /busybox/sleep
      args:
        - "99999"
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
        - sleep
      args:
        - "99999"
      tty: true
      volumeMounts:
        - mountPath: /home/jenkins/agent
          name: workspace
    - name: jnlp
      image: jenkins/inbound-agent:latest
      env:
        - name: JENKINS_URL
          value: http://jenkins.jenkins.svc.cluster.local:8080
      resources:
        requests:
          memory: "256Mi"
          cpu: "100m"
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

    environment {
        AWS_DEFAULT_REGION = 'ap-south-1'
        IMAGE_NAME = 'your-dockerhub-username/my-java-app'
        IMAGE_TAG = 'latest'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build JAR') {
            steps {
                container('maven') {
                    sh 'mvn clean package'
                }
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                container('kaniko') {
                    sh '''
                      /kaniko/executor \
                      --context $WORKSPACE \
                      --dockerfile $WORKSPACE/Dockerfile \
                      --destination=$IMAGE_NAME:$IMAGE_TAG \
                      --skip-tls-verify
                    '''
                }
            }
        }

        stage('Deploy with Helm') {
            steps {
                container('helm') {
                    sh '''
                      helm upgrade --install my-java-app ./helm-chart \
                      --namespace default \
                      --set image.repository=$IMAGE_NAME \
                      --set image.tag=$IMAGE_TAG
                    '''
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline finished!'
        }
    }
}

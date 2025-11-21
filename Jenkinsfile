pipeline {
    agent {
        kubernetes {
            label 'javaapp-agent'
            defaultContainer 'jnlp'
            yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    jenkins: slave
spec:
  containers:
  - name: maven
    image: maven:3.9.6-eclipse-temurin-21-git
    command:
      - cat
    tty: true
    volumeMounts:
      - mountPath: /home/jenkins/agent
        name: workspace
  - name: helm
    image: alpine/helm:3.11.2
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
  - name: jnlp
    image: jenkins/inbound-agent:latest
    resources:
      requests:
        memory: 256Mi
        cpu: 100m
    env:
      - name: JENKINS_AGENT_WORKDIR
        value: /home/jenkins/agent
    volumeMounts:
      - mountPath: /home/jenkins/agent
        name: workspace-volume
  nodeSelector:
    kubernetes.io/os: linux
  restartPolicy: Never
  volumes:
    - name: workspace
      emptyDir: {}
    - name: docker-config
      secret:
        secretName: regcred
    - name: workspace-volume
      emptyDir: {}
"""
        }
    }

    stages {
        stage('Checkout') {
            steps {
                echo "Checking out source code..."
                checkout scm
            }
        }

        stage('Build JAR') {
            steps {
                container('maven') {
                    echo "Building JAR with Maven..."
                    sh 'mvn clean package -DskipTests'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                container('kaniko') {
                    echo "Building Docker image..."
                    sh '''
                    /kaniko/executor \
                    --context $WORKSPACE \
                    --dockerfile $WORKSPACE/Dockerfile \
                    --destination=<your-dockerhub-username>/my-java-app:latest \
                    --skip-tls-verify
                    '''
                }
            }
        }

        stage('Deploy Helm Chart') {
            steps {
                container('helm') {
                    echo "Deploying application with Helm..."
                    sh 'helm upgrade --install my-java-app ./helm-chart -n my-namespace'
                }
            }
        }
    }
}

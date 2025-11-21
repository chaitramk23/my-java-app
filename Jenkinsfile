pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins
  containers:
  - name: maven
    image: maven:3.9.6-eclipse-temurin-21
    command: ["sleep"]
    args: ["999999"]
    volumeMounts:
    - name: workspace
      mountPath: /home/jenkins/agent
  - name: kaniko
    image: gcr.io/kaniko-project/executor:v1.9.0-debug
    command: ["/busybox/sleep"]
    args: ["999999"]
    env:
    - name: DOCKER_CONFIG
      value: /kaniko/.docker
    volumeMounts:
    - name: workspace
      mountPath: /home/jenkins/agent
    - name: docker-config
      mountPath: /kaniko/.docker/
  volumes:
  - name: workspace
    emptyDir: {}
  - name: docker-config
    secret:
      secretName: regcred
      items:
      - key: .dockerconfigjson
        path: config.json
"""
        }
    }

    environment {
        AWS_ACCOUNT = "287084412105"
        AWS_REGION  = "ap-south-1"
        IMAGE_REPO  = "${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/javaapp"
        IMAGE_TAG   = "${BUILD_NUMBER}"
        FULL_IMAGE  = "${IMAGE_REPO}:${IMAGE_TAG}"
        K8S_NAMESPACE = "javaapp"
        HELM_CHART_DIR = "/home/jenkins/agent/javaapp-helm"
    }

    stages {
        stage("Build JAR") {
            steps {
                container("maven") {
                    sh """
                        cd /home/jenkins/agent
                        git clone https://github.com/chaitramk23/my-java-app.git .
                        mvn clean package -Dmaven.test.skip=true
                        ls -l target
                    """
                }
            }
        }

        stage("Build Docker Image & Push") {
            steps {
                container("kaniko") {
                    sh """
                        /kaniko/executor \
                          --dockerfile=/home/jenkins/agent/Dockerfile \
                          --context=/home/jenkins/agent \
                          --destination=${FULL_IMAGE} \
                          --single-snapshot
                    """
                }
            }
        }

        stage("Deploy with Helm") {
            steps {
                container("kaniko") {   // or use helm container if you want
                    sh """
                        helm upgrade --install javaapp ${HELM_CHART_DIR} \
                          --namespace ${K8S_NAMESPACE} --create-namespace \
                          --set image.repository=${IMAGE_REPO} \
                          --set image.tag=${IMAGE_TAG}
                    """
                }
            }
        }
    }
}

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
    - name: helm
      image: alpine/helm:3.11.2
      command: ["sleep"]
      args: ["999999"]
      volumeMounts:
        - name: workspace
          mountPath: /home/jenkins/agent
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
        AWS_ACCOUNT    = "287084412105"
        AWS_REGION     = "ap-south-1"
        IMAGE_REPO     = "${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/javaapp"
        IMAGE_TAG      = "${BUILD_NUMBER}"
        FULL_IMAGE     = "${IMAGE_REPO}:${IMAGE_TAG}"

        K8S_NAMESPACE  = "javaapp"
        HELM_CHART_DIR = "/home/ubuntu/my-java-app/javaapp-helm"
    }

    stages {
        stage("Build JAR") {
            steps {
                container("maven") {
                    sh """
                        cd /home/ubuntu/my-java-app
                        mvn clean package -Dmaven.test.skip=true
                        ls -l target
                    """
                }
            }
        }

        stage("Build Docker Image & Push to ECR") {
            steps {
                container("kaniko") {
                    sh """
                        echo "Building and pushing image: ${FULL_IMAGE}"
                        /kaniko/executor \
                          --dockerfile=/home/ubuntu/my-java-app/Dockerfile \
                          --context=/home/ubuntu/my-java-app \
                          --destination=${FULL_IMAGE} \
                          --single-snapshot
                    """
                }
            }
        }

        stage("Deploy to Kubernetes with Helm") {
            steps {
                container("helm") {
                    sh """
                        echo "Deploying to Kubernetes using Helm chart"
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

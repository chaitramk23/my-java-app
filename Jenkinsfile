pipeline {

    agent none

    environment {
        // Git repository
        GIT_URL = "https://github.com/spring-projects/spring-petclinic.git"
        GIT_BRANCH = "main"

        // AWS details
        AWS_ACCOUNT = "<your-account-id>"
        AWS_REGION  = "ap-south-1"

        // Docker image info
        IMAGE_REPO  = "${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/myjavaapp"
        IMAGE_TAG   = "${BUILD_NUMBER}"
        FULL_IMAGE  = "${IMAGE_REPO}:${IMAGE_TAG}"

        // Kubernetes/Helm
        K8S_NAMESPACE = "javaapp"
        RELEASE_NAME  = "javaapp"
    }

    stages {

        stage("Build + Image + Deploy") {

            agent {
                kubernetes {
                    yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    jenkins-agent: javaapp
spec:
  restartPolicy: Never
  serviceAccountName: jenkins
  containers:
    - name: maven
      image: maven:3.9.2-openjdk-17
      command:
        - cat
      tty: true
      volumeMounts:
        - name: workspace-volume
          mountPath: /home/jenkins/agent

    - name: kaniko
      image: gcr.io/kaniko-project/executor:latest
      volumeMounts:
        - name: workspace-volume
          mountPath: /home/jenkins/agent
        - name: kaniko-secret
          mountPath: /kaniko/.docker
          readOnly: true

    - name: helm
      image: alpine/helm:3.11.2
      volumeMounts:
        - name: workspace-volume
          mountPath: /home/jenkins/agent

  volumes:
    - name: workspace-volume
      emptyDir: {}
    - name: kaniko-secret
      secret:
        secretName: regcred

  volumes:
    - name: workspace-volume
      emptyDir: {}
    - name: kaniko-secret
      secret:
        secretName: regcred
                    """
                }
            }

            stages {

                stage("Checkout Code") {
                    steps {
                        container("maven") {
                            sh """
                                cd /home/jenkins/agent
                                git clone --branch ${GIT_BRANCH} ${GIT_URL} repo
                            """
                        }
                    }
                }

                stage("Build JAR") {
                    steps {
                        container("maven") {
                            sh """
                                cd /home/jenkins/agent/repo
                                mvn -Dmaven.test.skip=true clean package
                            """
                        }
                    }
                }

                stage("Build Docker Image") {
                    steps {
                        container("kaniko") {
                            sh """
                                /kaniko/executor \
                                  --dockerfile=/home/jenkins/agent/repo/Dockerfile \
                                  --context=/home/jenkins/agent/repo \
                                  --destination=${FULL_IMAGE}
                            """
                        }
                    }
                }

                stage("Deploy via Helm") {
                    steps {
                        container("helm") {
                            sh """
                                helm upgrade --install ${RELEASE_NAME} \
                                  /home/jenkins/agent/repo/my-java-app \
                                  --namespace ${K8S_NAMESPACE} \
                                  --create-namespace \
                                  --set image.repository=${IMAGE_REPO} \
                                  --set image.tag=${IMAGE_TAG}
                            """
                        }
                    }
                }

            }
        }
    }
}

                 

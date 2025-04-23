# -------- Stage 1: Checkout code --------
FROM alpine/git AS code_checkout

WORKDIR /my-java-app

# Clone your Git repo (replace the repo URL accordingly)
RUN git clone https://github.com/chaitramk23/my-java-app.git

# -------- Stage 2: Build JAR using Maven --------
FROM maven:3.8-eclipse-temurin-17 AS build

WORKDIR /my-java-app

# Copy code from the previous stage
COPY --from=code_checkout /my-java-app /.

# Build the application (compile + test + package)
RUN mvn clean package -DskipTests

# -------- Stage 3: Run the JAR --------
FROM openjdk:17-jdk-slim

WORKDIR /my-java-app
 



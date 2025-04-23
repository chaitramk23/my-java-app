# -------- Stage 1: Checkout code --------
FROM alpine/git as code_checkout

WORKDIR /app

# Clone your Git repo (replace the repo URL accordingly)
RUN git clone https://github.com/yourusername/your-java-repo.git .

# -------- Stage 2: Build JAR using Maven --------
FROM maven:3.8.8-openjdk-17 as build

WORKDIR /app

# Copy code from the previous stage
COPY --from=code_checkout /app /app

# Build the application (compile + test + package)
RUN mvn clean package -DskipTests

# -------- Stage 3: Run the JAR --------
FROM openjdk:17-jdk-slim

WORKDIR /app

# Copy the built jar from the build stage
COPY --from=build /app/target/*.jar app.jar

# Command to run the application
ENTRYPOINT ["java", "-jar", "app.jar"]

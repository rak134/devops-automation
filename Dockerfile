# Stage 1: Build the Maven Project
FROM maven:3.8.5-openjdk-11 AS builder
WORKDIR /app

# Copy project files and build
COPY pom.xml .
RUN mvn dependency:go-offline

COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2: Set Up Tomcat Server and Deploy WAR
FROM openjdk:11-jdk
WORKDIR /usr/local/tomcat

# Install Tomcat
RUN apt-get update && apt-get install -y wget && \
    wget https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.34/bin/apache-tomcat-10.1.34.tar.gz && \
    tar -xvzf apache-tomcat-10.1.34.tar.gz && \
    mv apache-tomcat-10.1.34 tomcat && \
    rm apache-tomcat-10.1.34.tar.gz

# Give execution permission to Tomcat scripts
RUN chmod +x /usr/local/tomcat/tomcat/bin/*.sh

# Copy built WAR file from Maven build
COPY --from=builder /app/target/*.war /usr/local/tomcat/tomcat/webapps/sample-webapp.war

EXPOSE 8080

CMD ["/usr/local/tomcat/tomcat/bin/catalina.sh", "run"]

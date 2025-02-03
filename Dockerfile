FROM ubuntu:22.04

# Set environment variables
ENV TOMCAT_VERSION=10.1.34
ENV CATALINA_HOME=/usr/local/tomcat
ENV PATH=$CATALINA_HOME/bin:$PATH

# Update package list and install necessary packages
RUN apt-get update -y && \
    apt-get install -y openjdk-17-jdk git curl && \
    apt-get clean

# Download and install Apache Tomcat
RUN curl -L https://archive.apache.org/dist/tomcat/tomcat-10/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz -o /tmp/tomcat.tar.gz && \
    mkdir -p $CATALINA_HOME && \
    tar -xzf /tmp/tomcat.tar.gz -C $CATALINA_HOME --strip-components=1 && \
    rm /tmp/tomcat.tar.gz

# Copy the web application to the Tomcat webapps directory
COPY /target/sample-webapp.war $CATALINA_HOME/webapps/



# Expose the default Tomcat port
EXPOSE 8080

# Start Tomcat
CMD ["catalina.sh", "run"]

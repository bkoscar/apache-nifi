FROM ubuntu:22.04 AS ubuntu-nifi 

LABEL maintainer="Omar"
LABEL description="Apache NiFi 2.1.0 on Ubuntu 22.04 with Java 21 ARM64"

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    USER_NAME=omar \
    TZ=America/Mexico_City \
    HOME_DIR=/home/omar \
    NIFI_VERSION=2.1.0 \
    NIFI_HOME=/opt/nifi \
    JAVA_HOME=/usr/lib/jvm/java-21-openjdk-arm64 
    

# Update the system and configure the timezone
RUN apt-get update \
    && apt-get install -y sudo software-properties-common tzdata \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create user and configure permissions
RUN useradd -ms /bin/bash ${USER_NAME} && \
    mkdir -p ${HOME_DIR} && \
    chown -R ${USER_NAME}:${USER_NAME} ${HOME_DIR}  && \
    echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    usermod -aG sudo ${USER_NAME}

# Switch to the created user
USER ${USER_NAME}

# Install necessary dependencies
RUN sudo apt-get update && sudo apt-get install -y \
    git \
    unzip \
    wget \
    curl \
    gnupg \
    net-tools \
    openjdk-21-jre-headless \
    && sudo apt-get clean && sudo rm -rf /var/lib/apt/lists/*

# Verify Java installation
RUN java -version

# Download and configure Apache NiFi
RUN mkdir -p /tmp/nifi && \
    cd /tmp/nifi && \
    wget https://dlcdn.apache.org/nifi/${NIFI_VERSION}/nifi-${NIFI_VERSION}-bin.zip && \
    unzip nifi-${NIFI_VERSION}-bin.zip -d /tmp/nifi && \
    sudo mv /tmp/nifi/nifi-${NIFI_VERSION} ${NIFI_HOME} && \
    sudo ln -s ${NIFI_HOME} /opt/nifi && \
    sudo chown -R ${USER_NAME}:${USER_NAME} ${NIFI_HOME} && \
    sudo chmod +x ${NIFI_HOME}/bin/nifi.sh && \
    rm -rf /tmp/nifi

# Ensure nifi.sh is executable
RUN sudo chmod +x ${NIFI_HOME}/bin/nifi.sh

# Set the working directory
WORKDIR ${NIFI_HOME}/bin

# Add JAVA_HOME to nifi-env.sh
# RUN echo 'export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-arm64' | sudo tee -a /opt/nifi/bin/nifi-env.sh
RUN echo "export JAVA_HOME=${JAVA_HOME}" | sudo tee -a /opt/nifi/bin/nifi-env.sh

# Configure NiFi to listen on all interfaces
RUN sudo sed -i '/^nifi.web.https.host=/d' ${NIFI_HOME}/conf/nifi.properties && \
    echo 'nifi.web.https.host=0.0.0.0' | sudo tee -a ${NIFI_HOME}/conf/nifi.properties

EXPOSE 8443

# Command to run NiFi in the foreground
CMD ["./nifi.sh", "run"]
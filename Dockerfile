FROM ubuntu:22.04

# Define variables de entorno
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=America/Mexico_City \
    HOME_DIR=/home/developer \
    NIFI_VERSION=2.1.0 \
    NIFI_HOME=/opt/nifi \
    JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64

# Configura la zona horaria y actualiza el sistema
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    apt-get update && apt-get install -y \
        sudo \
        curl \
        git \
        unzip \
        wget \
        gnupg \
        software-properties-common \
        openjdk-21-jre-headless \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Verifica la instalación de Java
RUN java -version

# Crea el usuario 'developer' y configura el directorio home
RUN useradd -ms /bin/bash developer && \
    mkdir -p ${HOME_DIR} && \
    chown -R developer:developer ${HOME_DIR}

# Agrega permisos sudo sin contraseña para 'developer' (opcional)
RUN echo "developer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Descarga e instala Apache NiFi
RUN wget https://dlcdn.apache.org/nifi/${NIFI_VERSION}/nifi-${NIFI_VERSION}-bin.zip && \
    unzip nifi-${NIFI_VERSION}-bin.zip -d /opt && \
    rm nifi-${NIFI_VERSION}-bin.zip && \
    ln -s /opt/nifi-${NIFI_VERSION} ${NIFI_HOME} && \
    chown -R developer:developer ${NIFI_HOME} && \
    chmod +x ${NIFI_HOME}/bin/nifi.sh

# Cambia al usuario 'developer'
USER developer

# Establece el directorio de trabajo
WORKDIR ${NIFI_HOME}

# Expone los puertos necesarios para NiFi
EXPOSE 8080 8443

# Configura el Healthcheck para NiFi
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8080/nifi || exit 1

# Comando por defecto para ejecutar NiFi
CMD ["bin/nifi.sh", "run"]

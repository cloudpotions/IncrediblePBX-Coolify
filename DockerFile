# Use Ubuntu 22.04 as the base image
FROM ubuntu:22.04

# Set environment variables to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Update and install dependencies required for Incredible PBX
RUN apt-get update && apt-get install -y \
    wget \
    tar \
    nano \
    sudo \
    build-essential \
    openssh-server \
    apache2 \
    bison \
    flex \
    php \
    php-curl \
    php-cli \
    php-mysql \
    php-pear \
    php-gd \
    php-mbstring \
    php-intl \
    php-bcmath \
    curl \
    sox \
    libncurses5-dev \
    libssl-dev \
    mpg123 \
    libxml2-dev \
    libnewt-dev \
    sqlite3 \
    libsqlite3-dev \
    pkg-config \
    automake \
    libtool \
    autoconf \
    git \
    unixodbc-dev \
    uuid \
    uuid-dev \
    libasound2-dev \
    libogg-dev \
    libvorbis-dev \
    libicu-dev \
    libcurl4-openssl-dev \
    libical-dev \
    libneon27-dev \
    libsrtp2-dev \
    libspandsp-dev \
    subversion \
    libtool-bin \
    python2-dev \
    unixodbc \
    cron \
    dirmngr \
    sendmail-bin \
    sendmail \
    debhelper-compat \
    cmake \
    php-ldap \
    mailutils \
    dnsutils \
    apt-utils \
    dialog \
    linux-headers-$(uname -r) \
    libmariadb-dev \
    odbc-mariadb \
    && apt-get clean

# Install Node.js (required by some PBX components)
RUN curl -fsSL https://deb.nodesource.com/setup_14.x | bash - && \
    apt-get install -y nodejs && \
    node -v && npm -v

# Copy the installation script into the image
COPY IncrediblePBX2027-U.sh /root/IncrediblePBX2027-U.sh

# Make the script executable
RUN chmod +x /root/IncrediblePBX2027-U.sh

# Run the installation script
RUN /root/IncrediblePBX2027-U.sh

# Expose necessary ports
EXPOSE 80 443 5060-5061/udp 10000-20000/udp

# Start services (Apache, Asterisk) when the container is run
CMD service apache2 start && fwconsole start && tail -f /var/log/asterisk/full

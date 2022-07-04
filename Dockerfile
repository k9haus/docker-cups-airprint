FROM ubuntu:jammy

# Add repos
RUN echo 'deb http://us.archive.ubuntu.com/ubuntu/ jammy multiverse' >> /etc/apt/sources.list.d/multiverse.list && \
	echo 'deb-src http://us.archive.ubuntu.com/ubuntu/ jammy multiverse' >> /etc/apt/sources.list.d/multiverse.list && \
	echo 'deb http://us.archive.ubuntu.com/ubuntu/ jammy-updates multiverse' >> /etc/apt/sources.list.d/multiverse.list && \
	echo 'deb-src http://us.archive.ubuntu.com/ubuntu/ jammy-updates multiverse' >> /etc/apt/sources.list.d/multiverse.list && \
	echo 'deb http://archive.ubuntu.com/ubuntu/ jammy-security multiverse' >> /etc/apt/sources.list.d/multiverse.list && \
	echo 'deb-src http://archive.ubuntu.com/ubuntu/ jammy-security multiverse' >> /etc/apt/sources.list.d/multiverse.list

# Install the packages we need. Avahi will be included
RUN apt-get update && apt-get install -y \
	brother-lpr-drivers-extra brother-cups-wrapper-extra \
	cups \
	cups-pdf \
	inotify-tools \
	python3 \
	python3-cups \
&& rm -rf /var/lib/apt/lists/*

# Install custom DCP-T220 Drivers
RUN dpkg --add-architecture i386 && apt update && apt install -y wget \
&& wget https://download.brother.com/pub/com/linux/linux/packages/dcpt220pdrv-3.5.0-1.i386.deb \
&& wget https://download.brother.com/pub/com/linux/linux/packages/brscan5-1.2.10-0.amd64.deb \
&& wget https://download.brother.com/pub/com/linux/linux/packages/brscan-skey-0.3.1-2.amd64.deb \
&& dpkg -i *.deb

# This will use port 631
EXPOSE 631

# We want a mount for these
VOLUME /config
VOLUME /services

# Add scripts
ADD root /
RUN chmod +x /root/*
CMD ["/root/run_cups.sh"]

# Baked-in config file changes
RUN sed -i 's/Listen localhost:631/Listen 0.0.0.0:631/' /etc/cups/cupsd.conf && \
	sed -i 's/Browsing Off/Browsing On/' /etc/cups/cupsd.conf && \
	sed -i 's/<Location \/>/<Location \/>\n  Allow All/' /etc/cups/cupsd.conf && \
	sed -i 's/<Location \/admin>/<Location \/admin>\n  Allow All\n  Require user @SYSTEM/' /etc/cups/cupsd.conf && \
	sed -i 's/<Location \/admin\/conf>/<Location \/admin\/conf>\n  Allow All/' /etc/cups/cupsd.conf && \
	echo "ServerAlias *" >> /etc/cups/cupsd.conf && \
	echo "DefaultEncryption Never" >> /etc/cups/cupsd.conf


# References:
#   https://hub.docker.com/r/solarce/zoom-us
#   https://github.com/sameersbn/docker-skype
FROM debian:bullseye-slim
LABEL name="docker-zoom-us"

ENV DEBIAN_FRONTEND noninteractive

# Refresh package lists
RUN sed -i "s/\(^deb .* main\)/\1 contrib/" /etc/apt/sources.list
RUN apt-get update && \
	apt-get -qy dist-upgrade && \
	# Dependencies for the client .deb
	apt-get install -qy --no-install-recommends bind9-dnsutils bzip2 curl \
		ca-certificates sudo desktop-file-utils \
		iputils-ping iproute2 lib32z1 libx11-6 libegl1-mesa \
		libdbus-glib-1-2 libxcb-shm0 libglib2.0-0 libgl1-mesa-glx \
		libxrender1 libxcomposite1 libxslt1.1 libgstreamer1.0-0 \
		libgstreamer-plugins-base1.0-0 libxi6 libsm6 libfontconfig1 \
		libpulse0 libsqlite3-0 libxcb-shape0 libxcb-xfixes0 \
		libxcb-randr0 libxcb-image0 libxcb-keysyms1 libxcb-xtest0 \
		ibus ibus-gtk libxcb-xinerama0 libxkbcommon-x11-0 \
		libnss3 libxss1 xdg-utils xcompmgr procps pulseaudio \
		wget vim && \
	 apt-get clean -y && \
	 apt-get autoremove -y && \
	 rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt && \
	wget -O /opt/firefox-latest.tar.bz2 \
	    'https://download.mozilla.org/?product=firefox-latest&os=linux64&lang=en-US' && \
	tar -jxvf /opt/firefox-latest.tar.bz2 -C /opt/

ARG ZOOM_URL=https://zoom.us/client/latest/zoom_amd64.deb

# Grab the client .deb
# Install the client .deb
# Cleanup
RUN curl -sSL $ZOOM_URL -o /tmp/zoom_setup.deb && \
	dpkg -i /tmp/zoom_setup.deb && \
	apt-get -f install && \
		rm -rf /var/lib/apt/lists/* && \
	rm /tmp/zoom_setup.deb

COPY firefox.desktop /usr/share/applications/
COPY scripts/ /var/cache/zoom-us/
COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh

ENTRYPOINT ["/sbin/entrypoint.sh"]

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    apache2 \
    libapache2-mod-svn \
    subversion \
    apache2-utils \
    gettext-base \
    && a2enmod dav dav_svn auth_basic authn_file \
    && a2dissite 000-default \
    && rm -rf /var/lib/apt/lists/*

COPY conf/svn.conf.template /etc/apache2/sites-available/svn.conf.template
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]

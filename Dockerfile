FROM ubuntu:14.04

ENV LAST_UPDATED 20161021

# Install Percona Server, client, toolkit and xtrabackup.
RUN apt-get update && \
  apt-get -y --force-yes upgrade

# Installing Percona Server from Percona apt repository
RUN apt-get install -y --force-yes wget
RUN wget https://repo.percona.com/apt/percona-release_0.1-3.$(lsb_release -sc)_all.deb
RUN dpkg -i percona-release_0.1-3.$(lsb_release -sc)_all.deb
RUN apt-get update
RUN apt-get install -y --force-yes percona-server-server-5.6 percona-server-client-5.6 percona-toolkit percona-xtrabackup qpress

# Install autossh for permanent tunnel creation.
RUN apt-get install -y --force-yes autossh

# Empty mysql data dir, so that our init script can start from a clean slate
RUN rm -rf /var/lib/mysql/*

# Define mountable directories.
VOLUME ["/etc/mysql", "/var/lib/mysql", "/backups"]

# Add a default, tweaked mysql config. In production should be replaced by a mounted volume, with your own config managed by your orchestration solution (Chef, etc.)
ADD mysql/my.cnf /etc/mysql/my.cnf

ADD scripts/* /usr/bin/

# Define default command.
CMD ["mysqld_with_init"]

# Expose ports.
EXPOSE 3306
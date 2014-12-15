FROM dockerfile/ubuntu

# Install Percona Server, client & toolkit.
RUN \
  apt-key adv --keyserver keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A && \
  echo "deb http://repo.percona.com/apt `lsb_release -cs` main" > /etc/apt/sources.list.d/percona.list && \
  apt-get update && \
  apt-get install -y percona-server-server-5.6 percona-server-client-5.6 percona-toolkit

# Define mountable directories.
VOLUME ["/etc/mysql", "/var/lib/mysql"]

ADD scripts/mysqld /mysqld

# Define default command.
CMD ["/mysqld"]

# Expose ports.
EXPOSE 3306
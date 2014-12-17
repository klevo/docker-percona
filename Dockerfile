FROM dockerfile/ubuntu

# Install Percona Server, client & toolkit.
RUN \
  apt-key adv --keyserver keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A && \
  echo "deb http://repo.percona.com/apt `lsb_release -cs` main" > /etc/apt/sources.list.d/percona.list && \
  apt-get update && \
  apt-get install -y percona-server-server-5.6 percona-server-client-5.6 percona-toolkit percona-xtrabackup

# Define mountable directories.
VOLUME ["/etc/mysql", "/var/lib/mysql", "/backups"]

# Add a default, tweaked mysql config. In production should be replaced by a mounted volume, with your own config managed by your orchestration solution (Chef, etc.)
ADD mysql/my.cnf /etc/mysql/my.cnf

ADD scripts/create_my_root_cnf /create_my_root_cnf
ADD scripts/replication_master_sql /usr/bin/replication_master_sql
ADD scripts/replication_start /usr/bin/replication_start
ADD scripts/mysqld /mysqld

# Define default command.
CMD ["/mysqld"]

# Expose ports.
EXPOSE 3306
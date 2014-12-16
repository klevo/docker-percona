# Percona MySQL server with tools & shared volume initialization Dockerfile

Run a container:

```
docker run -d --name percona \
  -v /home/docker/percona-data:/var/lib/mysql \
  -e MYSQL_ROOT_PASSWORD=mypass \
  -p 3308:3306 \
  klevo/percona
```

Hot backup on a running container:

```
docker exec -i -t percona innobackupex /backups
docker exec -i -t percona innobackupex --apply-log /backups/2014-12-16_14-44-35
```
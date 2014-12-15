# Percona Data Only Container Dockerfile

To prepare the volume, just run this container once-off. It does not have to keep running.

```
docker run -v /containers/tmp/percona:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=mypass --name mysql_data klevo/percona_data
```

Then your can use a MySQL DB container with it.

```
docker run -d --volumes-from mysql_data --name mysql dockerfile/percona
```

To inspect the running mysql container:

```
docker exec -i -t mysql /bin/bash
```



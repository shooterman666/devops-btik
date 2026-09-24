## Container

```
docker run -d --name X image          # jalanin
docker ps / docker ps -a               # yg jalan / semua
docker stop X / docker start X
docker rm X / docker rm -f X           # hapus / stop+hapus
docker images / docker rmi image
```

## Masuk & lihat isi

```
docker exec -it X bash
docker exec X <command>
docker logs X / docker logs -f X
```

## Info & monitoring

```
docker inspect X
docker inspect --format '{{.NetworkSettings.Networks.bridge.IPAddress}}' X
docker stats
docker stats X --no-stream
```

## Volume

```
docker volume create nama
docker run -d --name X -v nama:/path image      # named volume
docker run -d --name X -v ~/folder:/path image   # bind mount
```

## Network

```
docker network ls
docker network create nama
docker run -d --name X --network host image
docker run -d --name X --network none image
docker run -d --name X --network nama image      # bisa saling curl pakai nama
```

## Restart policy

```
--restart no              # default
--restart always
--restart unless-stopped  # paling umum
--restart on-failure:3
```

## Resource limit

```
--memory="256m"
--cpus="0.5"
```

## 5 container test (contoh)

```
docker run -d --name c1-nginx --memory="128m" --cpus="0.3" nginx
docker run -d --name c2-redis --memory="64m" --cpus="0.2" redis
docker run -d --name c3-postgres --memory="256m" --cpus="0.5" -e POSTGRES_PASSWORD=test123 postgres
docker run -d --name c4-alpine --memory="32m" --cpus="0.1" alpine sleep 3600
docker run -d --name c5-busybox --memory="32m" --cpus="0.1" busybox sleep 3600
docker stats --no-stream
```
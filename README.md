## 👋 Welcome to wttr 🚀  

wttr README  
  
  
## Install my system scripts  

```shell
 sudo bash -c "$(curl -q -LSsf "https://github.com/systemmgr/installer/raw/main/install.sh")"
 sudo systemmgr --config && sudo systemmgr install scripts  
```
  
## Automatic install/update  
  
```shell
dockermgr update wttr
```
  
## Install and run container
  
```shell
dockerHome="/var/lib/srv/$USER/docker/casjaysdevdocker/wttr/wttr/latest/rootfs"
mkdir -p "/var/lib/srv/$USER/docker/wttr/rootfs"
git clone "https://github.com/dockermgr/wttr" "$HOME/.local/share/CasjaysDev/dockermgr/wttr"
cp -Rfva "$HOME/.local/share/CasjaysDev/dockermgr/wttr/rootfs/." "$dockerHome/"
docker run -d \
--restart always \
--privileged \
--name casjaysdevdocker-wttr-latest \
--hostname wttr \
-e TZ=${TIMEZONE:-America/New_York} \
-v "$dockerHome/data:/data:z" \
-v "$dockerHome/config:/config:z" \
-p 80:80 \
casjaysdevdocker/wttr:latest
```
  
## via docker-compose  
  
```yaml
version: "2"
services:
  ProjectName:
    image: casjaysdevdocker/wttr
    container_name: casjaysdevdocker-wttr
    environment:
      - TZ=America/New_York
      - HOSTNAME=wttr
    volumes:
      - "/var/lib/srv/$USER/docker/casjaysdevdocker/wttr/wttr/latest/rootfs/data:/data:z"
      - "/var/lib/srv/$USER/docker/casjaysdevdocker/wttr/wttr/latest/rootfs/config:/config:z"
    ports:
      - 80:80
    restart: always
```
  
## Get source files  
  
```shell
dockermgr download src casjaysdevdocker/wttr
```
  
OR
  
```shell
git clone "https://github.com/casjaysdevdocker/wttr" "$HOME/Projects/github/casjaysdevdocker/wttr"
```
  
## Build container  
  
```shell
cd "$HOME/Projects/github/casjaysdevdocker/wttr"
buildx 
```
  
## Authors  
  
🤖 casjay: [Github](https://github.com/casjay) 🤖  
⛵ casjaysdevdocker: [Github](https://github.com/casjaysdevdocker) [Docker](https://hub.docker.com/u/casjaysdevdocker) ⛵  

### Extensions
- YAML to JSON<br>
After creating yaml file, LMB - [Command Palette..] - search [convert]

### Django develop environment
- OS: Ubuntu
- Add current user to docker group

~~~
$ sudo groupadd docker
$ sudo usermod -aG docker $USER

$ groups obi
obi : obi adm cdrom sudo dip plugdev lpadmin lxd sambashare docker

$ getent group docker
docker:x:998:obi

### Reboot system
~~~

- config vs code<br>
Add extensions(Docker, Python, Remote - Containers)

### VScode from docker
- Link: https://hub.docker.com/r/codercom/code-server

~~~
$ docker pull docker pull codercom/code-server:3.10.2
$ docker run -it --name code-server -p 127.0.0.1:8080:8080 \
  -v "$HOME/.config:/home/coder/.config" \
  -v "$PWD:/home/coder/project" \
  -u "$(id -u):$(id -g)" \
  -e "DOCKER_USER=$USER" \
  codercom/code-server:latest
~~~

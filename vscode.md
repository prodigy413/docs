### Install vscode
https://code.visualstudio.com/Download

~~~
sudo apt install ./code_1.60.0-1630494279_amd64.deb
~~~

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
### Run vscode
$ docker pull docker pull codercom/code-server:3.10.2
$ docker run -it --name code-server -p 127.0.0.1:8080:8080 \
  -v "$HOME/.config:/home/coder/.config" \
  -v "$PWD:/home/coder/project" \
  -u "$(id -u):$(id -g)" \
  -e "DOCKER_USER=$USER" \
  codercom/code-server:latest
  
### Check password when config file is in container.
$ docker exec -it code-server bash
$ cat ~/.config/code-server/config.yaml
~~~

- Access from browser<br>
http://127.0.0.1:8080

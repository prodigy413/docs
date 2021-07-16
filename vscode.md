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

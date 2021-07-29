### Setup WSL2
- Link: https://docs.microsoft.com/en-us/windows/wsl/install-win10#manual-installation-steps
- Enable the Windows Subsystem for Linux & Virtual Machine feature

~~~
> dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
> dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
~~~

- Restart OS
- Download the Linux kernel update package and install<br>
https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi
- Set WSL 2 as your default version

~~~
> wsl --set-default-version 2
~~~

- Install your Linux distribution of choice<br>
https://aka.ms/wslstore<br>
Choose Ubuntu - [Get] - [Install] - [Launch] - Set username and password

### Control
- Refefence:<br>
https://pureinfotech.com/shutdown-wsl-2-linux-distros-windows-10/

~~~
### List all running WSL distros
> wsl --list --verbose

### Shutdown distros
> wsl -t distros

### Shutdown all distros
> wsl --shutdown

### Start or Restart distros
> wsl --distribution distros
~~~

# HMS Docker
Uses docker-compose to bring up the following containers to host an automated Plex server bundle:
- Plex
- Tautulli
- Ombi
- Sonarr
- Radarr
- Jackett
- Transmission/OpenVPN with a HTTP Proxy
- Reverse Proxy

## How it Works
On boot, the reverse proxy powered by ```jwilder/nginx-proxy``` obtains the IPs and hostnames of all running containers and builds a dynamic reverse proxy config that updates on container start and stop. The default assigned ```VIRTUAL_HOST``` values are ```<container_name>.${LOCALDOMAIN}``` where ```LOCALDOMAIN``` is defined in your ```.env``` file. Default is ```.local```. *(e.g. The sonarr container is ```sonarr.local``` and jackett would be ```jackett.local``` by default).*

**It is _highly_ recommended that you use a static IP for the docker host machine.**

You will need to update your DNS to point all A records for these hostnames towards the docker host IP, the reverse proxy will handle the rest by serving the data on port 80.



**If you _do not want_ to update your DNS**, you can still access the services by going to ```<docker host IP>:<port of service>```, or you can create a single "catch all" A record (e.g. ```hms-docker.local```) pointing towards the docker host IP and then specifying the port afterwards (```hms-docker.local:<port>```), the ports for services are listed below:

Service ports:
- Plex: 32400/web
- Tautulli: 8181
- Sonarr: 8989
- Radarr: 7878
- Ombi: 3579
- Jackett: 9117
- Transmission: 9091

Although it is device-specific, you can update your ```/etc/hosts``` file (or ```C:\Windows\System32\drivers\etc\hosts``` on Windows) with the format
```
...
<docker host IP>        <container_name>.${LOCALDOMAIN}
...
```
This will allow you to access the hostnames of the services by going to ```http://<container_name>:port``` or ```<container_name>:port/```.

Supported ```<container_name>```'s are:
- plex
- tautulli
- sonarr
- radarr
- ombi
- jackett
- transmission

Or you can create the single "catch all" record in this ```hosts``` file and just specify the port as mentioned above.

**A list of ```/etc/hosts``` entries will be generated after running ```setup.sh``` so you can easily copy and paste if you choose to go this route of updating your ```hosts``` file**

The Transmission container from ```haugene/docker-transmission-openvpn``` also includes an OpenVPN client as well as a HTTP proxy (running on port 8888 of the transmission container) for other containers to route traffic through the VPN. You can find all supported VPN providers and configurations at https://github.com/haugene/docker-transmission-openvpn.

## Usage
1. Define the path you want to use to store all data in ```.env``` (default is ```~/docker_data```).
2. Define the domain you want to use in the ```.env``` file under ```LOCALDOMAIN``` (default is ```.local```).
3. Input your VPN info under ```VPNUSER``` and ```VPNPASS``` in the ```.env``` file, as well as the ```VPNPROVIDER``` if your VPN subscription is supported. [Check here](https://github.com/haugene/docker-transmission-openvpn#supported-providers).
4. Visit https://plex.tv/claim to obtain your ```PLEX_CLAIM``` token and input this in the ```.env``` file.
5. Comment out or delete the ```NORDVPN``` environment entries under the ```transmission``` container if you do not use NordVPN.
6. Change your timezone in the ```.env``` if you are not in the ```America/New_York``` timezone.

To run in the background as detached after container startup:
```
$ docker-compose up -d
```

To run with container output for a bit of debugging:
```
$ docker-compose up
```

## Built With
- [jwilder/nginx-proxy](https://github.com/jwilder/nginx-proxy)
  - Provides the dynamic reverse proxy
- [haugene/docker-transmission-openvpn](https://github.com/haugene/docker-transmission-openvpn)
  - Provides Transmission, OpenVPN client, and the HTTP proxy that routes through the VPN.
- [linuxserver/sonarr](https://hub.docker.com/r/linuxserver/sonarr)
- [linuxserver/radarr](https://hub.docker.com/r/linuxserver/radarr)
- [linuxserver/jackett](https://hub.docker.com/r/linuxserver/jackett)
- [linuxserver/ombi](https://hub.docker.com/r/linuxserver/ombi)
- [plexinc/pms-docker](https://hub.docker.com/r/plexinc/pms-docker)
- [tautulli/tautulli](https://hub.docker.com/r/tautulli/tautulli)

## Acknowledgments
- Big thanks to [jwilder](https://github.com/jwilder), [haugene](https://github.com/haugene), and [linuxserver](https://www.linuxserver.io/) for making this project possible through the use of their containers.

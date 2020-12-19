###### This is my first time ever working with Docker and this size/complexity of bash script, pls be nice and help me learn the correct or more efficient way of doing things.

# HMS Docker
Uses docker-compose to bring up the following containers to host an orchestrated home media server:
- Plex
- Tautulli
- Ombi
- MySQL with Adminer
- Sonarr
- Radarr
- Jackett
- Transmission/OpenVPN with an HTTP Proxy
- Traefik
- Portainer
- Watchtower

## Getting Started with the setup script:
1. Define the path you want to use to store all data in the ```.env``` file after ```DATAFOLDER``` (default is ```/mnt/hms-docker_data```).
2. Define if you're using a network share or not by setting ```USINGNETWORKSHARE``` to ```true``` or ```false```.
3. Define the domain you want to use in the ```.env``` file under ```LOCALDOMAIN``` (default is ```.local```) and also in the ```traefik.toml``` where it says ```your-domain-here```.
4. Enter your email address in the ```traefik.toml``` where it says ```your-email-here``` so you can receive notifications for when your certificates are expiring.
5. Input your VPN info under ```VPNUSER``` and ```VPNPASS``` in the ```.env``` file, as well as the ```VPNPROVIDER``` if your VPN subscription is supported. [Click here to check supported VPN providers](https://github.com/haugene/docker-transmission-openvpn#supported-providers).
6. Declare any other VPN environment variables *(e.g. If using NordVPN, you can set the Country and Category with ```NORDVPN_COUNTRY=US``` and ```NORDVPN_CATEGORY=legacy_p2p```).*
7. Configure any additional Transmission environment variables you may want.
8. Define the ```NETWORKSHAREDRIVER```, currently only supports CIFS and NFS (ignored if ```USINGNETWORKSHARE=false```).
9. If using CIFS, define where you want the ```CREDENTIALFILE``` to go. *WARNING: only the user that runs the script will be able to access this file as it is stored in their home dir by default with permissions 0600*
10. If using NFS, define the ```NFSFOLDER``` and ```NFSOPTIONS``` (if any). If no options are defined, the ```/etc/fstab``` entry will use ```defaults``` when mounting on boot.
    - NFS users will also need to put in any sort of value for ```NETWORKSHAREUSER``` and ```NETWORKSHAREPASS```, I don't have handling for blank entries yet for these.
11. Visit https://plex.tv/claim to obtain your ```PLEX_CLAIM``` token and input this in the ```.env``` file.
12. Change your timezone in the ```.env``` if you are not in the ```America/New_York``` timezone.
13. Run ```setup.sh```, or just ```docker-compose up -d``` if you already have a docker environment that you prefer.

If this is a fresh install of Ubuntu 18.04, just run ```setup.sh``` and it'll automatically remove old versions of Docker (if installed), add GPG keys and new Docker repo and install Docker, install docker-compose, mount a network share (CIFS or NFS) on boot by adding to ```/etc/fstab```, also appends the IP and hostname of containers to ```/etc/hosts``` (if you enter Y when prompted).


## If you already have a Docker environment setup:
1. Modify the entries in .env as described above to adapt it to your environment (such as ```DATAFOLDER``` and ```LOCALDOMAIN```)
2. Copy the traefik.toml to ${DATAFOLDER}/traefik after modifying
3. To run in the background as detached after container startup:
```
$ docker-compose up -d
```
4. To run with container output for a bit of debugging (will kill containers on CTRL+C):
```
$ docker-compose up
```

## How it Works
On container boot, Traefik obtains the IPs and hostnames of all running containers and builds a dynamic reverse proxy config that updates on container start and stop. The default assigned hostname values are ```<container_name>.${LOCALDOMAIN}``` where ```LOCALDOMAIN``` is defined in your ```.env``` file. Default is ```.local```. *(e.g. The sonarr container would be ```sonarr.local``` and jackett would be ```jackett.local``` by default).*

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
- Portainer: 9000
- Traefik: 8080
- Adminer: 8082

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
- portainer
- traefik

Or you can create the single "catch all" record in this ```hosts``` file and just specify the port as mentioned above.

**You will be given the option to append these to your ```/etc/hosts``` file when running the script (only on Linux). Just enter Y or N when prompted. They will also be printed out so you can copy and paste if needed.**

The Transmission container from ```haugene/docker-transmission-openvpn``` also includes an OpenVPN client as well as a HTTP proxy (running on port 8888 of the transmission container) for other containers to route traffic through the VPN. You can find all supported VPN providers and configurations at https://github.com/haugene/docker-transmission-openvpn.

## How everything connects
- After port 80 is forwarded, update the DNS with your registrar to add a ```ombi.<TLD domain>``` that resolves to your IP so you can access ombi from anywhere thanks to the reverse proxy, along with any other containers you made available.
- Ombi sends any requests to Sonarr and Radarr, which contact Jackett to query a large number of trackers.
- Once a match is found, Sonarr and Radarr will determine if it should download it based on the quality profiles you specify and then send it off to Transmission to download.
- After it's done downloading/seeding, Sonarr or Radarr will link it to the Plex media folder and notify Ombi that it's ready on Plex.
- Tautulli is used for Plex analytics, such as which users have watched the most content, what kind of content, and a bunch of other useful data.

## Note about SSL Certs
Only the Ombi container will be given an SSL cert by default. This is because it is most likely the only container that will be exposed to the internet.
To change that, add/modify these lines to the label section of the container in the ```docker-compose.yml```:
```
- traefik.frontend.redirect.entryPoint=https
- traefik.frontend.headers.SSLRedirect=true
```
You may also need to update your ```traefik.toml``` file in ```${DATAFOLDER}/traeifik``` to get it to redirect to https every time.

## Built With
- [Traefik](https://hub.docker.com/_/traefik)
- [Watchtower](https://hub.docker.com/r/v2tec/watchtower/)
  - Automatically updates Docker containers when an update is released for the container image.
- [Portainer](https://hub.docker.com/r/portainer/portainer/)
  - Docker management tool
- [haugene/docker-transmission-openvpn](https://github.com/haugene/docker-transmission-openvpn)
  - Provides Transmission, OpenVPN client, and the HTTP proxy that routes through the VPN.
- [linuxserver/sonarr](https://hub.docker.com/r/linuxserver/sonarr)
- [linuxserver/radarr](https://hub.docker.com/r/linuxserver/radarr)
- [linuxserver/jackett](https://hub.docker.com/r/linuxserver/jackett)
- [linuxserver/ombi](https://hub.docker.com/r/linuxserver/ombi)
- [plexinc/pms-docker](https://hub.docker.com/r/plexinc/pms-docker)
- [tautulli/tautulli](https://hub.docker.com/r/tautulli/tautulli)

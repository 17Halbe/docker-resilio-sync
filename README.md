# docker-resilio-sync
A docker container providing a resilio instance using shared folders(no web-gui) for server use. Including a setup script.

The idea is to have a remote instance of a resilio client which is just providing files in a cloudlike way. Therefore we don't use a webclient but manage the synced folders via a setup script. Therefore reducing the attack vector on those files.
It is recommended to only use encrypted keys for this setup.

#Installation

`git clone https://github.com/17Halbe/docker-resilio-sync.git`

edit the `.env.dist` file to your needs and rename it to `.env`:
```
cp .env.dist .env
vi .env
docker-compose up
chmod +x setup.sh
./setup.sh
```

The synced folders reside in a volume named `syncdata` to facilitate backups. 
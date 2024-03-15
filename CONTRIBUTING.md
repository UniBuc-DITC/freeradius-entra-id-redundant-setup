# Contributing instructions

The setup in this repo is based on [Docker](https://www.docker.com/) and the [Docker Compose](https://docs.docker.com/compose/) plugin.

You can spin up the required containers by running:

```sh
docker compose up --build
```

This will (re)build the FreeRADIUS container image, download the PostgreSQL and Redis images and create/start instances of each. It will run forever. You can stop it by using the `Ctrl + C` / `Cmd + C` key combination or the equivalent on your system.

To check that the basic setup is working properly, in another terminal you can run:

```sh
./test-connection.sh
```

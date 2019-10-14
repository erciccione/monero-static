This is a simple dockerfile i use to build static binaries of the Monero daemon and wallet. It's a lighter and slightly edited version of the dockerfile contained in [the monero repo](). I removed some stuff i don't need (volumes, open ports, etc) and the dependencies related to hardware wallets.

To use it you only need docker installed on your system.

```
docker build . -t monero-static-docker
docker run -it --rm --name monero-static monero-static-docker
# copy the binaries from the container to your host system (run this command from outside your container)
docker cp monero-static:/home/monero/build/Linux/master/release/bin <DESTINATION FOLDER IN THE HOST SYSTEM>
# exit from the docker container
exit
```

The container will be destroyed right after we exit, but the `monero-static-docker` image is still there and contains the monero git repository with all the static dependencies already compiled. That means when the upstream repository gets updated, we can just create a container based on the image we built, pull the changes and build again. The process is:

```
# create a container based on the docker image, as we did above
docker run -it --rm --name monero-static monero-static-docker

# pull the changes from the monero repo
git pull

# build the new binaries
make clean
make release-static

# copy the binaries to the host machine
docker cp monero-static:/home/monero/build/Linux/master/release/bin <DESTINATION FOLDER IN THE HOST SYSTEM>
```
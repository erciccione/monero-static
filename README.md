This is a simple dockerfile i use to build static binaries of the Monero daemon and wallet. It's a lighter and slightly edited version of the dockerfile contained in [the monero repo](https://github.com/monero-project/monero/blob/master/Dockerfile). I removed some stuff which is not needed to build (volumes, open ports, etc) and the dependencies related to hardware wallets.

I find it very useful, because allow me to build the static environment and then I only need to pull the latest monero code and simply build again. I thought somebody else could find it useful for their needs, so here it is.

You only need docker installed on your system, then you can start:

```
  # Build the image and run it
docker build . -t monero-static-docker
docker run -it --rm --name monero-static monero-static-docker
  # Copy the binaries from the container to your host system (run this command from outside your container)
docker cp monero-static:/home/monero/build/Linux/master/release/bin <DESTINATION FOLDER IN THE HOST SYSTEM>
  # Exit from the docker container
exit
```

The container will be destroyed right after we leave it, but the `monero-static-docker` image is still there and contains the monero git repository with all the static dependencies already compiled. That means when the upstream repository gets updated, we can just create a container based on the image we already built, pull the changes and build Monero again. The process is:

```
  # Create a container based on the docker image, as we did before
docker run -it --rm --name monero-static monero-static-docker

  # Pull the changes from the monero repo
git pull

  # Build the new binaries
make clean
make release-static

  # Copy the binaries to the host machine
docker cp monero-static:/home/monero/build/Linux/master/release/bin <DESTINATION FOLDER IN THE HOST SYSTEM>
```

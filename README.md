This is a simple dockerfile i use to build static binaries of the Monero daemon and wallet. It's a lighter and slightly edited version of the dockerfile contained in [the monero repo](https://github.com/monero-project/monero/blob/master/Dockerfile). I removed some stuff which is not needed (volumes, open ports, etc) and the dependencies related to hardware wallets. If you need to use the binaries your hardware wallet, don't use this.

## Instructions

### 1. Install Docker
If possible, use your packaging system to get docker. For example, on Debain based distros docker can be installed by simply running `sudo apt install docker.io`

Take a look at [the official documentation](https://docs.docker.com/engine/install/) for details.

### 2. Clone this repository and navigate into the directory

```
git clone https://github.com/erciccione/monero-static-docker.git
cd monero-static-docker
```

### 3. Build the docker image and create a container based on it

```
docker build . -t monero-static-docker
```
This will take some time. Just sit back and wait until your computer is done compiling, then run the following command to create a container based on the docker image you just built. The binaries will be there, waiting to be copied to your system.
```
docker run -it --rm --name monero-static monero-static-docker
```


### 4. Copy the freshly built binaries to yur host system
Run this command from outside your container. Meaning you need to lunch another terminal window.
```
docker cp monero-static:/home/monero/build/Linux/master/release/bin <DESTINATION FOLDER IN THE HOST SYSTEM>
exit
```

The container will be destroyed right after we leave it, but the `monero-static-docker` image is still there and contains the monero git repository with all the static dependencies already compiled. That means when the upstream repository gets updated, we can just create a container based on the image we already built, pull the changes and build Monero again.

### Reuse the image everytime you want to make your own release

#### Create a container based on the docker image, as we did before
```
docker run -it --rm --name monero-static monero-static-docker
```
#### Pull the changes from the monero repo
```
cd monero && git pull
```

#### Build the new binaries
```
make clean
make release-static
```

#### Copy the binaries to the host machine
```
docker cp monero-static:/home/monero/build/Linux/master/release/bin <DESTINATION FOLDER IN THE HOST SYSTEM>
```

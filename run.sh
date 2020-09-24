#!/bin/bash

# TODO: Add GUI

runcontainer() {
  printf "\n-> Creating container...\n"
  docker run -it -d --name monero-static-container --net host --rm monero-static bash &> /dev/null
}

copy() {
  printf "\n-> Importing binaries...\n"
  docker cp $1 .
  printf "\n-> Binaries copied to 'bin' folder\n"
}

dexec() {
if docker exec -it monero-static-container bash -c "$1"; then
  printf "\n-> Done.\n"
else
  printf "\n-> Exiting...\n"
fi
}

build() {
  printf "\n-> Fetching code...\n"
  # getting last tag
  lastTag=$(docker exec -it monero-static-container bash -c 'cd monero && git pull --all &> /dev/null && git tag -l | sort -V | tail  -1')

  printf "\n-> What version do you want to build?\n"
  printf "\nmaster is bleeding edge and can contain bugs. Build the latest release if you are unsure.\n\n"
  printf "1) Build master"
  printf "\n2) Build latest release: $lastTag\n"
  printf "\nWhat do you want to do? (choose 1 or 2)\n"

  while true; do
    read version
    

    if [[ $version -eq 1 ]]; then
      printf "\n-> Building Master...\n"
      dexec "cd monero && git submodule update --init --force && make release-static"
      copy monero-static-container:/home/monero/build/Linux/master/release/bin
      break
    elif [[ $version -eq 2 ]]; then
      printf "\n-> Building release $lastTag\n"
      # ${lastTag::-1} is superugly
      dexec "cd monero && git checkout ${lastTag::-1} && git submodule update --init --force && make release-static"
      copy monero-static-container:/home/monero/build/Linux/_HEAD_detached_at_${lastTag::-1}_/release/bin
      break
    else
      printf "\nChoose 1 or 2\n"
    fi
  done
}

if ! docker images | grep "monero-static" &> /dev/null; then
  printf "\n-> Image not present. Building it...\n"
  docker build . -t monero-static
  runcontainer
  copy
else
  printf "\n-> Image found. Using it to build the container\n"
  runcontainer
  build
fi

# Brutally delete container
docker rm monero-static-container -f &> /dev/null
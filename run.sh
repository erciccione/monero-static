#!/bin/bash

runcontainer() {
  printf "\n-> Creating container...\n"
  docker run -it -d --name monero-static-container --net host --rm monero-static bash &> /dev/null
}

copy() {
  printf "\n-> Importing binaries...\n"
  docker cp monero-static-container:/home/monero/build/Linux/master/release/bin .
  printf "\n-> Binaries copied to 'bin' folder\n"
}

dexec() {
if docker exec -it monero-static-container bash -c "$1"; then
  printf "\n-> Done.\n"
  copy
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
      sleep 2
      dexec "cd monero && make release-static"
      break
    elif [[ $version -eq 2 ]]; then
      printf "\n-> Building release $lastTag\n"
      sleep 2
      # ${lastTag::-1} is superugly
      dexec "cd monero && git checkout ${lastTag::-1} && make release-static"
      break
    else
      printf "\nChoose 1 or 2\n"
    fi
    # Copy the binaries
    copy

  done
}


if ! docker images | grep "monero-static" &> /dev/null; then
  printf "\n-> Image not present. Building it...\n"
  sleep 2
  docker build . -t monero-static
  runcontainer
  copy
else
  printf "\n-> Image found. Using it to build the container\n"
  sleep 2
  runcontainer
  build
fi

# Brutally delete container
docker rm monero-static-container -f &> /dev/null
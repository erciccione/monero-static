#!/bin/bash

# TODO: Add GUI
# TODO: add checks: docker installed, dependencies (git, curl, jq)

# We always delete the container when exiting. This also avoids having orphan containers in case of SIGTERM
trap "printf '\n-> Exiting\n' ; docker rm -f monero-static-container &> /dev/null" EXIT

runcontainer() {
  # Start detached container to make it available for successive commands. We use '--net host' to avoid possible issues with VPNs or network configurations.
  printf "\n-> Creating container...\n"
  docker run -it -d --name monero-static-container --net host --rm monero-static bash &> /dev/null
}

# Get latest tag
get_tag() {
  tag=$(curl -s -o- https://api.github.com/repos/monero-project/monero-gui/releases/latest | jq -r '.tag_name') || exit
}

get_build() {

  printf "\nWhat version do you want to build?\n"
  printf "\nmaster is bleeding edge and can contain bugs.\nBuild the latest release if you are unsure.\n\n"
  printf "1) Build master"
  printf "\n2) Build latest release: $tag\n"
  leaveready="\nWhat do you want to do? Choose 1 or 2.\nPress ctrl + c or type 'exit' if you want to leave:\n"
  printf "$leaveready"

  while true; do
    read version

    if [[ $version -eq 1 ]] || [[ $version -eq 2 ]]; then
      break
    elif [[ $version -eq "exit" ]]; then
      exit
    else
      printf "$leaveready"
    fi
  done
}

build() {

  dexec() {
  docker exec -it monero-static-container bash -c "$1" || exit
  }

  copy() {
  printf "\n-> Importing binaries..."
  docker cp $1 . && printf "\n-> Binaries copied to 'bin' folder in " && pwd || printf "\n-> Something went wrong, binaries not copied" && exit
  }

  if [[ $version -eq 1 ]]; then
    printf "\n-> Building Master...\n"
    dexec "git pull && git submodule update --init --force && make release-static"
    copy monero-static-container:/home/monero/build/Linux/master/release/bin
  elif [[ $version -eq 2 ]]; then
    printf "\n-> Building release $tag\n"
    dexec "git pull --all && git checkout ${tag} &> /dev/null && git submodule update --init --force && make release-static -j3"
    copy monero-static-container:/home/monero/build/Linux/_HEAD_detached_at_${tag}_/release/bin
  fi
}


# Introduction with Monero logo
cat << "EOF"

    .-----------------------------------------.
    |              MONERO STATIC              |
    '-----------------------------------------'
                'r1kWQ@@@@@@QWE]r'                
            `^XQ@@@@@@@@@@@@@@@@@@QX*`            
          ~e@@@@@@@@@@@@@@@@@@@@@@@@@@k~          
        '9@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@9,        
       i@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@i       
      S@@@@1;O@@@@@@@@@@@@@@@@@@@@@@R;\@@@@k      
     u@@@@@1  _O@@@@@@@@@@@@@@@@@@O_  |@@@@@u     
    ,@@@@@@1    ,k@@@@@@@@@@@@@@k_    |@@@@@@,    
    o@@@@@@1      'e@@@@@@@@@@e,      |@@@@@@o    
    g@@@@@@1        'y@@@@@@e'        |@@@@@@W    
    g@@@@@@1   `u:    -x@@y-    :]`   |@@@@@@W    
    o@@@@@@1   `mwS;    ``    ;uwX`   |@@@@@@o    
    ,@@@@@@1   `mXXXS^      ;SXXXX`   |@@@@@@,    
     ''''''`   `mXXXXwar``^awXXXXX`   `''''''     
               `mXXXXXXXeeXXXXXXXX`               
       ,z{{{{{{]wXXXXXXXXXXXXXXXXX]{{{{{{1,       
        `LwXXXXXXXXXXXXXXXXXXXXXXXXXXXXwL-        
          '|eXXXXXXXXXXXXXXXXXXXXXXXXe\'          
             _\oXXXXXXXXXXXXXXXXXXo\:             
                `:^\1uZmXXmZj1\^:-            
    .------------------------------------------.
    |       Build your own Monero Release      |
    |             - By ErCiccione -            |
    '------------------------------------------'                                                                          
EOF

# Main

if ! docker images | grep "monero-static" &> /dev/null; then
  printf "This is your first time using Monero Static, Welcome!"
  printf "\nNow we prepare the environment where your release will"
  printf "\nbe compiled, after you will have to choose if you want to"
  printf "\nbuild master (the latest code) or the latest tag (last"
  printf "\nworking code meant to be released).\n"
  printf "\nGet yourself a coffee, this will take some time.\n"

  printf "\n-> Building the Docker image...\n"
  get_tag
  get_build
  docker build . -t monero-static || exit
  runcontainer
  build
else
  printf "Welcome back! I'm about to create your Monero CLI release.\n"
  get_tag
  get_build
  runcontainer
  build
fi
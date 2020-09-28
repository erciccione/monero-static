#!/bin/bash

# TODO: Add GUI

runcontainer() {
  printf "\n-> Creating container...\n"
  docker run -it -d --name monero-static-container --net host --rm monero-static bash &> /dev/null
}

copy() {
  printf "\n-> Importing binaries...\n"
  docker cp $1 . || printf "\n-> Something went wrong, binaries not copied" && exit
  printf "\n-> Binaries copied to 'bin' folder in " && pwd
}

dexec() {
  docker exec -it monero-static-container bash -c "$1" || exit
}

build() {
  printf "\n-> Fetching code...\n"
  # getting last tag
  lastTag=$(docker exec -it monero-static-container bash -c 'cd monero && git pull --all &> /dev/null && git tag -l | sort -V | tail  -1') || exit

  printf "\n-> What version do you want to build?\n"
  printf "\nmaster is bleeding edge and can contain bugs. Build the latest release if you are unsure.\n\n"
  printf "1) Build master"
  printf "\n2) Build latest release: $lastTag\n"
  printf "\nWhat do you want to do? (Choose 1 or 2. Press ctrl + c or type 'exit' if you want to leave)\n"

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
    elif [[ $version -eq "exit" ]]; then
      exit
    else
      printf "\nChoose 1 or 2. Press ctrl + c or type 'exit' if you want to leave\n"
    fi
  done
}


trap "printf '\n-> Exiting\n' ; docker rm -f monero-static-container &> /dev/null" EXIT

cat << "EOF"

    .-----------------------------------------.
    |              MONERO STATIC              |
    |                   v1.0                  |
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

if ! docker images | grep "monero-static" &> /dev/null; then
  printf "This is your first time using Monero Static, Welcome!"
  printf "\nYou don't have to do anything. I'm about to build the latest Monero CLI software"
  printf "\nand copy it inside a 'bin' folder. Get yourself a cofee, this will take some time.\n"
  sleep 5

  printf "\n-> Building the Docker image...\n"
  docker build . -t monero-static || exit
  runcontainer
  copy
else
  printf "Welcome back! I'm about to create your Monero CLI release.\n"
  runcontainer
  build
fi

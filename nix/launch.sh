#!/usr/bin/env bash

host_init=oracle-km1-1-init
hosts=("oracle-km1-1" "contabo-1" "oracle-bv1-1")
inventory="../inventory.yml"

bootstrap(){
    nixos-rebuild switch --flake ~/git/kubernetes/fluxcd#$host_init --target-host oracle-km1-1 # TODO make this index of hosts [0]
}
prepare_token_rke2(){
    # while true; do
        echo "running token"
        for host in "${hosts[@]}"; do
            # ssh $host "mkdir -p /etc/rancher/rke2/"
            scp /home/bocmo/.ssh/token $host:/var/token
        done
        # sleep 2
    # done
}
update(){
    echo "running switch"
    for host in "${hosts[@]}"; do
        nixos-rebuild switch --flake ~/git/kubernetes/fluxcd#$host --target-host $host
        if [ $? -eq 0 ]; then
            echo "Command executed successfully."
        else
            echo "Command failed."
            exit
        fi
    done
}
try_update(){
    echo "running test"
    for host in "${hosts[@]}"; do
        nixos-rebuild test --flake ~/git/kubernetes/fluxcd#$host --target-host $host
        if [ $? -eq 0 ]; then
            echo "Command executed successfully."
        else
            echo "Command failed."
            exit
        fi
    done
}
build(){
    echo "running builds"
    for host in "${hosts[@]}"; do
        nixos-rebuild build --flake ~/git/kubernetes/fluxcd#$host --target-host $host
        if [ $? -eq 0 ]; then
            echo "Command executed successfully."
        else
            echo "Command failed."
            exit
        fi
    done
}
wg-mesh(){
    cd vxlan-wireguard-mesh
	ansible-playbook wireguard.yml -i $inventory
    echo "sleeping before ping"
    sleep 15
	ansible-playbook ping.yml -i $inventory
    cd ../
}
vxlan-mesh(){
    cd vxlan-wireguard-mesh
	ansible-playbook vxlan_systemd.yml -i $inventory
    echo "sleeping before ping"
    sleep 5
	ansible-playbook ping_vxlan.yml -i $inventory
    cd ../
}
if [[ $1 == test ]]; then
    build
    prepare_token_rke2
    try_update
elif [[ $1 == wg-mesh ]]; then
    wg-mesh
    exit
elif [[ $1 == mesh ]]; then
    wg-mesh
    vxlan-mesh
    exit
elif [[ $1 == build ]]; then
    build
elif [[ $1 == deploy ]]; then
    build
    prepare_token_rke2
    try_update
    update
elif [[ $1 == switch ]]; then
    build
    prepare_token_rke2
    # prepare_token_rke2 &
    # TOKEN_PID=$!
    # kill $TOKEN_PID
    # wait $TOKEN_PID
    try_update
    update
elif [[ $1 == token ]]; then
    prepare_token_rke2
elif [[ $1 == service_restart ]]; then
    echo "restarting services"
    for host in "${hosts[@]}"; do
        echo restarting $host
        ssh $host "systemctl restart rke2-server.service"
    done
elif [[ $1 == deploy_all ]]; then
    echo "wg-mesh step"
    wg-mesh
    echo "build step"
    build
    echo "token step"
    prepare_token_rke2
    echo "try update step"
    try_update
    echo "atempting update step"
    bootstrap
    update
    echo "atempting vxlan meshing"
    vxlan-mesh
    echo "done step"
    exit
fi




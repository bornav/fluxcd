#!/usr/bin/env bash
prepare(){
    cd custom
    ansible-playbook prepare-cloud.yaml -i ../wireguard-mesh/automation-wireguard/inventories/inventory.yml
    cd ..
}
wg-mesh(){
    cd wireguard-mesh/automation-wireguard
	ansible-playbook wireguard.yml -i "inventories/inventory.yml"
	ansible-playbook ping.yml -i "inventories/inventory.yml"
    cd ../../
}
deploy(){
    cd k3s-ansible
    /usr/bin/env bash ./deploy.sh
    cd ..
}
reset(){
    cd k3s-ansible
    /usr/bin/env bash ./reset.sh
    cd ..
}
if [[ $1 == prepare ]]; then
    prepare
elif [[ $1 == wg-mesh ]]; then
    wg-mesh
    exit
elif [[ $1 == deploy ]]; then
    deploy
    exit
elif [[ $1 == reset ]]; then
    reset
    exit
elif [[ $1 == deploy-all ]]; then
    prepare
    wg-mesh
    deploy
fi




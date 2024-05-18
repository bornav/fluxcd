#!/usr/bin/env bash
clone(){
    git clone https://github.com/jawher/automation-wireguard.git
    git clone https://github.com/techno-tim/k3s-ansible.git
}

prepare-inv(){
    cp hosts-all.yaml k3s-ansible/inventory/sample/hosts.yaml
    cp hosts-all.yaml automation-wireguard/inventories/inventory.yml
    cp k3s-ansible/ansible.example.cfg k3s-ansible/ansible.cfg
    sed -i '/^inventory/ s/.*/inventory = inventory\/sample\/hosts.yaml/' k3s-ansible/ansible.cfg
    mkdir -p k3s-ansible/inventory/sample
    cp -r group_vars k3s-ansible/inventory/sample/
}

prepare-sys(){
    cd custom
    ansible-playbook prepare-cloud.yaml -i hosts-all.yaml
    cd ..
}
wg-mesh(){
    cd automation-wireguard
	ansible-playbook wireguard.yml -i "inventories/inventory.yml"
	ansible-playbook ping.yml -i "inventories/inventory.yml"
    cd ../
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
cleanup(){
    rm -rf k3s-ansible
    rm -rf automation-wireguard
}
if [[ $1 == prepare-sys ]]; then
    prepare-sys
elif [[ $1 == wg-mesh ]]; then
    wg-mesh
    exit
elif [[ $1 == deploy ]]; then
    deploy
    exit
elif [[ $1 == reset ]]; then
    reset
    cleanup
    exit
elif [[ $1 == clone ]]; then
    clone
    exit
elif [[ $1 == prepare ]]; then
    prepare-inv
    prepare-sys
    exit
elif [[ $1 == deploy-all ]]; then
    clone
    prepare-inv
    prepare-sys
    wg-mesh
    deploy
elif [[ $1 == redeploy-all ]]; then
    clone
    prepare-inv
    wg-mesh
    deploy
elif [[ $1 == reset-deploy-all ]]; then
    reset
    prepare-inv
    prepare-sys
    wg-mesh
    deploy
fi




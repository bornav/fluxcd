#/bin/sh
#example deploy simple cluster: BOOTSTRAP=true SIMPLE=true ./launch.sh
#example nuke existing cluster: ~any~ ./launch.sh RESET
export ANSIBLE_HOST_KEY_CHECKING=false
host_location="./external/my-cluster/hosts.ini"
reset(){
    decrypt
    git clone --branch v1.25.9+k3s1 https://github.com/techno-tim/k3s-ansible
    cat k3s-ansible/ansible.example.cfg > k3s-ansible/ansible.cfg
    sed -i 's#^inventory = .*#inventory = ../external/my-cluster/hosts.ini#' k3s-ansible/ansible.cfg
    sed -i 's#^ansible-playbook site.yml$#ansible-playbook site.yml -e "@../external/my-cluster/group_vars/.decrypted~encrypted.yaml" -e "@../vars/.decrypted~vars-protected.yaml"#' k3s-ansible/deploy.sh
    cd k3s-ansible
    ansible-playbook reset.yml -e "@../external/my-cluster/group_vars/.decrypted~encrypted.yaml" -e "@../vars/.decrypted~vars-protected.yaml" $DBG
    cd ..
}
bootstrap(){
    decrypt
    cd ../../
    chmod +x ./kubernetes/bootstrap/bootstrap.sh
    kubectl apply --server-side --kustomize ./kubernetes/bootstrap/flux
    sops --decrypt kubernetes/bootstrap/flux/age-key.sops.yaml | kubectl apply -f -
    sops --decrypt kubernetes/bootstrap/flux/github-ssh-key.sops.yaml | kubectl apply -f -
    sops --decrypt kubernetes/bootstrap/flux/github-token.sops.yaml | kubectl apply -f -
    kubectl apply -f kubernetes/flux/vars/cluster-settings.yaml
    kubectl apply --server-side --kustomize ./kubernetes/flux/config
    cd deployment/ansible
    rm_secrets

}
kube_config(){
    decrypt
    ansible-playbook ./playbook/update_kube_config.yaml -i $host_location -e "@./vars/vars.yaml" -e "@./vars/.decrypted~vars-protected.yaml" $DBG
    rm_secrets
}
decrypt(){
    sops --decrypt ./vars/vars-protected.yaml > ./vars/.decrypted~vars-protected.yaml
    sops --decrypt ./external/my-cluster/group_vars/encrypted.yaml > ./external/my-cluster/group_vars/.decrypted~encrypted.yaml
    sops --decrypt ./vars/netmaker.env > ./vars/.decrypted~netmaker.env
}
rm_secrets(){
if [ "$(find . -type f | grep -i ".decrypted" | wc -l)" -gt 0 ]; then
  find . -type f | grep -i .decrypted | xargs rm
else
  echo no secrets found
  break
fi
}
k3s_install(){
    git clone --branch v1.25.9+k3s1 https://github.com/techno-tim/k3s-ansible
    cat k3s-ansible/ansible.example.cfg > k3s-ansible/ansible.cfg
    sed -i 's#^inventory = .*#inventory = ../external/my-cluster/hosts.ini#' k3s-ansible/ansible.cfg
    sed -i 's#^ansible-playbook site.yml$#ansible-playbook site.yml -e "@../external/my-cluster/group_vars/.decrypted~encrypted.yaml" -e "@../vars/.decrypted~vars-protected.yaml"#' k3s-ansible/deploy.sh
    cd k3s-ansible
    ansible-galaxy install -r ./collections/requirements.yml
    ./deploy.sh
    cd ..
}
simple_install(){
    ansible-playbook ./playbook/simple_k3s_install.yaml -i $host_location $DBG
    
}
netmaker_install(){
    decrypt
    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook ./playbook/netmaker-install.yaml -i $host_location -e "@./vars/vars.yaml" -e "@./vars/.decrypted~vars-protected.yaml" $DBG
}
forward(){
    decrypt
    ansible-playbook ./playbook/forwarding.yaml -i $host_location -e "@./vars/vars.yaml" $DBG
}
forward_clean(){
    decrypt
    ansible-playbook ./playbook/forwarding-clean.yaml -i $host_location -e "@./vars/vars.yaml" $DBG
}
prepare(){
    decrypt
    ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook ./playbook/prepare-cloud.yaml -i $host_location -e "@./vars/vars.yaml" -e "@./vars/.decrypted~vars-protected.yaml" -e ansible_user=ubuntu $DBG
}
forward_traffic(){
    ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook ./playbook/add-startup-task.yaml -i $host_location -e "@./vars/vars.yaml" -e "@./vars/.decrypted~vars-protected.yaml"
}
test(){ #this is a test funtion for rapid testing
    ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook ./playbook/add-startup-task.yaml -i $host_location -e "@./vars/vars.yaml" -e "@./vars/.decrypted~vars-protected.yaml"
    echo ""
}
if [ -z "$DEBUG" ];then
    break
else
    echo "DEBUG MODE SELECTED"
    DBG="-vvv"
fi

if [ -z "$1" ];then
    break
elif [[ $1 == NETMAKER ]]; then
    netmaker_install
    exit
elif [[ $1 == TEST ]]; then
    test
    exit
elif [[ $1 == RESET ]]; then
    reset
    exit
elif [[ $1 == DECRYPT ]]; then
    decrypt
    exit
elif [[ $1 == CONFIG ]]; then
    kube_config
    exit
elif [[ $1 == PREPARE ]]; then
    prepare #not work
    exit
elif [[ $1 == BOOTSTRAP ]]; then
    bootstrap
    exit
elif [[ $1 == FORWARD ]]; then
    forward
    exit
elif [[ $1 == FORWARD_CLEAN ]]; then
    forward_clean
    exit
elif [[ $1 == FORWARD_TRAFFIC ]]; then
    forward_traffic
    exit
elif [[ $1 == RERE ]]; then
    reset
elif [[ $CLEAN_VIRT == true ]]; then
    ~/scripts/snapshot_revert.sh 
    # while ! ping -c 1 -n -w 1 k8s-01 &> /dev/null
    # do
    #     printf "%c" "."
    # done
else 
    echo "input command unrecognized, exiting"
    exit 1
fi
prepare



#rm_secrets
#rm -rf k3s-ansible
#rm ./vars/.decrypted~vars-protected.yaml ./external/my-cluster/group_vars/.decrypted~encrypted.yaml

if [[ $FRESH == true ]]; then
    reset
fi
if [[ $SIMPLE != true ]]; then
    k3s_install
else
    simple_install
fi
if [[ $CONFIG == true ]]; then
    kube_config
fi

if [[ $BOOTSTRAP == true ]]; then
    kube_config
    bootstrap
    forward_traffic
fi


# clean

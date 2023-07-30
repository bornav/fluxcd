#/bin/sh
#example deploy simple cluster: BOOTSTRAP=true SIMPLE=true ./launch.sh
#example nuke existing cluster: ~any~ ./launch.sh RESET
reset(){
    decrypt
    git clone --branch v1.25.9+k3s1 https://github.com/techno-tim/k3s-ansible
    cat k3s-ansible/ansible.example.cfg > k3s-ansible/ansible.cfg
    sed -i 's#^inventory = .*#inventory = ../external/my-cluster/hosts.ini#' k3s-ansible/ansible.cfg
    sed -i 's#^ansible-playbook site.yml$#ansible-playbook site.yml -e "@../external/my-cluster/group_vars/.decrypted~encrypted.yaml" -e "@../vars/.decrypted~vars-protected.yaml"#' k3s-ansible/deploy.sh
    cd k3s-ansible
    ansible-playbook reset.yml -e "@../external/my-cluster/group_vars/.decrypted~encrypted.yaml" -e "@../vars/.decrypted~vars-protected.yaml"
    cd ..
}
bootstrap(){
    cd ../../
    chmod +x ./kubernetes/bootstrap/bootstrap.sh
    kubectl apply --server-side --kustomize ./kubernetes/bootstrap/flux
    sops --decrypt kubernetes/bootstrap/flux/age-key.sops.yaml | kubectl apply -f -
    sops --decrypt kubernetes/bootstrap/flux/github-ssh-key.sops.yaml | kubectl apply -f -
    sops --decrypt kubernetes/bootstrap/flux/github-token.sops.yaml | kubectl apply -f -
    kubectl apply -f kubernetes/flux/vars/cluster-settings.yaml
    kubectl apply --server-side --kustomize ./kubernetes/flux/config
    cd deployment/ansible
}
kube_config(){
    decrypt
    ansible-playbook ./playbook/update_kube_config.yaml -i ./inventory/hosts.ini -e "@./vars/vars.yaml" -e "@./vars/.decrypted~vars-protected.yaml"
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
    ansible-playbook ./playbook/simple_k3s_install.yaml -i ./inventory/hosts.ini
    
}
netmaker_install(){
    decrypt
    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook ./playbook/netmaker-install.yaml -i ./inventory/hosts.ini -e "@./vars/vars.yaml"  
}
if [[ $1 == NETMAKER ]]; then
    netmaker_install
    exit
fi
if [[ $1 == RESET ]]; then
    reset
    exit
fi
if [[ $1 == DECRYPT ]]; then
    decrypt
    exit
fi
if [[ $1 == CONFIG ]]; then
    kube_config
    exit
fi
if [[ $1 == BOOTSTRAP ]]; then
    bootstrap
    exit
fi
if [[ $CLEAN_VIRT == true ]]; then
    ~/scripts/snapshot_revert.sh 
    # while ! ping -c 1 -n -w 1 k8s-01 &> /dev/null
    # do
    #     printf "%c" "."
    # done
fi
decrypt
ansible-playbook ./playbook/prepare-cloud.yaml -i ./inventory/hosts.ini -e "@./vars/vars.yaml" -e "@./vars/.decrypted~vars-protected.yaml"



#rm_secrets
#rm -rf k3s-ansible
#rm ./vars/.decrypted~vars-protected.yaml ./external/my-cluster/group_vars/.decrypted~encrypted.yaml

if [[ $FRESH == true ]]; then
    reset
fi
if [[ $SIMPLE != true ]]; then
    k3s_install
fi
if [[ $SIMPLE == true ]]; then
    simple_install
fi
if [[ $CONFIG == true ]]; then
    kube_config
fi

if [[ $BOOTSTRAP == true ]]; then
    kube_config
    bootstrap
fi

# clean

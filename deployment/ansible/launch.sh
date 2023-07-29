#/bin/sh
#SSH KEY
#ansible-playbook ./playbook/purge-net-blockers.yaml --user bocmo --ask-pass --ask-become-pass -i ./inventory/hosts
reset(){
    decrypt
    git clone --branch v1.25.9+k3s1 https://github.com/techno-tim/k3s-ansible
    cat k3s-ansible/ansible.example.cfg > k3s-ansible/ansible.cfg
    sed -i 's#^inventory = .*#inventory = ../external/my-cluster/hosts.ini#' k3s-ansible/ansible.cfg
    sed -i 's#^ansible-playbook site.yml$#ansible-playbook site.yml -e "@../external/my-cluster/group_vars/.decrypted~encrypted.yaml" -e "@../vars/.decrypted~vars-protected.yaml"#' k3s-ansible/deploy.sh
    cd k3s-ansible
    ansible-playbook reset.yml -e "@../external/my-cluster/group_vars/.decrypted~encrypted.yaml" -e "@../vars/.decrypted~vars-protected.yaml"
    cd ..
    exit
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
    ansible-playbook ./playbook/update_kube_config.yaml -i ./inventory/hosts -e "@./vars/vars.yaml" -e "@./vars/.decrypted~vars-protected.yaml"
    rm_secrets
}
decrypt(){
sops --decrypt ./vars/vars-protected.yaml > ./vars/.decrypted~vars-protected.yaml
sops --decrypt ./external/my-cluster/group_vars/encrypted.yaml > ./external/my-cluster/group_vars/.decrypted~encrypted.yaml
}
rm_secrets(){
find | grep -i .decrypted | xargs rm
}
if [[ $1 == FRESH ]]; then
    reset
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
ansible-playbook ./playbook/prepare-cloud.yaml -i ./inventory/hosts -e "@./vars/vars.yaml" -e "@./vars/.decrypted~vars-protected.yaml"


git clone --branch v1.25.9+k3s1 https://github.com/techno-tim/k3s-ansible
cat k3s-ansible/ansible.example.cfg > k3s-ansible/ansible.cfg
sed -i 's#^inventory = .*#inventory = ../external/my-cluster/hosts.ini#' k3s-ansible/ansible.cfg
sed -i 's#^ansible-playbook site.yml$#ansible-playbook site.yml -e "@../external/my-cluster/group_vars/.decrypted~encrypted.yaml" -e "@../vars/.decrypted~vars-protected.yaml"#' k3s-ansible/deploy.sh


cd k3s-ansible
ansible-galaxy install -r ./collections/requirements.yml
./deploy.sh
cd ..

#rm_secrets
#rm -rf k3s-ansible
#rm ./vars/.decrypted~vars-protected.yaml ./external/my-cluster/group_vars/.decrypted~encrypted.yaml
if [[ $CONFIG == true ]]; then
    kube_config
fi

if [[ $BOOTSTRAP == true ]]; then
    kube_config
    bootstrap
fi

# clean

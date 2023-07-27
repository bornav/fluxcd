#/bin/sh
#SSH KEY
#ansible-playbook ./playbook/purge-net-blockers.yaml --user bocmo --ask-pass --ask-become-pass -i ./inventory/hosts
if [[ $CLEAN != false ]]; then
    ~/scripts/snapshot_revert.sh 
    # while ! ping -c 1 -n -w 1 k8s-01 &> /dev/null
    # do
    #     printf "%c" "."
    # done
fi
sops --decrypt ./vars/vars-protected.yaml > ./vars/.decrypted~vars-protected.yaml
ansible-playbook ./playbook/prepare-cloud.yaml -i ./inventory/hosts -e "@./vars/vars.yaml" -e "@./vars/.decrypted~vars-protected.yaml"
#ansible-playbook ./playbook/prepare.yaml -i ./inventory/hosts -e "@./vars/vars.yaml" -e "@./vars/.decrypted~vars-protected.yaml"
# ansible-playbook ./playbook/add-ssh-keys.yaml -i ./inventory/hosts -e "@./vars/vars.yaml" -e "@./vars/.decrypted~vars-protected.yaml"
# ansible-playbook ./playbook/create-user.yaml -i ./inventory/hosts -e "@./vars/vars.yaml" -e "@./vars/.decrypted~vars-protected.yaml"


git clone --branch v1.25.9+k3s1 https://github.com/techno-tim/k3s-ansible
cat k3s-ansible/ansible.example.cfg > k3s-ansible/ansible.cfg
sed -i 's#^inventory = .*#inventory = ../external/my-cluster/hosts.ini#' k3s-ansible/ansible.cfg
sops --decrypt ./external/my-cluster/group_vars/encrypted.yaml > ./external/my-cluster/group_vars/.decrypted~encrypted.yaml
#sed -i 's#^ansible-playbook site.yml$#ansible-playbook site.yml -e "@../external/my-cluster/group_vars/.decrypted~encrypted.yaml"#' k3s-ansible/deploy.sh
sed -i 's#^ansible-playbook site.yml$#ansible-playbook site.yml -e "@../external/my-cluster/group_vars/.decrypted~encrypted.yaml" -e "@../vars/.decrypted~vars-protected.yaml"#' k3s-ansible/deploy.sh


cd k3s-ansible
ansible-galaxy install -r ./collections/requirements.yml
./deploy.sh

cd ..
#rm -rf k3s-ansible
#rm ./vars/.decrypted~vars-protected.yaml ./external/my-cluster/group_vars/.decrypted~encrypted.yaml

if [[ $BOOTSTRAP == true ]]; then
    cd ../../
    chmod +x ./kubernetes/bootstrap/bootstrap.sh
    ./kubernetes/bootstrap/bootstrap.sh
    cd deployment/ansible
fi
#/bin/sh
#SSH KEY
#ansible-playbook ./playbook/purge-net-blockers.yaml --user bocmo --ask-pass --ask-become-pass -i ./inventory/hosts

if [[ $BOOTSTRAP == true ]]; then
    cd ../../
    chmod +x ./kubernetes/bootstrap/bootstrap.sh
    ./kubernetes/bootstrap/bootstrap.sh
fi
#/bin/sh
#example run command: APPLY=true ./launch.sh DEPLOY
#example remove existing: APPLY=true ./launch.sh TEARDOWN
if [ -z "$APPLY" ]; then
    APPLY=plan
else
    APPLY=apply
fi

decrypt(){
  sops --decrypt ./credentials/gcp-01-creds.json > ./credentials/.decrypted~gcp-01-creds.json
}
init(){
terraform init
}
deploy(){
  terraform $APPLY -var-file=./gcp/gcp_01.auto.tfvars -var 'credentials_gpc_01=./credentials/.decrypted~gcp-01-creds.json'
  #TODO add cloudflare dns entry for the new ip
}
rm_secrets(){
if [ "$(find . -type f | grep -i ".decrypted" | wc -l)" -gt 0 ]; then
  find . -type f | grep -i .decrypted | xargs rm
else
  echo no secrets found
  break
fi
}
tear_down(){
    while true; do
		read -p 'are you sure you wish to proceed [y/n]: ' yn
		case $yn in
		[Yy]*)
			break
			;;
		[Nn]*)
			exit 1
			;;
		*) echo "Please answer yes or no." ;;
		esac
	done
    decrypt
    terraform $APPLY -var-file=./gcp/gcp_01.auto.tfvars -var 'credentials_gpc_01=./credentials/.decrypted~gcp-01-creds.json' -destroy
    rm_secrets
}

if [[ $1 == TEARDOWN ]]; then
    decrypt
    tear_down
    exit
fi
if [[ $1 == INIT ]]; then
    init
    exit
fi
if [[ $1 == DEPLOY ]]; then
    decrypt
    deploy
    exit
fi




#tear_down
#init
#deploy
# decrypt 
rm_secrets
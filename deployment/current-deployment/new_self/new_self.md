before run wireguard mesh thingie to bridge it all together

(optional) run the prepare step


## deploy first master
copy install_config.yaml master 1 section to target system and run
`curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.30.0+k3s1 sh -s - --config=/root/install_config.yaml`
## deploy second master
copy install_config.yaml master 2 section to target system and run
`curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.30.0+k3s1 sh -s - --config=/root/install_config.yaml`
## deploy third master
copy install_config.yaml master 3 section to target system and run
`curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.30.0+k3s1 sh -s - --config=/root/install_config.yaml`
### note, it will be unhealthy untill cilium is deployed with the values, but the nodes will join(notready)

## run on master1 to get cli for cilium | optional | can also be run on other nodes

`CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=arm64
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz`
### care to update the CLI_ARCH to the actual os (amd64 arm64)

## to deploy cilium
helm install cilium cilium/cilium --namespace=kube-system --values cilium_values.yaml 
## to upgrade when changes in values file
helm upgrade cilium cilium/cilium  --namespace=kube-system --values=cilium_values.yaml

## to upgrade to new cilium version
helm upgrade cilium cilium/cilium  --namespace=kube-system --version 1.15.4 --values=cilium_values.yaml

## to add the loadbalancer ip pool and other requirements
kubectl apply -f cilium_config.yaml


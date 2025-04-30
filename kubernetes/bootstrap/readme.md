# Bootstrap
all commands need to be ran from root folder
## install crd-s
to bootstrap run:
```sh
kubectl apply --context context-prod --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/experimental-install.yaml
kubectl apply --context context-prod --server-side -f https://github.com/prometheus-operator/prometheus-operator/releases/download/v0.81.0/stripped-down-crds.yaml
kubectl apply --context context-prod --server-side -f https://raw.githubusercontent.com/kubernetes-sigs/external-dns/refs/heads/master/docs/sources/crd/crd-manifest.yaml
```


## 
```sh
sops --decrypt kubernetes/bootstrap/flux/age-key.sops.yaml | kubectl apply -f -
sops --decrypt kubernetes/bootstrap/flux/github-ssh-key.sops.yaml | kubectl apply -f -
sops --decrypt kubernetes/bootstrap/flux/github-token.sops.yaml | kubectl apply -f -
sops --decrypt kubernetes/bootstrap/flux/vault-secret.yaml | kubectl apply -f -
sops --decrypt kubernetes/bootstrap/cilium-ca.yaml | kubectl apply -n kube-system -f -

ROOT_DIR=~/git/kubernetes/fluxcd helmfile init
ROOT_DIR=~/git/kubernetes/fluxcd helmfile --kube-context context-prod apply --hide-notes --skip-diff-on-install --suppress-diff --suppress-secrets -f ./kubernetes/bootstrap/helmfile.yaml 
```



## post deploymeny certmanager add prod secret
```sh
kustomize build kubernetes/apps/xauth/cert-manager/cert-manager/addons/certificates/prod/ | ka -f -
```
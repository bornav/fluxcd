# Bootstrap

## Flux

### Install Flux

```sh
kubectl apply --server-side --kustomize ./kubernetes/bootstrap/flux
```

### Apply Cluster Configuration

_These cannot be applied with `kubectl` in the regular fashion due to be encrypted with sops_

```sh
sops --decrypt kubernetes/bootstrap/flux/age-key.sops.yaml | kubectl apply -f -
sops --decrypt kubernetes/bootstrap/flux/github-ssh-key.sops.yaml | kubectl apply -f -
sops --decrypt kubernetes/bootstrap/flux/github-token.sops.yaml | kubectl apply -f -
sops --decrypt kubernetes/bootstrap/flux/vault-secret.yaml | kubectl apply -f -
kubectl apply -f kubernetes/flux/vars/cluster-settings.yaml
```

### Kick off Flux applying this repository

```sh
kubectl apply --server-side --kustomize ./kubernetes/flux/config
```

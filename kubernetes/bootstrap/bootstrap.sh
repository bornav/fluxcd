#!/bin/sh

kubectl apply --server-side --kustomize ./kubernetes/bootstrap/flux
sops --decrypt kubernetes/bootstrap/flux/age-key.sops.yaml | kubectl apply -f -
sops --decrypt kubernetes/bootstrap/flux/github-ssh-key.sops.yaml | kubectl apply -f -
sops --decrypt kubernetes/bootstrap/flux/github-token.sops.yaml | kubectl apply -f -
kubectl apply -f kubernetes/flux/vars/cluster-settings.yaml
kubectl apply --server-side --kustomize ./kubernetes/flux/config


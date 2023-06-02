
#!/bin/bash
# find our local path to run in CI
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
export PATH=$PATH:$SCRIPTPATH
ROOT=kubernetes
# mirror kustomize-controller build options
#kustomize_flags="--load-restrictor=LoadRestrictionsNone --reorder=legacy"
kustomize_flags="--load-restrictor=LoadRestrictionsNone"
kustomize_config="kustomization.yaml"

# Kubernetes Open API extension scheme
OPENAPI=https://raw.githubusercontent.com/kubernetes/kubernetes/master/api/openapi-spec/v3/apis__apiextensions.k8s.io__v1_openapi.json

# loop kubeconform trough these folders
resources=('apps')

# reliable set and interpret exit codes
set -o errexit

echo "INFO - Downloading Flux OpenAPI schemas"
mkdir -p /tmp/flux-crd-schemas/master-standalone-strict
curl -sL https://github.com/fluxcd/flux2/releases/latest/download/crd-schemas.tar.gz | tar zxf - -C /tmp/flux-crd-schemas/master-standalone-strict


find ./$ROOT -type f -name '*.yaml' -print0 | while IFS= read -r -d $'\0' file;
  do
    echo "INFO - Validating $file"
    yq -e 'true' "$file" > /dev/null
done

echo "INFO - Validating clusters"
         kubeconform  -exit-on-error -verbose -summary -schema-location default  -schema-location '/tmp/flux-crd-schemas/master-standalone-strict/{{ .ResourceKind }}{{ .KindSuffix }}.json' -schema-location $OPENAPI ./$ROOT/


for k8s_resources in "${resources[@]}"
do
 echo "INFO - Validating kustomize overlays"
 find ./$ROOT/$k8s_resources -type f -name $kustomize_config -print0 | while IFS= read -r -d $'\0' file;
  do
    echo "INFO - Validating kustomization ${file/%$kustomize_config}"
    kustomize build "${file/%$kustomize_config}" $kustomize_flags  | \
      kubeconform -exit-on-error  -verbose -summary -schema-location default \
       -schema-location '/tmp/flux-crd-schemas/master-standalone-strict/{{ .ResourceKind }}{{ .KindSuffix }}.json' -schema-location $OPENAPI
    if [[ ${PIPESTATUS[0]} != 0 ]]; then
      exit 1
    fi
  done
done

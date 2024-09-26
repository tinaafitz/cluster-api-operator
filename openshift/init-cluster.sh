#!/bin/bash
PATH_TO_PULL_SECRETS=$PWD/pull-secrets.json

kind create cluster
helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set crds.enabled=true

if [ -n "$AWS_ACCOUNT_ID" -a -n "$PATH_TO_ANSICLOUD" -a -f "$PATH_TO_ANSICLOUD/bin/activate" ] ; then
    # set PATH_TO_ANSICLOUD=$HOME/ansicloud-full/ansible-2.9
    # if AWS_ACCOUNT_ID is set then use SSO to sign
    # using aws-saml.py see https://gitlab.corp.redhat.com/ansicloud/ansicloud-full
    . $PATH_TO_ANSICLOUD/bin/activate
    export AWS_REGION="us-west-2"
    aws-saml.py --account=$AWS_ACCOUNT_ID
    export AWS_PROFILE=saml
fi
# double times base64 encoded -> the same result like using:
#   kubectl create secret generic my-secret-name --from-literal=AWS_B64ENCODED_CREDENTIALS="${AWS_B64ENCODED_CREDENTIALS}" --namespace my-name=space
AWS_B64ENCODED_CREDENTIALS=$(clusterawsadm bootstrap credentials encode-as-profile|base64 -w0)
helm install capi-operator --create-namespace --namespace capi-operator-system charts/cluster-api-operator \
   --set awsEncodedCredentials="$AWS_B64ENCODED_CREDENTIALS" \
   --set image.manager.tag='v4.17' \
   --set pullJsonSecret=$(cat $PATH_TO_PULL_SECRETS|base64 -w0) \
   --set-json 'imagePullSecrets=[{"name":"image-pull-secret"}]'  \
   --wait


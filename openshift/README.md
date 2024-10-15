# OpenShift Cluster API Operator helm chart

OpenShift (OCP) Cluster API Operator helm chart is based on the k8s-sig cluster-api-operator helm [chart](https://github.com/kubernetes-sigs/cluster-api-operator/tree/main/hack/charts/cluster-api-operator).  The OpenShift helm chart uses the [redhat-registry](https://catalog.redhat.com/software/containers/explore) container images to deploy the cluster-api-operator, cluster-api and cluster-api-aws-providers.

## Install

Add CAPI Operator & cert manager helm repository:

```
$ helm repo add capi-operator https://raw.githubusercontent.com/openshift/cluster-api-operator/refs/heads/main/openshift
$ helm repo add jetstack https://charts.jetstack.io --force-update
$ helm repo update
```

Install cert manager:

```
$ helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set installCRDs=true
```

Follow the instructions below to create the AWS credentials environment variable:

```
$ export AWS_REGION=us-east-1 
$ export AWS_ACCESS_KEY_ID=<your-access-key>
$ export AWS_SECRET_ACCESS_KEY=<your-secret-access-key>
$ export AWS_SESSION_TOKEN=<session-token> # If you are using Multi-Factor Auth.
$ export AWS_B64ENCODED_CREDENTIALS=$(clusterawsadm bootstrap credentials encode-as-profile|base64 -w0)
$ echo $AWS_B64ENCODED_CREDENTIALS
```

Install the OpenShift Cluster-api-operator

```
$ helm upgrade --install capi-operator capi-operator/cluster-api-operator --create-namespace -n capi-operator-system --set awsEncodedCredentials=$AWS_B64ENCODED_CREDENTIALS
```

#### Note:

To set the redhat openshift credentials at the cluster-api-aws-provider visit https://console.redhat.com/openshift/token to retrieve your API authentication token. Then run the helm install command with the redhat credentials token defined as below.

```
$ helm upgrade --install capi-operator capi-operator/cluster-api-operator --create-namespace -n capi-operator-system --set awsEncodedCredentials=$AWS_B64ENCODED_CREDENTIALS --set ocmToken=<set-redhat-api-credentials-token>
```


## Troubleshooting

Run the following command to confirm the cluster-api-operator deployed

```
$ oc get deploy -n capi-operator-system
NAME                                 READY   UP-TO-DATE   AVAILABLE   AGE
capi-operator-cluster-api-operator   1/1     1            1           45m
```

Run the following commands to confirm the coreProvider is deployed and cluster-api deployment is running

```
$ oc get coreProvider -n capi-system
NAME          INSTALLEDVERSION   READY
cluster-api   v1.8.4             True

$ oc get deploy -n capi-system
NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
capi-controller-manager   1/1     1            1           47m
```

Run the following commands to confirm the infrastructureProvider is deployed and cluster-api-aws-provider deployment is running

```
$ oc get infrastructureProvider -n capa-system
NAME   INSTALLEDVERSION   READY
aws    v2.6.1             True

$ oc get deploy -n capa-system
NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
capa-controller-manager   1/1     1            1           48m
```

## Uninstall

Uninstall the  OpenShift Cluster-api-operator chart

```
$ helm delete capi-operator -n capi-operator-system
```
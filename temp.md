~~~
kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -oyaml > key.yaml

kubeseal < /tmp/ss.yaml --recovery-unseal --recovery-private-key key.yaml -o yaml
~~~

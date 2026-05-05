```
kubectl scale deployment <deployment名> --replicas=<数> -n <namespace>

kubectl patch daemonset fluent-bit -n logging \
  -p '{"spec":{"template":{"spec":{"nodeSelector":{"daemonset-disabled":"true"}}}}}'

kubectl patch daemonset fluent-bit -n logging \
  --type='json' \
  -p='[{"op":"remove","path":"/spec/template/spec/nodeSelector/daemonset-disabled"}]'
```

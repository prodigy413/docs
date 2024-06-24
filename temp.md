~~~
kubectl patch deployment <deployment-name> -n <namespace> --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/lifecycle", "value": {"preStop": {"exec": {"command": ["ls", "-l"]}}}}]'
~~~

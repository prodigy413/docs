~~~
kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -oyaml > key.yaml

kubeseal < /tmp/ss.yaml --recovery-unseal --recovery-private-key key.yaml -o yaml
~~~

~~~
application-https.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: test-app
  namespace: argocd
spec:
  destination:
    namespace: default
    server: https://kubernetes.default.svc
  project: test-project
  source:
    path: ./
    repoURL: https://github.com/prodigy413/argocd-test.git
    targetRevision: HEAD
  syncPolicy:
    automated:
      prune: true
      selfHeal: true


project-https.yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: test-project
  namespace: argocd
spec:
  description: Project for argocd test
  destinations:
  - name: obi-cluster
    namespace: '*'
    server: https://kubernetes.default.svc
  sourceRepos:
  - https://github.com/prodigy413/argocd-test.git
#  - '*'


repository-https.yaml
apiVersion: v1
kind: Secret
metadata:
  labels:
    argocd.argoproj.io/secret-type: repository
  name: test-repo
  namespace: argocd
data:
  password: Z2hwX3J4cUtHUVJNYkNzbERXOFNWWXNhYzlrbUUwc1h2bDRVbUZSYQ==
  project: ZGVmYXVsdA==
  proxy: aHR0cDovL3NxdWlkLmFyZ29jZC5zdmMuY2x1c3Rlci5sb2NhbDozMTI4
  type: Z2l0
  url: aHR0cHM6Ly9naXRodWIuY29tL3Byb2RpZ3k0MTMvYXJnb2NkLXRlc3QuZ2l0
  username: cHJvZGlneTQxMw==
type: Opaque
~~~

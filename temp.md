<table>
  <tr>
    <th>/</th>
    <th>ALB</th>
    <th>NPLB</th>
  </tr>
  <tr>
    <td>SSL終端</td>
    <td>〇</td>
    <td>〇</td>
  </tr>
  <tr>
    <td>PodからClientIP確認</td>
    <td>X-Forwarded-Forヘッダーで確認可能<br>- 参照：<a href="https://guide.ncloud-docs.com/docs/ja/k8s-troubleshoot-lb#%E4%B8%8D%E6%AD%A3%E3%81%AA-client-ip">不正な Client IP</a></td>
    <td>proxy-protocolの有効にして確認可能<br>- 参照：<a href="https://guide.ncloud-docs.com/docs/ja/k8s-troubleshoot-lb#%E4%B8%8D%E6%AD%A3%E3%81%AA-client-ip">不正な Client IP</a></td>
  </tr>
  <tr>
    <td>Podのデプロイ時、<br>ゼロダウンタイム失敗の問題</td>
    <td colspan="2">k8s v1.26でkube-proxyにProxyTerminatingEndpoints機能を追加し、問題解決<br><a href="https://kubernetes.io/blog/2022/12/30/advancements-in-kubernetes-traffic-engineering/">Kubernetes v1.26: Advancements in Kubernetes Traffic Engineering</a></td>
  </tr>
</table>

<table>
  <tr>
    <th>/</th>
    <th>ALB Ingress Controller</th>
    <th>3rd Ingress Controller</th>
  </tr>
  <tr>
    <td>デフォルトLB</td>
    <td>ALB</td>
    <td>NPLB</td>
  </tr>
  <tr>
    <td>Ingress動作</td>
    <td>各IngressごとHostnameが存在</td>
    <td>Ingress数に関係なく1つのHostnameが存在</td>
  </tr>
  <tr>
    <td>インストール/削除</td>
    <td>HypervisorがKVMの場合：<br>- 自動インストールされて削除は不可<br>HypervisorがXENの場合：<br>- インストール/削除可能</td>
    <td>インストール/削除可能</td>
  </tr>
</table>

~~~
$ kubectl get ingress -o \
custom-columns=\
NAME:.metadata.name,\
INGRESS_CLASS:.spec.ingressClassName,\
HOSTNAME:.status.loadBalancer.ingress[*].hostname

NAME      INGRESS_CLASS   HOSTNAME
nginx01   alb             ing-default-nginx01-b1424-26811501-68946e022421.jpn.lb.naverncp.com
nginx02   alb             ing-default-nginx02-4afb4-26811502-6f18524e4ca5.jpn.lb.naverncp.com



$ kubectl get ingress -o \
custom-columns=\
NAME:.metadata.name,\
INGRESS_CLASS:.spec.ingressClassName,\
HOSTNAME:.status.loadBalancer.ingress[*].hostname

NAME      INGRESS_CLASS   HOSTNAME
nginx01   nginx           ingress-ngi-ingress-ngin-65d9a-26811516-4991c7a24dc2.jpn.lb.naverncp.com
nginx02   nginx           ingress-ngi-ingress-ngin-65d9a-26811516-4991c7a24dc2.jpn.lb.naverncp.com

$ kubectl -n ingress-nginx get svc
NAME                                 TYPE           CLUSTER-IP       EXTERNAL-IP                                                                PORT(S)                      AGE
ingress-nginx-controller             LoadBalancer   198.19.218.173   ingress-ngi-ingress-ngin-65d9a-26811516-4991c7a24dc2.jpn.lb.naverncp.com   80:32202/TCP,443:30449/TCP   23m
ingress-nginx-controller-admission   ClusterIP      198.19.191.232   <none>                                                                     443/TCP                      23m
~~~

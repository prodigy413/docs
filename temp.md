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
    <td>利用可能LB</td>
    <td>ALB</td>
    <td>NPLB</td>
  </tr>
  <tr>
    <td>Ingress動作</td>
    <td>各IngressごとHostnameが存在 ※1</td>
    <td>Ingress数に関係なく1つのHostnameが存在 ※1</td>
  </tr>
  <tr>
    <td>インストール/削除</td>
    <td>HypervisorがKVMの場合：<br>- 自動インストールされて削除は不可<br>HypervisorがXENの場合：<br>- インストール/削除可能</td>
    <td>インストール/削除可能</td>
  </tr>
  <tr>
    <td>Annotationの設定場所</td>
    <td>Ingressリソース</td>
    <td>Serviceリソース</td>
  </tr>
  <tr>
    <td>ETC</td>
    <td>rewrite-target利用不可</td>
    <td>-</td>
  </tr>
</table>

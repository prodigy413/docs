# Kubernetes VerUp

## Ncloud Kubernetes Service

[Ncloud Kubernetes Service のリリースノート](https://guide.ncloud-docs.com/docs/ja/k8s-k8srelease)

## Deprecated API

- Link<br>[Deprecated API Migration Guide](https://kubernetes.io/docs/reference/using-api/deprecation-guide)<br>[CHANGELOG](https://github.com/kubernetes/kubernetes/tree/master/CHANGELOG)

### v1.25

- <b>CronJob</b>
  - batch/v1beta1 => batch/v1
- <b>EndpointSlice</b>
  - discovery.k8s.io/v1beta1 => discovery.k8s.io/v1
  - If migration is needed [click here.](https://kubernetes.io/docs/reference/using-api/deprecation-guide/#endpointslice-v125)
- <b>Event</b>
  - events.k8s.io/v1beta1 => events.k8s.io/v1
  - If migration is needed [click here.](https://kubernetes.io/docs/reference/using-api/deprecation-guide/#event-v125)
- <b>HorizontalPodAutoscaler</b>
  - autoscaling/v2beta1 => autoscaling/v2
  - If migration is needed [click here.](https://kubernetes.io/docs/reference/using-api/deprecation-guide/#horizontalpodautoscaler-v125)
- <b>PodDisruptionBudget</b>
  - policy/v1beta1 => policy/v1
  - If migration is needed [click here.](https://kubernetes.io/docs/reference/using-api/deprecation-guide/#poddisruptionbudget-v125)
- <b>PodSecurityPolicy</b>
  - policy/v1beta1 => Will beRemoved
- <b>RuntimeClass</b>
  - node.k8s.io/v1beta1 => node.k8s.io/v1

### v1.26

- <b>Flow control resources</b>
  - flowcontrol.apiserver.k8s.io/v1beta1 => flowcontrol.apiserver.k8s.io/v1beta2
- <b>HorizontalPodAutoscaler</b>
  - autoscaling/v2beta2 => autoscaling/v2
  - If migration is needed [click here.](https://kubernetes.io/docs/reference/using-api/deprecation-guide/#horizontalpodautoscaler-v126)

### v1.27

- <b>CSIStorageCapacity</b>
  - storage.k8s.io/v1beta1 => storage.k8s.io/v1

### v1.29

- <b>Flow control resources</b>
  - flowcontrol.apiserver.k8s.io/v1beta2 => flowcontrol.apiserver.k8s.io/v1 or flowcontrol.apiserver.k8s.io/v1beta3
  - If migration is needed [click here.](https://kubernetes.io/docs/reference/using-api/deprecation-guide/#flowcontrol-resources-v129)

## From IBM Site

> [!NOTE]
> Please ignore Update about IKS.

- [1.25](https://cloud.ibm.com/docs/containers?topic=containers-cs_versions_125#prep-up-125)
- [1.26](https://cloud.ibm.com/docs/containers?topic=containers-cs_versions_126#prep-up-126)
- [1.27](https://cloud.ibm.com/docs/containers?topic=containers-cs_versions_127#prep-up-127)
- [1.28](https://cloud.ibm.com/docs/containers?topic=containers-cs_versions_128#prep-up-128)
- [1.29](https://cloud.ibm.com/docs/containers?topic=containers-cs_versions_129#prep-up-129)

# ETC

## Nginx Ingress Controller

### v1.10.0
- [v1.10.0](https://github.com/kubernetes/ingress-nginx/releases/tag/controller-v1.10.0)
- From `Breaking changes`
  - This version does not support chroot image, this will be fixed on a future minor patch release
  - This version dropped Opentracing and zipkin modules, just Opentelemetry is supported as of this release
  - This version dropped support for PodSecurityPolicy
  - This version dropped support for GeoIP (legacy). Only GeoIP2 is supported

### v1.9.0

- [v1.9.0](https://github.com/kubernetes/ingress-nginx/releases/tag/controller-v1.9.0)
- From `Some important updates to consider for testing:`
  - Disable user snippets per default
  - remove curl on base container
  - Implement annotation validation

### v1.8.0

- [v1.8.0](https://github.com/kubernetes/ingress-nginx/releases/tag/controller-v1.8.0)
- From `Important Changes:`
  - Validate path types => [strict-validate-path-type](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/#strict-validate-path-type)
  - images: upgrade to Alpine 3.18
  - Update documentation to reflect project name; Ingress-Nginx Controller

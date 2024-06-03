~~~yaml
apiVersion: v1
kind: Namespace
metadata:
  name: test01
---
apiVersion: v1
kind: Namespace
metadata:
  name: test02
---
apiVersion: v1
kind: Namespace
metadata:
  name: test03
---
apiVersion: v1
kind: Namespace
metadata:
  name: test04
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: x-test-01
  labels:
    app: x-test-01
  namespace: test01
spec:
  selector:
    matchLabels:
      app: x-test-01
  replicas: 1
  template:
    metadata:
      labels:
        app: x-test-01
    spec:
      containers:
      - name: nginx
        image: nginx:1.25.3
        imagePullPolicy: IfNotPresent
        lifecycle:
          postStart:
            exec:
              command: ["/bin/sh", "-c", "sleep 60"]
          preStop:
            exec:
              command: ["/bin/sh", "-c", "sleep 60"]
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: x-test-02
  labels:
    app: x-test-02
  namespace: test01
spec:
  selector:
    matchLabels:
      app: x-test-02
  replicas: 1
  template:
    metadata:
      labels:
        app: x-test-02
    spec:
      containers:
      - name: nginx
        image: nginx:1.25.3
        imagePullPolicy: IfNotPresent
        lifecycle:
          postStart:
            exec:
              command: ["/bin/sh", "-c", "sleep 60"]
          preStop:
            exec:
              command: ["/bin/sh", "-c", "sleep 60"]
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: x-test-03
  labels:
    app: x-test-03
  namespace: test01
spec:
  selector:
    matchLabels:
      app: x-test-03
  replicas: 1
  template:
    metadata:
      labels:
        app: x-test-03
    spec:
      containers:
      - name: nginx
        image: nginx:1.25.3
        imagePullPolicy: IfNotPresent
        lifecycle:
          postStart:
            exec:
              command: ["/bin/sh", "-c", "sleep 60"]
          preStop:
            exec:
              command: ["/bin/sh", "-c", "sleep 60"]
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: x-test-04
  labels:
    app: x-test-04
  namespace: test02
spec:
  selector:
    matchLabels:
      app: x-test-04
  replicas: 1
  template:
    metadata:
      labels:
        app: x-test-04
    spec:
      containers:
      - name: nginx
        image: nginx:1.25.3
        imagePullPolicy: IfNotPresent
        lifecycle:
          postStart:
            exec:
              command: ["/bin/sh", "-c", "sleep 60"]
          preStop:
            exec:
              command: ["/bin/sh", "-c", "sleep 60"]
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: x-test-05
  labels:
    app: x-test-05
  namespace: test02
spec:
  selector:
    matchLabels:
      app: x-test-05
  replicas: 1
  template:
    metadata:
      labels:
        app: x-test-05
    spec:
      containers:
      - name: nginx
        image: nginx:1.25.3
        imagePullPolicy: IfNotPresent
        lifecycle:
          postStart:
            exec:
              command: ["/bin/sh", "-c", "sleep 60"]
          preStop:
            exec:
              command: ["/bin/sh", "-c", "sleep 60"]
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: x-test-06
  labels:
    app: x-test-06
  namespace: test03
spec:
  selector:
    matchLabels:
      app: x-test-06
  replicas: 1
  template:
    metadata:
      labels:
        app: x-test-06
    spec:
      containers:
      - name: nginx
        image: nginx:1.25.3
        imagePullPolicy: IfNotPresent
        lifecycle:
          postStart:
            exec:
              command: ["/bin/sh", "-c", "sleep 60"]
          preStop:
            exec:
              command: ["/bin/sh", "-c", "sleep 60"]
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: x-test-07
  labels:
    app: x-test-07
  namespace: test03
spec:
  selector:
    matchLabels:
      app: x-test-07
  replicas: 2
  template:
    metadata:
      labels:
        app: x-test-07
    spec:
      containers:
      - name: nginx
        image: nginx:1.25.3
        imagePullPolicy: IfNotPresent
        lifecycle:
          postStart:
            exec:
              command: ["/bin/sh", "-c", "sleep 60"]
          preStop:
            exec:
              command: ["/bin/sh", "-c", "sleep 60"]
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: x-test-08
  labels:
    app: x-test-08
  namespace: test04
spec:
  selector:
    matchLabels:
      app: x-test-08
  replicas: 2
  template:
    metadata:
      labels:
        app: x-test-08
    spec:
      containers:
      - name: nginx
        image: nginx:1.25.3
        imagePullPolicy: IfNotPresent
        lifecycle:
          postStart:
            exec:
              command: ["/bin/sh", "-c", "sleep 60"]
          preStop:
            exec:
              command: ["/bin/sh", "-c", "sleep 60"]

~~~

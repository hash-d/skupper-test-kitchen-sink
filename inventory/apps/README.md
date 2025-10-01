Applications
============

| subdir | `test_name` | Description |
| :---   | :---        | :---        |
| hello  | hello-world | The Skupper example "Hello World" application |


Creating apps
=============

The directories under inventory/apps contain the configuration of the applications that will be created for the test, and the verifications that can be done to confirm that application is working correctly.

The application definitions should always be set for groups.  Here, attention must be taken on whether adeployment can exist on multiple hosts (actual hosts or namespaces), or not.

On the apps, you can define the following variables:

`container_worloads`
--------------------

A list of dictionaries, with images to be deployed on the host or K8S namespace:

```
container_workloads:
- name: hello-world-frontend
  image: quay.io/skupper/hello-world-frontend
  expose: "8080:8080"
  kube_replicas: 3
  kube_app: frontend
```

`application_resources`
-----------------------

A list of K8S resource definitions that can be fed to skupper.v2.resource for creation (such as Listener, Connector, etc).

`application_url_checks`
------------------------

A list of URLs to be verified from the host/namespace.  In all cases, curl will be used for the testing; directly for system sites, via Lanyard for Kube.

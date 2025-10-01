Introduction
============

This repository consists of a series of simple tests for Skupper, which can be expanded by the use of different inventories.

The tests are simple in the sense that they follow a straightforward sequence setup-verify-teardown; in that, they are different from other e2e tests that may verify the setup, then introduce some modification, verify that and repeat the cycle.

The objective of the tests is mainly for non-functional verifications:

-   Use Setup and Verify, then upgrade Skupper and verify again
-   Explore different Setup strategies, and how they impact the product
-   Use Setup to prepare an environment for manual testing
-   Explore the same test in different topologies
-   Allow tests to run in specific topologies, such as Disconnected testing
-   Setup and Verify; power the whole cluster down and back again, see how the product behaves

Executing tests
===============

Make targets
============

`test`
------

The main target: it will run `test.yaml`, which in turn calls `setup.yaml`, `verify.yaml`, and `teardown.yaml`, with an optional pause before teardown.  It does not call `prep.yaml`.

`prep`
------

This calls `prep.yaml`, to make changes so a host is prepared to run this specific test.  It makes changes to the host, so make sure you understand what it is doing, especially if running in your own computer.

It will not do general skupper testing preparation (such as installing the router or CLI binaries, Podman or Docker, Python or any other packages): the machines need to be configured for general testing before any playbooks in this repository are run.

Examples of things it may do:

- Open firewall ports
- Enable lingering

`setup`, `verify` and `teardown`
--------------------------------

These are the component parts of a full test, that can be called individually for development, testing or composition.

When running them separately, make sure to defined `TEST_ID`, lest you may try to verify or teardown namespaces different from what were created on the setup.

`check`, `inv-list` and `inventory`
-----------------------------------

These will provide different views of the inventory, with the same configuration as used for the main targets.

`inv-list` runs `ansible-inventory --list -y`, whereas `inventory` produces a PDF with a diagram view of the inventory.  For the PDF generation, you'll need to have [GraphVis](https://graphviz.org/) installed.

`check` will instead try to ping the configured hosts (`ansible.builtin.ping` for system sites, `kubernetes.core.k8s_cluster_info` for kube).  You can use it to validate your inventory before an actual execution

`reload`
--------

This is an auxiliary target that will call `reload.yaml`, which will execute `skupper.v2.system` with `action: reload` on all system (podman, docker and systemd) hosts in the inventory.

To reload only some of the hosts, use `OPTIONS=--limit="<filter>"`.

General concepts
================

- Ansible inventory hosts are not actual hosts, but abstract Skupper sites; they can be any type of system site or a Kubernetes site

Creating topologies
===================

The topology inventories declare abstract topologies: which sites exist and how they connect to each other.  Actual hosts and namespaces are defined on local inventories, instead.

There are three major groups at this time:

- backends
- frontends
- hubs

[comment]: # in the future, perhaps add at least one more group: DB.  Perhaps also DMZ, but then hubs may be just that.  DBs may be backends, too, but in general single deployment?

The actual topologies are created on subgroups that represent individual hosts or namespaces:

- backend-0-9
- frontend-0-9
- hub-0-9

On these subgroup vars, the topology is defined by declaring `skupper_links`.  For example, you could have `inventory/topology/1-1/group_vars/frontend-0` with the following contents:

```
skupper_links:
- backend-0
```

For a hub/spoke topology, the links could be declared on the top-level group.  For example, `inventory/topology/1-1/group_vars/frontend` could have this:

```
skupper_links:
- hub-0
```

Besides linking, the group vars on the topology inventory also define site configuration and topology-specific Skupper resources.  For example, for a site that accepts incoming links:

```
---

site_spec:
  linkAccess: default

site_resources:
- apiVersion: skupper.io/v2alpha1
  kind: RouterAccess
  metadata:
    name: access-1
  spec:
    roles:
      - port: 55671
        name: inter-router
      - port: 45671
        name: edge
    bindHost: "{{ ansible_host }}"
```

:!: **Attention**: at this level, you don't know whether the hosts are system or kubernetes sites.  And, if they're system sites, more than one could reside in a single VM (for example, for testing Podman and Docker sites running side by side).  For that reason, make sure any ports you declare on your topology are unique for the topology.

Creating apps
=============

The directories under inventory/apps contain the configuration of the applications that will be created for the test, and the verifications that can be done to confirm that application is working correctly.

The application definitions should always be set for groups.  Here, attention must be taken on whether adeployment can exist on multiple hosts (actual hosts or namespaces), or not.

If only one  XXX

On the apps, you can define the following variables:

`container_worloads`
--------------------

A list of dictionaries, with images to be deployed on the host/namespace:

```
container_workloads:
- name: hello-world-frontend
  image: quay.io/skupper/hello-world-frontend
  expose: "8080:8080"
```

`application_resources`
-----------------------

A list of K8S resource definitions that can be fed to skupper.v2.resource for creation (such as Listener, Connector, etc).

`application_url_checks`
------------------------

A list of URLs to be verified from the host/namespace.  In all cases, curl will be used for the testing; directly for system sites, via Lanyard for Kube.

Local inventories
=================

This is where actual hosts and namespaces are declared, and associated to groups.

Configuration
=============

Make variables
--------------

| Name    | Required | Description |
| :---    | :---     | :---        |
| `TOPO`  | Y | The topology to be used.  List available under `inventory/topology` |
| `APP`   | Y | The app to be run.  `inventory/apps` |
| `LOCAL` | Y | The local inventory.  This is where hosts are defined and set under role and technology groups |
| `SKUPPER_VERSION` | | `inventory/version`.  Use this to populate image variables, when required |
| `TEST_ID` | | If not set, the Makefile will generate a random value.  That allows the same test to be run in parallel against the same cluster, as the `TEST_ID` is part of the namespaces.  When using Kitchen Sink for environment preparation, however, it may be necessary to set `TEST_ID` so different executions deal with the same namespaces.  Make it short. |

Inventory
---------

These variables can be set individually on the local inventory's `host_vars`, per group on `group_vars` or for all hosts via Ansible's `-e` option.  In that case, pass it to the make file with the `OPTIONS` variable:

    make APP=hello TOPO=1-1 LOCAL=local-1 test OPTIONS='-e ks_serial=1


| Name | Type | Default Value | Description |
| :--- | :--- | :--- | :--- |
| `kubeconfig` | `string` | unset/omit | If all testing goes to a single cluster, this can be defined on `group_vars/kube` or via `-e kubeconfig=`.  Otherwise, set it per host or per group. |
| `ks_install_system_controller` | `boolean` | `true` | This option is `true` by default on `podman`, `systemd` and `docker`, and it is not set for `kubernetes`.  It controls whether the system controller is to be installed (and later removed, on teardown) |
| `ks_pause` | n/a | unset | Whether `test.yaml` should pause between the `verify` and `teardown` steps.  This will take effect simply by defining the variable; any type, any value. Use `OPTIONS="-e pause="` to activate it.|
| `ks_retry_multiplier` | `int` | 1 | A multiplier to be used on the `retries` keyword.  It does not affect the delay between retries, only the number of retries.  Set it to zero to remove all retries |
| `ks_serial` | `int` | unset / omit | Some plays (not all) can be set to run with a smaller concurrency by setting the `keyword` serial via this variable.  To restrict concurrency on all plays, use `OPTIONS=-f1` |
| `ks_wait_kube_teardown` | `boolean` | `false` | Whether the test should wait for the namespace removal to complete |
| `ks_wait_kube_teardown_seconds` | `integer` | `600` | How many seconds to wait for the namespace removal |
| `ks_workload_platform` | `string` | depends | This selects how workloads will be deployed.  Defaults to same as `skupper_platform`, except for `systemd`, where `podman` is used by default.  Change this only if you want your workloads to run in a different container engine |

Images
------

*   `cli_image`
*   `router_image`
*   `system_controller_image`

Generated
---------

These variables are generated by parts of the playbooks or in the inventory itself, and are used elsewehere.

| Name | Type | Default Value | Description |
| :--- | :--- | :--- | :--- |
| `inventory_namespace` | `string` | `ks_{test_id}-{test_name}-{inventory_hostname}`| This will become the value of the `platform` field on `skupper.v2.*` calls.

Internal
--------

These variables control internal mechanics of the test, and should generally not be changed.

| Name | Type | Default Value | Description |
| :--- | :--- | :--- | :--- |
| `ks_reached_end` | `boolean` | unset | This is set to true right before the teardown step, on any remaining hosts — that is, on any hosts that did not fail previously.  It is used to allow the teardown process to take place at the end of the playbook, while still reporting failures. |
| `skupper_platform` | `string` | `podman`, `docker`, `systemd` or `kube` | This will become the value of the `platform` field on `skupper.v2.*` calls.
| `skupper_platform_type` | `string` | `system` or `kubernetes` | `podman`, `docker` and `systemd` sites share most of their behaviors, as opposed to `kube`.  This variable is used to group these platform types to simplify logic |
| `test_name` | `string` | n/a | The name of the test.  This is set on `group_vars/all` on each test.  This variable is used when constructing the namespace names, so its value needs to be valid for [RFC 1123](https://datatracker.ietf.org/doc/html/rfc1123)



General ideas
=============

Playbooks
---------

- Prep?
- Setup
- Verify
- Teardown
- Disruptors?

Inventories
-----------

- topology
  - basic
  - non-kube
  - kube
  - disconnected
  - kube-to-non
  - non-to-kube
- assignment
  - assign application roles to nodes from the topology
- application
  - hello world
  - hipstershop?
  - load

Host names?

- Site type?
- Edgeness?
- Application use?

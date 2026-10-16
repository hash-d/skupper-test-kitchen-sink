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

Tests are executed by calling `make`.  The default `make` target is `test`, which will run the setup, verify and teardown phases.

To call it,  you'll need to set at least `APP`, `TOPO` and `LOCAL`:

    make APP=hello TOPO=1-1 SKUPPER_VERSION=2.1.1 LOCAL=dh-system.yaml

Where

* `APP` is a directory under `inventory/apps` which defines the workloads, connectors and listeners
* `TOPO` is a directory under `inventory/topology` which describes how the sites will be connected
* `LOCAL` is a file or directory under `inventory/local`.  This directory is not under git control, and this is where the actual hosts are defined.

Make targets
============

`test`
------

The main target: it will run `test.yaml`, which in turn calls `check.yaml`, `setup.yaml`, `verify.yaml`, and `teardown.yaml`, with an optional pause before teardown.  It does not call `prep.yaml`.

`prep`
------

/!\ **TODO**

This calls `prep.yaml`, to make changes so a host is prepared to run this specific test.  It makes changes to the host, so make sure you understand what it is doing, especially if running in your own computer.

It will not do general skupper testing preparation (such as installing the router or CLI binaries, Podman or Docker, Python or any other packages): the machines need to be configured for general testing before any playbooks in this repository are run.

Examples of things it may do:

- Open firewall ports
- Enable lingering

`setup`, `verify` and `teardown`
--------------------------------

These are the component parts of a full test, that can be called individually for development, testing or composition.

When running them separately, make sure to define `TEST_ID`, lest you may try to verify or teardown namespaces different from what were created on the setup.

`check`, `inv-list` and `inventory`
-----------------------------------

These will provide different views of the inventory, with the same configuration as used for the main targets.

`inv-list` runs `ansible-inventory --list -y`, whereas `inventory` produces a PDF with a diagram view of the inventory.  For the PDF generation, you'll need to have [GraphVis](https://graphviz.org/) installed.

`check` will instead try to ping the configured hosts (`ansible.builtin.ping` for system sites, `kubernetes.core.k8s_cluster_info` for kube).  You can use it to validate your inventory before an actual execution

`reload`
--------

This is an auxiliary target that will call `reload.yaml`, which will execute `skupper.v2.system` with `action: reload` on all system (podman, docker and systemd) hosts in the inventory.

To reload only some of the hosts, use `OPTIONS=--limit="<filter>"`.

The default operation is to reload all sites at the same time.  To change that, use `OPTIONS=-f1` or `OPTIONS="-e sk_serial=1"`.

General concepts
================

Ansible inventory hosts
-----------------------

Ansible inventory hosts are not actually individual hosts, but abstract Skupper sites; they can be any type of system site or a Kubernetes site:

  - For system sites, for example, a single actual host may be assigned to more than one inventory host, in which case several different skupper namespaces may be created on the host
  - For kube sites, the hosts will generally use the `local` connection, and may (or not) differ on `kubeconfig`.

In any case, each inventory host will correspond to a single, unique Skupper or K8S namespace.

Technology groups
-----------------

Each host must be explicitly declared to belong to one (and only one) of four technology groups:

- kube
- docker
- podman
- systemd

Their belonging to one of these groups will determine how workloads are deployed, sites created, links established, listeners and connectors defined, and so on.

Example local inventory snippet:

    kube:
      hosts:
        frontend-0:
    podman:
      hosts:
        hub-0:
    docker:
      hosts:
        backend-0:

In addition to these individual groups, there is also a `system` group that encompasses `docker`, `podman` and `systemd`.  Hosts should not be set directly to that group, however, as the playbooks would not know how to handle them.  That group exists to simplify `hosts` filters on plays that apply to all types of system sites.

Role groups
-----------

Additionally, each host must also be explicitly declared to belong to one of the following role groups:

- frontends
- backends
- hubs

`frontend` and `backends` are similar: besides the sites, they'll generally have workloads deployed on them.

`hubs` generally will have no worklods, serving only as routing nodes in the VAN.

Example local inventory snippet:

    frontends:
      hosts:
        frontend-0
    backends:
      hosts:
        backends-[0:3]
    hubs:
      hosts:
        hub-0:

Note that while most topologies will have all three role groups defiened, some may not include `hubs`.  If you define hosts in your local inventory on the `hubs` group for those topologies, the sites will be created on those hosts, but they'll not be connected to the VAN.


Further reading
===============

- [Topologies](inventory/topology/README.md)
- [Apps](inventory/apps/README.md)
- [Configuration](configuration.md)


Local inventories and examples
===============================

As mentioned above, this is where actual hosts are declared, and associated to groups.  They reside on `inventory/local`, and can either be single files or directories.

Those are local to your environment and not handled by git.

On those files, you need to declare where your hosts exists on the two main groupings (technologies and roles).

You may also need to declare `ansible_host` for system sites, and you can define other host or group specific variables.

Check the applications and topologies README files for details on what can be configured, as well as the [configuration](configuration.md) page.

kube-only, 10 backend sites
---------------------------

It's easy to create several sites on a single kube cluster, thanks to Ansible inventory's range system, and the fact that they do not need to have `ansible_host` defined (the unique namespaces are created automatically).

```
kube:
  hosts:
    backend-[0:9]:
    hub-0:
    frontend-0:
  vars:
    kubeconfig: /path/to/kube
backends:
  hosts:
    backend-[0-9]:
hubs:
  hosts:
    hub-0:
frontend:
  hosts;
    frontend-0:
```

system sites; all techs
-----------------------

For system sites, `ansible_host` needs to be declared for each host, as the expeced inventory hostnames (`[backend|frontend|hub]-[[:digit:]]`) do not correspond to actual host names.

A single system could support more than one role or one technology, as long as the application, topology and operating system allow it (RHEL8, for example, does not support Podman and Docker sites on the same host).

```
podman:
  hosts:
    backend-0:
      ansible_host: 10.0.0.1
      ansible_user: cloud-user
docker:
  hosts:
    hub-0:
      ansible_host: 10.0.0.2
      ansible_user: cloud-user
systemd:
  hosts:
    frontend-0:
      ansible_host: 10.0.0.3
      ansible_user: cloud-user

backends:
  hosts:
    backend-0:
hubs:
  hosts:
    hub-0:
frontend:
  hosts;
    frontend-0:
```



General ideas
=============

Playbooks
---------

- Prep?
- Setup
- Verify
- Teardown
- Disruptors?
- Helpers
  - reload
  - check
  - inventory

Inventories
-----------

- topology
  - 1-1
    - perhaps split in to: 1-frontend-n-backend and n-frontend-1-backend; links going to the '1' site
  - front-hub-back
    - can be used for disconnected, with the hub on the bastion
  - two-hubs
    - one hub for frontend, one for backend, and they are interconnected
  - N
    - like frame2's.  Simplest that can verify a variety of link settings
  - Geo HA.  Two sets of two-hubs; the backend hubs have secondary links to the frontend hub on the other set with high cost, to be used in case one of the backend sites is lost
  - topologies should accept some level of configuration
    - setting HA, for example, so we do not have whole topologies just for that
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

TODO
====

- Split inventory target into inv-dot and inv-pdf
- Make inv-dot a requirement for inv-pdf, test and verify
  - Storing the whole inventory might give away secrets; the dot file requires no pre-reqs installed (only the inv-pdf target), and can be used as an evidence of the inventory that was used.
- Generate (save) and print a test report: variables, git describe, etc
- App and topology README: sample/template local inventories
- Implement the `prep` target
- Implement port shift values, to simplifly topology and application development
  jobaid: `groups['group_name'].index(inventory_hostname)`
- Create kube children groups; allow local inventories to set hosts on them, adding specific functionality (for example, applications may expose frontend workloads via routes on OpenShift)
- Change the way sites are prepared to accept links: instead of `site_spec` + `site_resources`, make it a single configuration that works for both kube and non-kube.  Still allow site specs, though
- Change Makefile to use ansible-navigator, instead of ansible-playbook
- Make inv-svg; add some svg as examples on README.md
- Refactor into a collection?
- change `container_workloads` from a list to a dictionary, so that their contents can be addressed by other parts of the inventory or playbook
- create some checklists (and hopefully some way of checking them): always set kubeconfig, stage for skupper.v2.resource, etc...
- add `ks_reload_handlers` (default true) and `ks_final_system_reload` (default false) to allow setup before start
- create 'noop' application, which installs no application
- add local cli operation mode (ie, instead of using skupper.v2, make calls to the cli)

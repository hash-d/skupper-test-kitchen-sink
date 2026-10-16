Topologies
==========

1-1
---

A simple topology with a single frontend site (frontend-0), to which 1-N backend sites connect (backend-0, backend-1...).

front-hub-back
--------------

Hub and spoke: N frontend sites and N backend sites connect to a single Hub site (hub-0).

Creating topologies
===================

The topology inventories declare abstract topologies: which sites exist and how they connect to each other.  Actual hosts and namespaces are defined on local inventories, instead.

Links
-----

To define the topology, the variable `skupper_links` needs to be declared.  For example, you could have `inventory/topology/1-1/group_vars/backends` with the following contents:

```
skupper_links:
- frontend-0
```

This would cause any hosts on the `backends` group to create a Skupper link to the site defined for the inventory host `frontend-0`, creating a hub-and-spoke topology.

For simpler topologies, this configuration goes to the `group_vars` of a group, so all hosts on that group create a link to the same site.

More complex topologies (none at this time) could define `skupper_links` on `host_vars`, allowing for a more detailed topology.  In that case, the topology documentation needs to describe which hosts need to exist on the local inventory.

Note that, at this time, `skupper_links` accepts only individual inventory hosts as targets, not groups.

Sites
-----

The playbook will create one site on each inventory host.  The site may be specified with the `site_spec` variable.  Continuing on the example above, as `frontend-0` is the target of a link, it needs to be able to accept link requests:

```
site_spec:
  linkAccess: "{{ 'default' if skupper_platform == 'kubernetes' else omit }}"

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

Here, `site_spec` is defined with `linkAccess: default` for `kubernetes` sites, which is omitted for other types of sites.

`site_spec` is sent as-is to `skupper.v2.resource` when creating the site, so any fields that are acceptable in a `site.skupper.io` `spec` field can be set here, such as `ha`, `defaultIssuer` or `edge`.

The second variable `site_resources` is system-site-specific, and a temporary measure while a more sofisticated solution is developed: system sites require `RouterAccess` resources to be defined explicitly (whereas the controller on kubernetes sites which create them based on `spec.linkAccess`).

So, on the example above, the two variables are complementary: one allows the site to receive router connections on kube, the other on non-kube.

`site_resources` will be created as-is, and only for system sites.

:!: **Attention**: at this level, you don't know whether the hosts are system or kubernetes sites.  And, if they're system sites, more than one could reside in a single VM (for example, for testing Podman and Docker sites running side by side).  For that reason, make sure any ports you declare on your topology are unique for the topology.

There are three major groups at this time:

- backends
- frontends
- hubs

[comment]: # in the future, perhaps add at least one more group: DB.  Perhaps also DMZ, but then hubs may be just that.  DBs may be backends, too, but in general single deployment?

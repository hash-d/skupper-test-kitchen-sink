
# To be done on Glue:
#
# - Install skupper-router, proper version: rpm, build, etc
# - docker and podman login on registry.redhat.io, for released runs
#   * Attention to DOCKER_HOST pointing to podman when doing this

# ansible-galaxy collection install skupper.v2:2.0.0
# # https://github.com/skupperproject/skupper-ansible/issues/71
# # Released collection 2.0 cannot set SKUPPER_ROUTER_IMAGE; take it from the branch
# ansible-galaxy collection install git@github.com:skupperproject/skupper-ansible.git,2.0
# sudo dnf install skupper-cli-2.0.1 skupper-router-3.3.1
#
# ansible-galaxy collection install skupper.v2:2.1.1
system-1:
	ansible-playbook \
		-i inventory/basic \
		-i inventory/topology/system-1/ \
		-i inventory/apps/hello/ \
		-i inventory/local/dh-sink.yaml \
		-i inventory/local/rhsi-$(SKUPPER_VERSION).yaml \
		-v \
		$(OPTIONS) \
		test.yaml

system-1-teardown:
	ansible-playbook \
		-i inventory/basic \
		-i inventory/topology/system-1/ \
		-i inventory/apps/hello/ \
		-i inventory/local/dh-sink.yaml \
		-i inventory/local/rhsi-$(SKUPPER_VERSION).yaml \
		-v \
		$(OPTIONS) \
		teardown.yaml

.PHONY: inventory
system-1-inventory:
	ansible-inventory \
		-i inventory/basic \
		-i inventory/topology/system-1/ \
		-i inventory/apps/hello/ \
		-i inventory/local/dh-sink.yaml \
		-i inventory/local/rhsi-$(SKUPPER_VERSION).yaml \
		--list -y all

single:
	ansible-playbook \
		-i inventory/basic \
		-i inventory/topology/system-single/ \
		-i inventory/local/ \
		-v \
		$(OPTIONS) \
		test.yaml

# kube-1
kube-1-setup:
	ansible-playbook \
		-i inventory/basic \
		-i inventory/topology/kube-1/ \
		-i inventory/apps/hello/ \
		-i inventory/local/dh-kube.yaml \
		-i inventory/local/rhsi-$(SKUPPER_VERSION).yaml \
		-v \
		$(OPTIONS) \
		setup.yaml

kube-1:
	ansible-playbook \
		-i inventory/basic \
		-i inventory/topology/kube-1/ \
		-i inventory/apps/hello/ \
		-i inventory/local/dh-kube.yaml \
		-i inventory/local/rhsi-$(SKUPPER_VERSION).yaml \
		-v \
		$(OPTIONS) \
		test.yaml

kube-1-teardown:
	ansible-playbook \
		-i inventory/basic \
		-i inventory/topology/kube-1/ \
		-i inventory/apps/hello/ \
		-i inventory/local/dh-kube.yaml \
		-i inventory/local/rhsi-$(SKUPPER_VERSION).yaml \
		-v \
		$(OPTIONS) \
		teardown.yaml

.PHONY: inventory
kube-1-inventory:
	ansible-inventory \
		-i inventory/basic \
		-i inventory/topology/kube-1/ \
		-i inventory/apps/hello/ \
		-i inventory/local/dh-kube.yaml \
		-i inventory/local/rhsi-$(SKUPPER_VERSION).yaml \
		--list -y all

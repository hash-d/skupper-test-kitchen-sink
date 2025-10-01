
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
#

RANDOM != echo $$RANDOM | sha1sum | cut -c -5
# if ansible gets something like 123e10, it thinks it's a number in scientific
# format and goes haywire; that's whey the ks- prefix is required, here
TEST_ID ?= ks-$(RANDOM)

system-1:
	ansible-playbook \
		-i inventory/basic \
		-i inventory/topology/system-1/ \
		-i inventory/apps/hello/ \
		-i inventory/local/dh-sink.yaml \
		-i inventory/version/rhsi-$(SKUPPER_VERSION).yaml \
		-v \
		$(OPTIONS) \
		test.yaml

system-1-teardown:
	ansible-playbook \
		-i inventory/basic \
		-i inventory/topology/system-1/ \
		-i inventory/apps/hello/ \
		-i inventory/local/dh-sink.yaml \
		-i inventory/version/rhsi-$(SKUPPER_VERSION).yaml \
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
		-i inventory/version/rhsi-$(SKUPPER_VERSION).yaml \
		--list -y all

single:
	ansible-playbook \
		-i inventory/basic \
		-i inventory/topology/system-single/ \
		-i inventory/local/ \
		-v \
		$(OPTIONS) \
		test.yaml

check:
	ansible-playbook \
		-i inventory/basic \
		-i inventory/topology/$(TOPO)/ \
		-i inventory/apps/$(APP)/ \
		-i inventory/version/rhsi-$(SKUPPER_VERSION).yaml \
		-i inventory/local/$(LOCAL) \
		-e test_id=$(TEST_ID) \
		-v \
		$(OPTIONS) \
		check.yaml
		#-i inventory/version/rhsi-$(SKUPPER_VERSION).yaml \

setup:
	ansible-playbook \
		-i inventory/basic \
		-i inventory/topology/$(TOPO)/ \
		-i inventory/apps/$(APP)/ \
		-i inventory/version/rhsi-$(SKUPPER_VERSION).yaml \
		-i inventory/local/$(LOCAL) \
		-e test_id=$(TEST_ID) \
		-v \
		$(OPTIONS) \
		setup.yaml

verify:
	ansible-playbook \
		-i inventory/basic \
		-i inventory/topology/$(TOPO)/ \
		-i inventory/apps/$(APP)/ \
		-i inventory/version/rhsi-$(SKUPPER_VERSION).yaml \
		-i inventory/local/$(LOCAL) \
		-v \
		-e test_id=$(TEST_ID) \
		$(OPTIONS) \
		verify.yaml

teardown:
	ansible-playbook \
		-i inventory/basic \
		-i inventory/topology/$(TOPO)/ \
		-i inventory/apps/$(APP)/ \
		-i inventory/version/rhsi-$(SKUPPER_VERSION).yaml \
		-i inventory/local/$(LOCAL) \
		-v \
		-e test_id=$(TEST_ID) \
		$(OPTIONS) \
		teardown.yaml
		# not necessary for kube, yet
		# -i inventory/version/rhsi-$(SKUPPER_VERSION).yaml \

gen_dir:
	[ -d generated ] || mkdir generated

inv-list:
	ansible-inventory \
		-i inventory/basic \
		-i inventory/topology/$(TOPO)/inv.yaml \
		-i inventory/apps/$(APP)/ \
		-i inventory/version/rhsi-$(SKUPPER_VERSION).yaml \
		-i inventory/local/$(LOCAL) \
		$(OPTIONS) \
		--list -y all

.PHONY: inventory
inventory: gen_dir inv-list
	ansible-playbook \
		-i inventory/basic \
		-i inventory/topology/$(TOPO)/ \
		-i inventory/apps/$(APP)/ \
		-i inventory/version/rhsi-$(SKUPPER_VERSION).yaml \
		-i inventory/local/$(LOCAL)/ \
		$(OPTIONS) \
		inventory.yaml
	dot -Tpdf generated/inventory.dot -o generated/inventory.pdf
		#-i inventory/version/rhsi-$(SKUPPER_VERSION).yaml \

test:
	ansible-playbook \
		-i inventory/basic \
		-i inventory/topology/$(TOPO)/ \
		-i inventory/apps/$(APP)/ \
		-i inventory/version/rhsi-$(SKUPPER_VERSION).yaml \
		-i inventory/local/$(LOCAL) \
		-v \
		-e test_id=$(TEST_ID) \
		$(OPTIONS) \
		test.yaml
		# not necessary for kube, yet

reload:
	ansible-playbook \
		-i inventory/basic \
		-i inventory/topology/$(TOPO)/ \
		-i inventory/apps/$(APP)/ \
		-i inventory/version/rhsi-$(SKUPPER_VERSION).yaml \
		-i inventory/local/$(LOCAL) \
		-v \
		-e test_id=$(TEST_ID) \
		$(OPTIONS) \
		reload.yaml
		# not necessary for kube, yet

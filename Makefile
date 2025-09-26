
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
# TODO refactor:
# - Do we need all these targets?  Force the caller to define TOPOLOGY,
#   APP and SKUPPER_VERSION, they all should be the same
# - Even setup/teardown/main: is it necessary?  They could be made into
#   tags on test.yaml
# - local/rhsi-$(SKUPPER_VERSION).yaml should move to versions/rhsi-$(SKUPPER_VERSION).yaml,
#   instead
# - One more required parameter: LOCAL, to select a single file or directory
#   within inventory/local:  `-i inventory/local/$( LOCAL )`.  The idea is to
#   allow the user to have several prepared local inventories and select one of them

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

check:
	ansible-playbook \
		-i inventory/basic \
		-i inventory/topology/$(TOPO)/ \
		-i inventory/apps/$(APP)/ \
		-i inventory/local/$(LOCAL) \
		-e test_id=$(TEST_ID) \
		-v \
		$(OPTIONS) \
		check.yaml
		#-i inventory/local/rhsi-$(SKUPPER_VERSION).yaml \

setup:
	ansible-playbook \
		-i inventory/basic \
		-i inventory/topology/$(TOPO)/ \
		-i inventory/apps/$(APP)/ \
		-i inventory/local/$(LOCAL) \
		-e test_id=$(TEST_ID) \
		-v \
		$(OPTIONS) \
		setup.yaml
		#-i inventory/local/rhsi-$(SKUPPER_VERSION).yaml \

verify:
	ansible-playbook \
		-i inventory/basic \
		-i inventory/topology/$(TOPO)/ \
		-i inventory/apps/$(APP)/ \
		-i inventory/local/$(LOCAL) \
		-v \
		-e test_id=$(TEST_ID) \
		$(OPTIONS) \
		verify.yaml
		# not necessary for kube, yet
		#-i inventory/local/rhsi-$(SKUPPER_VERSION).yaml \

teardown:
	ansible-playbook \
		-i inventory/basic \
		-i inventory/topology/$(TOPO)/ \
		-i inventory/apps/$(APP)/ \
		-i inventory/local/$(LOCAL) \
		-v \
		-e test_id=$(TEST_ID) \
		$(OPTIONS) \
		teardown.yaml
		# not necessary for kube, yet
		# -i inventory/local/rhsi-$(SKUPPER_VERSION).yaml \

gen_dir:
	[ -d generated ] || mkdir generated

.PHONY: inventory
inventory: gen_dir
	ansible-inventory \
		-i inventory/basic \
		-i inventory/topology/$(TOPO)/inv.yaml \
		-i inventory/apps/$(APP)/ \
		-i inventory/local/$(LOCAL) \
		$(OPTIONS) \
		--list -y all
	ansible-playbook \
		-i inventory/basic \
		-i inventory/topology/$(TOPO)/ \
		-i inventory/apps/$(APP)/ \
		-i inventory/local/$(LOCAL)/ \
		$(OPTIONS) \
		inventory.yaml
	dot -Tpdf generated/inventory.dot -o generated/inventory.pdf
		#-i inventory/local/rhsi-$(SKUPPER_VERSION).yaml \

test:
	ansible-playbook \
		-i inventory/basic \
		-i inventory/topology/$(TOPO)/ \
		-i inventory/apps/$(APP)/ \
		-i inventory/local/$(LOCAL) \
		-v \
		-e test_id=$(TEST_ID) \
		$(OPTIONS) \
		test.yaml
		# not necessary for kube, yet
		# -i inventory/local/rhsi-$(SKUPPER_VERSION).yaml \

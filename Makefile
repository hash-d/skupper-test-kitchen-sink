
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

RANDOM != echo $$RANDOM | sha1sum | cut -c -5

# if ansible gets something like 123e10, it thinks it's a number in scientific
# format and goes haywire; that's whey the ks- prefix is required, here
TEST_ID ?= ks-$(RANDOM)

TEST_FLAGS = \
	$(TEST_INV_FLAGS) \
	-e test_id=$(TEST_ID) \
	$(OPTIONS)

TEST_INV_FLAGS = \
	-i inventory/basic \
	-i inventory/topology/$(TOPO)/ \
	-i inventory/apps/$(APP)/ \
	-i inventory/version/rhsi-$(SKUPPER_VERSION).yaml \
	-i inventory/local/$(LOCAL) \

test:
	ansible-playbook $(TEST_FLAGS) test.yaml

check:
	ansible-playbook $(TEST_FLAGS) check.yaml

setup:
	ansible-playbook $(TEST_FLAGS) setup.yaml

verify:
	ansible-playbook $(TEST_FLAGS) verify.yaml

teardown:
	ansible-playbook $(TEST_FLAGS) teardown.yaml

inv-list:
	ansible-inventory $(TEST_INV_FLAGS) $(OPTIONS) --list -y all

gen_dir:
	[ -d generated ] || mkdir generated


.PHONY: inventory
inventory: gen_dir inv-list
	ansible-playbook $(TEST_FLAGS) inventory.yaml
	fdp -Tpdf generated/inventory.dot -o generated/inventory.pdf

reload:
	ansible-playbook $(TEST_FLAGS) reload.yaml

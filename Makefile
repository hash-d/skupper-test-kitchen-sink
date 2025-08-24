
basic:
	ansible-playbook \
		-i inventory/basic \
		-i inventory/topology/system-1/ \
		-i inventory/apps/hello/ \
		-i inventory/local/ \
		-v \
		$(OPTIONS) \
		test.yaml

teardown:
	ansible-playbook \
		-i inventory/basic \
		-i inventory/topology/system-1/ \
		-i inventory/apps/hello/ \
		-i inventory/local/ \
		-v \
		$(OPTIONS) \
		teardown.yaml

.PHONY: inventory
inventory:
	ansible-inventory \
		-i inventory/basic \
		-i inventory/topology/system-1/ \
		-i inventory/apps/hello/ \
		-i inventory/local/ \
		--list -y all

single:
	ansible-playbook \
		-i inventory/basic \
		-i inventory/topology/system-single/ \
		-i inventory/local/ \
		-v \
		$(OPTIONS) \
		test.yaml


basic:
	ansible-playbook \
		-i inventory/basic \
		-i inventory/topology/system-1/ \
		-v \
		$(OPTIONS) \
		test.yaml

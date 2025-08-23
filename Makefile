
basic:
	ansible-playbook \
		-i inventory/topology/non-kube-1/ \
		-v \
		$(OPTIONS) \
		test.yaml

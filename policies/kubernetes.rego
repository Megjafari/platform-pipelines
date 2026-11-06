package main

import rego.v1

workloads := {"Deployment", "StatefulSet", "DaemonSet"}

containers contains container if {
	workloads[input.kind]
	some container in input.spec.template.spec.containers
}

deny contains msg if {
	workloads[input.kind]
	not input.spec.template.spec.securityContext.runAsNonRoot
	msg := sprintf("%s/%s must set spec.template.spec.securityContext.runAsNonRoot", [input.kind, input.metadata.name])
}

deny contains msg if {
	some container in containers
	endswith(container.image, ":latest")
	msg := sprintf("container %s must not use the :latest tag", [container.name])
}

deny contains msg if {
	some container in containers
	not contains(container.image, ":")
	msg := sprintf("container %s must pin an image tag or digest", [container.name])
}

deny contains msg if {
	some container in containers
	not container.resources.limits.memory
	msg := sprintf("container %s must set a memory limit", [container.name])
}

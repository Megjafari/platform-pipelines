package main

import rego.v1

good := {
	"kind": "Deployment",
	"metadata": {"name": "app"},
	"spec": {"template": {"spec": {
		"securityContext": {"runAsNonRoot": true},
		"containers": [{
			"name": "app",
			"image": "ghcr.io/example/app:1.0.0",
			"resources": {"limits": {"memory": "64Mi"}},
		}],
	}}},
}

test_good_deployment_passes if {
	count(deny) == 0 with input as good
}

test_latest_tag_is_denied if {
	bad := json.patch(good, [{"op": "replace", "path": "/spec/template/spec/containers/0/image", "value": "app:latest"}])
	count(deny) == 1 with input as bad
}

test_missing_tag_is_denied if {
	bad := json.patch(good, [{"op": "replace", "path": "/spec/template/spec/containers/0/image", "value": "app"}])
	count(deny) == 1 with input as bad
}

test_root_is_denied if {
	bad := json.patch(good, [{"op": "remove", "path": "/spec/template/spec/securityContext"}])
	count(deny) == 1 with input as bad
}

test_missing_memory_limit_is_denied if {
	bad := json.patch(good, [{"op": "remove", "path": "/spec/template/spec/containers/0/resources"}])
	count(deny) == 1 with input as bad
}

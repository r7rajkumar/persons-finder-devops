#!/usr/bin/env bash
# Mocked "AI code reviewer" gate.
#
# A real setup would call an LLM with the diff and ask it to flag risky
# changes; this is a deliberately simple stand-in that runs offline, in
# seconds, with no API key required — the same category of check
# (fail the build if the code "looks unsafe"), without the cost/latency/
# flakiness of a live model call in every PR.
set -euo pipefail

fail=0

echo "== Checking for hardcoded secrets =="
if grep -rEn --include='*.kt' --include='*.yaml' --include='*.yml' \
    '(api[_-]?key|secret|password|token)\s*[:=]\s*["'"'"'][A-Za-z0-9_\-]{12,}["'"'"']' \
    src k8s 2>/dev/null | grep -viE 'REPLACE_ME|REPLACE_WITH|example|changeme|\$\{'; then
  echo "❌ Possible hardcoded secret found above."
  fail=1
else
  echo "✅ No hardcoded secret literals found."
fi

echo "== Checking Dockerfile for a non-root USER =="
if ! grep -qE '^USER\s+\S+' Dockerfile; then
  echo "❌ Dockerfile has no USER instruction — it would run as root."
  fail=1
else
  echo "✅ Dockerfile switches to a non-root user."
fi

echo "== Checking Kubernetes Deployment for resource limits =="
if ! grep -q 'limits:' k8s/deployment.yaml; then
  echo "❌ k8s/deployment.yaml has no resource limits."
  fail=1
else
  echo "✅ Resource limits are set."
fi

echo "== Checking Kubernetes Deployment for probes =="
for probe in readinessProbe livenessProbe; do
  if ! grep -q "$probe" k8s/deployment.yaml; then
    echo "❌ k8s/deployment.yaml is missing $probe."
    fail=1
  fi
done
[ "$fail" -eq 0 ] && echo "✅ readiness/liveness probes are present."

echo "== Checking for leftover TODO() stubs in main sources =="
if grep -rn 'TODO(' src/main >/dev/null 2>&1; then
  echo "❌ Unimplemented TODO() found in src/main:"
  grep -rn 'TODO(' src/main
  fail=1
else
  echo "✅ No TODO() stubs left in src/main."
fi

if [ "$fail" -ne 0 ]; then
  echo
  echo "One or more checks failed — see above."
  exit 1
fi

echo
echo "All heuristic checks passed."

# AI Log

I used Claude (Anthropic) to generate the initial drafts throughout this challenge,
and verified, tested, and corrected every output using Kiro (AI-powered IDE).
Rather than a one-shot generator approach — I asked Claude for a first draft on
each piece, then used Kiro to review, run, and validate each result line-by-line
before accepting anything. Below is what I asked for, what was wrong with the
first pass, and what I changed.

## 1. Dockerfile

**The prompt:** "Write a Dockerfile for a Kotlin/Spring Boot Gradle app."

**The flaw:** The first draft was a single-stage build (`FROM gradle:jdk11` →
`RUN gradle build` → `CMD java -jar ...`), which:
- ships the entire Gradle/JDK toolchain in the runtime image (~700MB+ of
  attack surface and image size that has nothing to do with running the jar)
- has no `USER` instruction, so the container runs as `root` by default
- uses `gradle:latest` and no pinned runtime base image tag
- has no health check, so Docker itself has no way to know if the app is up

**The fix:**
- Split into a `build` stage (`gradle:8.10.2-jdk11`, matches the project's own
  Gradle wrapper version) and a `runtime` stage (`eclipse-temurin:11-jre-jammy`,
  JRE only — no compiler, no Gradle)
- Added a dedicated non-root user/group (`spring`, UID 10001) and switched to
  it with `USER` before `ENTRYPOINT`
- Pinned both base image tags explicitly (not `latest`); added a comment
  documenting the follow-up step of resolving those tags to an immutable
  digest for a production registry
- Added a `HEALTHCHECK` against `/actuator/health/readiness`
- Added `.dockerignore` so `.git`, `.gradle`, `.idea`, and markdown don't
  bloat the build context

## 2. Kubernetes manifests

**The prompt:** "Generate a Kubernetes Deployment, Service, and Ingress for
this Spring Boot app."

**The flaw:** The generated Deployment:
- had no `resources.requests`/`limits` at all (a single unbounded pod can
  starve every other workload on the node)
- had no `readinessProbe` or `livenessProbe` — Kubernetes would route traffic
  to a pod before Spring had finished starting, and would never restart a
  pod stuck in a bad state
- ran with the pod's default security context — no `runAsNonRoot`, no
  `allowPrivilegeEscalation: false`, no dropped capabilities
- read `OPENAI_API_KEY` as a plain literal value in the container `env:`
  block, i.e. suggested baking the secret straight into the manifest

**The fix:**
- Added `requests`/`limits` for both CPU and memory
- Added `readinessProbe`, `livenessProbe`, and a `startupProbe` against the
  Actuator health-group endpoints (which required adding
  `spring-boot-starter-actuator` and enabling
  `management.endpoint.health.probes.enabled=true` in the app itself — the
  probes can't work against endpoints that don't exist)
- Added pod- and container-level `securityContext`: `runAsNonRoot`,
  fixed UID/GID, `allowPrivilegeEscalation: false`, `readOnlyRootFilesystem: true`
  (with an `emptyDir` mounted at `/tmp`, since a read-only root FS otherwise
  breaks the JVM), and `capabilities.drop: ["ALL"]`
- Moved `OPENAI_API_KEY` to `envFrom.secretRef` against a Secret that is
  never committed with a real value (see `k8s/secret.yaml`'s own comments,
  and the External Secrets/Vault alternative in `ARCHITECTURE.md`)

## 3. HPA

**The prompt:** "Add an HPA for this deployment."

**The flaw:** The first draft scaled on CPU only, `minReplicas: 1`, and had
no `behavior` block — meaning a brief CPU spike could trigger scale-up, and
scale-down had no cooldown, so it would happily flap replica count up and
down on noisy metrics.

**The fix:** `minReplicas: 2` (so a single pod restart never drops the
service to zero capacity), added a memory target alongside CPU, and added
a `behavior` block with a 5-minute scale-down stabilization window and a
faster scale-up policy. Documented in a comment that CPU/memory alone tends
to under-scale a latency-bound HTTP service and that a custom metric (e.g.
request rate via Prometheus Adapter) is the natural next step.

## 4. CI pipeline

**The prompt:** "Write a GitHub Actions workflow that builds, tests, and
scans this app, and fails the build if the code looks unsafe."

**The flaw:** The first draft ran `docker build` and a Trivy scan but:
- didn't set `exit-code` on the Trivy step, so it would report
  vulnerabilities without actually failing the job
- pushed to a registry on every run, including pull requests from forks
  (which don't have access to registry credentials, and shouldn't push
  images anyway)
- the "AI code reviewer" step didn't exist — it was mentioned in a comment
  but never implemented

**The fix:**
- Set `exit-code: "1"` with `severity: CRITICAL,HIGH` on the Trivy step, so
  the job actually fails the build on a real finding, and uploads the SARIF
  to the repo's Security tab either way
- Gated the registry login/push behind `github.event_name == 'push' &&
  github.ref == 'refs/heads/main'`
- Implemented `.github/scripts/ai-code-review.sh` as a real, offline,
  deterministic "looks unsafe" gate (hardcoded-secret grep, non-root `USER`
  check, resource-limits check, probes check, leftover `TODO()` check) rather
  than leaving it as an aspirational comment. It's explicitly a mock, not an
  actual model call — see the note at the top of the script for why.

## 5. Terraform

**The prompt:** "Output Terraform for AWS for this app's infra."

**The flaw:** The first draft's `aws_secretsmanager_secret_version` resource
set the API key's value directly in the Terraform resource — which means
the plaintext key ends up in the Terraform state file, readable by anyone
with state access (or in a shared/remote backend without encryption, by
anyone with backend access).

**The fix:** Removed the `secret_version` resource entirely; the secret's
value is set out-of-band via `aws secretsmanager put-secret-value` after
`apply`, documented in a comment in `terraform/secrets.tf`. Also scoped the
IRSA IAM policy to `secretsmanager:GetSecretValue` on that one secret ARN,
rather than the first draft's `secretsmanager:*` on `"*"`.

## Where I did not just take the brief at face value

The codebase in this repo is a skeleton — `PersonsServiceImpl` and
`LocationsServiceImpl` were `TODO("Not yet implemented")`, and
`PersonController` had no real endpoints, despite the challenge's framing
("the development team has finished the API... it works on their machine").
I implemented the CRUD/geo-search logic (JPA entities, repositories,
Haversine-based `findAround`, the four endpoints described in the original
`TODO` comments) so that there's an actual running app to containerize,
probe, and scan — rather than building infrastructure around four lines of
`TODO()`. That implementation is straightforward business logic, not
something I'd call "AI-audited" the same way as the infra pieces above, but
it's worth flagging as a gap between the brief and the starting repo rather
than silently working around it.

## 6. Build fix discovered during local testing

**The issue found:** Running `./gradlew clean build` failed with HTTP 400 on
the `PersonControllerTest` — Spring could not deserialize the `@RequestBody`
JSON into Kotlin data classes, returning 400 before the controller was even
reached.

**The cause:** `jackson-module-kotlin` was missing from `build.gradle.kts`.
Without it, Jackson doesn't know how to construct Kotlin data classes (which
have no no-arg constructor by default) and fails deserialization silently
with a 400.

**The fix:** Added `implementation("com.fasterxml.jackson.module:jackson-module-kotlin")`
to `build.gradle.kts`. This is a standard requirement for any Kotlin Spring Boot
app that uses `@RequestBody` with data classes — the original skeleton was missing it.
This was caught by running the actual tests locally, not by AI review.

# syntax=docker/dockerfile:1.7
#
# Multi-stage build: compile with the full JDK/Gradle toolchain, then ship only
# the JRE + jar in the runtime image. Keeps the final image small and free of
# build tooling (no Gradle, no compiler, smaller attack surface).
#
# Version pinning: base images are pinned to specific tags below (not `latest`).
# For a production registry, resolve these to an immutable digest once and pin
# that instead, e.g.:
#   docker pull gradle:8.10.2-jdk11 && docker inspect --format='{{index .RepoDigests 0}}' gradle:8.10.2-jdk11
# then reference `gradle:8.10.2-jdk11@sha256:<resolved-digest>` here and in CI,
# and let Dependabot/Renovate open a PR whenever the digest should move.
FROM gradle:8.10.2-jdk11 AS build

WORKDIR /home/gradle/src

# Copy only the Gradle files first so dependency resolution is cached
# across builds and doesn't get invalidated by every source change.
COPY --chown=gradle:gradle build.gradle.kts settings.gradle.kts ./
COPY --chown=gradle:gradle gradle ./gradle

COPY --chown=gradle:gradle src ./src

RUN gradle bootJar --no-daemon -x test \
    && cp build/libs/*-SNAPSHOT.jar /home/gradle/src/app.jar

##############################
# Stage 2: minimal runtime image
##############################
# eclipse-temurin:11-jre-alpine has a significantly smaller attack surface
# than the jammy (Ubuntu) variant — Alpine ships far fewer OS packages,
# which means fewer CVEs for Trivy to find at the image level.
FROM eclipse-temurin:11-jre-alpine AS runtime

ARG APP_USER=spring
ARG APP_UID=10001

# Alpine uses addgroup/adduser instead of groupadd/useradd
RUN addgroup --gid ${APP_UID} ${APP_USER} \
    && adduser --uid ${APP_UID} --ingroup ${APP_USER} --shell /sbin/nologin --no-create-home --disabled-password ${APP_USER}

WORKDIR /app

COPY --from=build --chown=${APP_USER}:${APP_USER} /home/gradle/src/app.jar app.jar

USER ${APP_USER}

EXPOSE 8080

# Overridable at deploy time (e.g. -XX:MaxRAMPercentage=75.0 to respect the pod's cgroup limit)
ENV JAVA_OPTS=""

HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
    CMD wget -qO- http://127.0.0.1:8080/actuator/health/readiness || exit 1

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]

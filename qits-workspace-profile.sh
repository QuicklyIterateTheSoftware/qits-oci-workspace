# Sourced by every login shell (/etc/profile.d). The workspace daemon runs EVERY command it starts
# as `bash -lc` — builds, actions, service supervision and both coding-agent harnesses — so this
# runs ahead of any build without this image owning an entrypoint and without a change to the
# daemon that is PID 1.
#
# Both fixes are idempotent and both fail soft: a login shell is never worth breaking over them.

# --- 1. give the container's arbitrary uid a name -------------------------------------------------
# The container runs as the deployment host's uid (qits-workspaces passes `--user <uid>`, group 0)
# and this image cannot know that number at build time, so the uid resolves to no user at all.
# Almost every tool is content with that. PostgreSQL is not: `initdb` calls getpwuid() and refuses
# to run when it cannot name its own user —
#
#     initdb: could not look up effective user ID 1000: user does not exist
#
# — so EVERY test that starts an embedded PostgreSQL fails inside a workspace and passes everywhere
# else: a developer machine has a passwd entry, and CI builds in a different image. That makes the
# gap invisible until someone runs a suite here. qits-deployments, qits-githost and
# qits-platform-edge all carry such suites today.
#
# /etc/passwd is group-writable for group 0 (see the Dockerfile, which explains the trade-off);
# the `-w` test is what keeps this silent rather than noisy where it is not.
if ! getent passwd "$(id -u)" >/dev/null 2>&1 && [ -w /etc/passwd ]; then
  printf 'qits:x:%s:%s:qits workspace:%s:/bin/bash\n' \
    "$(id -u)" "$(id -g)" "${HOME:-/workspace}" >> /etc/passwd
fi

# --- 2. point Maven at the platform's repository --------------------------------------------------
# Maven 3.8+ refuses plain-HTTP repositories outright, and every qits pom declares its platform
# repository as `qits-maven` over http (there is no TLS inside qits-net). Without the settings file
# a workspace build dies before it reaches the network, naming a blocker rather than a cause:
#
#     Blocked mirror for repositories: [qits-maven (http://…, default, releases+snapshots)]
#       ... from/to maven-default-http-blocker (http://0.0.0.0/)
#
# MAVEN_ARGS (Maven 3.9+) applies it to `./mvnw` as well as `mvn`, which matters because every
# repository here builds through its wrapper.
#
# INERT UNTIL THE DEPLOYMENT TELLS US THE ADDRESS. The settings file's mirror URL is
# ${env.QITS_MAVEN_REPOSITORY_URL}, which Maven leaves unexpanded when the variable is unset — so
# the flag is added only when qits-workspaces has injected a real address, and an older platform
# that injects none behaves exactly as it did before rather than failing against a literal
# "${env...}" URL.
if [ -n "${QITS_MAVEN_REPOSITORY_URL:-}" ]; then
  case " ${MAVEN_ARGS:-} " in
    # A caller that named its own settings keeps them — a repository's own
    # .qits-maven-settings.xml must still win when someone passes it.
    *" -s "* | *" --settings "*) : ;;
    *) MAVEN_ARGS="${MAVEN_ARGS:+$MAVEN_ARGS }-s /etc/qits/maven-settings.xml"; export MAVEN_ARGS ;;
  esac
fi

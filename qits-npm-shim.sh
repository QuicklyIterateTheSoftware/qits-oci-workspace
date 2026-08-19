#!/bin/sh
# npm, with the platform's @qits scope pointed at the registry that actually serves it.
#
# WHY A SHIM AND NOT ENVIRONMENT. npm's only spelling for a scoped registry is the config key
# `@qits:registry`, whose environment form is `npm_config_@qits:registry` — a name containing `@`
# and `:`. That name cannot travel the normal route:
#
#   * qits-containers refuses it (`Invalid environment key`), and rightly: its env keys are
#     POSIX-shaped on purpose, and widening a platform-wide validator to admit one tool's
#     convention is the wrong trade; and
#   * a shell cannot create it either — `export 'npm_config_@qits:registry=…'` is "not a valid
#     identifier" in every POSIX shell — so /etc/profile.d cannot set it, the way it does set
#     MAVEN_ARGS.
#
# A process CAN inherit such a name (measured: bash passes it through untouched and `npm config get
# @qits:registry` reads it), which is what makes `env` in the exec below work where `export` cannot.
#
# WHY NOT A .npmrc. npm ranks a PROJECT .npmrc above the user and global ones, and every SPA here
# commits one naming the deployment host's own port — an address that does not exist inside a
# container. Only the command line and the environment outrank it, so nothing written to a file in
# HOME could win.
#
# INERT UNTIL TOLD, like the Maven half: with QITS_WORKSPACE_NPM_REGISTRY_URL unset this is a plain
# exec and npm behaves exactly as it always did.
if [ -n "${QITS_WORKSPACE_NPM_REGISTRY_URL:-}" ]; then
  exec env "npm_config_@qits:registry=$QITS_WORKSPACE_NPM_REGISTRY_URL" /usr/bin/npm "$@"
fi
exec /usr/bin/npm "$@"

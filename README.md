# qits-oci-workspace

The workspace toolchain base image, published as **`qits/workspace-base`**.

It holds the tools a workspace container needs to work on a checkout: git and a shell toolchain,
JDK 25, node + pnpm, python, a pinned Playwright Chromium with a pinned font stack, the coding agent
CLIs (Claude Code, Kimi Code), and language servers (jdtls, typescript-language-server). Every
package is commented in the `Dockerfile` with the reason it is there. Read that before changing
anything.

It carries no daemon binary and no entrypoint. It is a base, not a runnable workspace.

## What consumes it

`qits-workspace-daemon`'s `docker/Dockerfile.workspace` layers the daemon binary on top of this
image and entrypoints to it. That result is the image a workspace container runs. The project-agent
images do the same thing for their own binary.

The published name is `qits/workspace-base`, not the repository name, because that is the name those
Dockerfiles already write.

## Building by hand

    docker build -t qits/workspace-base:latest .

Expect a long, network-heavy build — roughly 3.4 GB of image, fetching two apt trees, a JDK, node,
a Chromium and several CLIs. CI allows two hours for it.

## Provenance — why this repository exists

Before this repository, the recipe lived only at
`~/code/qits-backend-devel/docker/qits/Dockerfile` as the `workspace` stage of the pre-split
monolith. That was the sole copy, it sat outside every repository, and it existed only on one
developer's disk. No CI could build a workspace image, and three Dockerfile headers elsewhere
pointed at it by a name it did not have.

The `Dockerfile` here is that stage copied verbatim, comments and pinned versions included. The one
change is dropping ` AS workspace` from the `FROM`, since the stage is now the whole image. It
therefore produces the same image the platform runs today.

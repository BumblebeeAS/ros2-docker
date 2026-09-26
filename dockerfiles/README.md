# Dockerfiles

Dockerfiles are grouped by the narrowest platform constraint imposed by the layer:

| Directory      | Compatibility                                                                           |
| -------------- | --------------------------------------------------------------------------------------- |
| `common`       | Architecture-independent layers, or layers that select artifacts by target architecture |
| `amd64`        | Linux amd64/x86_64                                                                      |
| `arm64`        | Linux arm64/aarch64                                                                     |
| `environments` | Project environment assembly                                                            |

## Design Note

We have a separate `environments` directory to split by role rather than by platform.

These Dockerfiles don't belong in `common` since they are not reusable capabilities. Keeping them separate leaves `common` a library of layers any project may reuse, and files project layers together.

These Dockerfiles should near at the end of a `CONFIG_IMAGE_KEY` chain (before `install_env`), and is bound to its sibling `environments/<name>/` directory through `LOCAL_ENV_FOLDER`, which `Dockerfile.install_env` reads to copy that project's files into the image.

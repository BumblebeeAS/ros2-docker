#!/usr/bin/env python3
#
# Adapted from NVIDIA's Isaac ROS layered image builder:
#   https://github.com/NVIDIA-ISAAC-ROS/isaac-ros-cli
#   scripts/run_dev/build_image_layers.py
#
# Ported from upstream: sourcing the shell environment config, the greedy
# image-key resolution, the bake-dict and HCL generation, and driving
# `docker buildx bake` over the generated file.
#
# Dropped: registry / S3 / NGC layer caching, the Kubernetes builder driver,
# content-hashed target names, multi-arch builds and --push. None of them apply
# to local development images built against a single base image.
#
# Changed: upstream chains layers by intermediate tag and invokes bake once per
# layer, which keeps the build serial so each layer can be pushed to or pulled
# from a cache registry. Without that registry, layers here chain through named
# `previous_layer` build contexts instead, so a single bake invocation builds
# the whole graph and independent layers run in parallel.

import argparse
import os
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Dict, List, Optional, Tuple

ROOT = Path(__file__).resolve().parent

# Mirrors utils/print_color.sh so output matches the rest of the tooling.
ERROR = "\033[0;31m"
SUCCESS = "\033[0;32m"
WARNING = "\033[0;33m"
INFO = "\033[0;36m"
NC = "\033[0m"

CONFIG_KEYS = [
    "CONFIG_IMAGE_KEY",
    "CONFIG_DOCKER_SEARCH_DIRS",
    "BUILT_IMAGE",
    "DOCKER_CONTEXT_DIR",
    "DOCKER_BUILD_BASE_IMAGE",
]


# Progress goes to stderr so stdout carries only the generated Bake file.
def print_error(message):
    print(f"{ERROR}{message}{NC}", file=sys.stderr)


def print_success(message):
    print(f"{SUCCESS}{message}{NC}", file=sys.stderr)


def print_warning(message):
    print(f"{WARNING}{message}{NC}", file=sys.stderr)


def print_info(message):
    print(f"{INFO}{message}{NC}", file=sys.stderr)


def run_shell(
    command: str, capture_output=True, verbose=False, check=False, env=None
) -> Tuple[bool, str, str]:
    """Run a shell command in a subprocess and return the result."""
    if verbose:
        print_warning(command)

    os_env = os.environ.copy()
    if env:
        os_env.update(env)
    # Always run with check=False so stdout/stderr can be surfaced before raising.
    completed_process = subprocess.run(
        command,
        capture_output=capture_output,
        text=True,
        check=False,
        shell=True,
        env=os_env,
    )
    if check and completed_process.returncode != 0:
        if capture_output:
            if completed_process.stdout:
                print(completed_process.stdout, flush=True)
            if completed_process.stderr:
                print(completed_process.stderr, file=sys.stderr, flush=True)
        raise subprocess.CalledProcessError(
            completed_process.returncode,
            completed_process.args,
            output=completed_process.stdout,
            stderr=completed_process.stderr,
        )
    return (
        completed_process.returncode == 0,
        completed_process.stdout,
        completed_process.stderr,
    )


def extract_env_vars(source_filepath: Path, keys: List[str]) -> Optional[Dict]:
    """Source a shell config and read the requested variables out of it."""
    if not source_filepath.is_file():
        return None

    try:
        _, output, _ = run_shell(
            f"bash -c 'set -a && source {source_filepath} && env'",
            capture_output=True,
            check=True,
        )
    except subprocess.CalledProcessError:
        return None

    env_values_by_key = {}
    for line in output.splitlines():
        key, _, value = line.partition("=")
        if key in keys:
            env_values_by_key[key] = value

    # `set -a` does not export arrays, so read any remaining keys separately.
    for key in keys:
        if key not in env_values_by_key:
            _, output, _ = run_shell(
                f"bash -c 'source {source_filepath} && echo ${{{key}[@]}}'",
                capture_output=True,
            )
            env_values_by_key[key] = [v for v in output.strip().split(" ") if v]
    return env_values_by_key


class ImageKey:
    """A dotted image key, e.g. noble_pip.ccache.install_env."""

    def __init__(self, image_key_list: List[str]):
        self.image_keys_ = image_key_list

    def __str__(self):
        return ".".join(self.image_keys_)

    @classmethod
    def from_string(cls, image_key_str: str):
        return cls(image_key_str.split("."))


class Dockerfile:
    """One resolved layer: a Dockerfile plus the image key it matched."""

    def __init__(self, dockerfile_path: Path, image_key: ImageKey):
        self.dockerfile_path_ = dockerfile_path
        self.image_key_ = image_key

    def image_key(self) -> str:
        return str(self.image_key_)

    def target_name(self) -> str:
        """Bake target name for this layer."""
        return self.image_key().replace(".", "-")

    def __str__(self):
        return str(self.dockerfile_path_)


class ImageBuildPlan:
    """The ordered layers resolved from an image key."""

    def __init__(self, dockerfiles: List[Dockerfile], image_key: ImageKey = None):
        self.dockerfiles_ = dockerfiles
        self.image_key_ = image_key

    def final_target_name(self) -> str:
        return self.dockerfiles_[-1].target_name()

    def generate_bake_dict(
        self,
        base_image: str,
        target_image_name: str,
        context_dir: Path,
        extra_build_args: Dict[str, str] = None,
    ) -> Dict:
        """Generate a dictionary representing the docker buildx bake configuration.

        Every layer builds `FROM $BASE_IMAGE`. The first layer resolves that to
        the configured base image; every later one resolves it to the named
        context holding the previous layer's result, which is also what makes
        the dependency an edge in bake's graph.
        """
        targets = {}
        previous_target_name = None

        for i, dockerfile in enumerate(self.dockerfiles_):
            target_name = dockerfile.target_name()
            target = {
                "context": str(context_dir),
                "dockerfile": str(dockerfile.dockerfile_path_),
                "network": "host",
                "args": dict(extra_build_args or {}),
            }

            if previous_target_name is None:
                target["args"]["BASE_IMAGE"] = base_image
            else:
                target["contexts"] = {
                    "previous_layer": f"target:{previous_target_name}"
                }
                target["args"]["BASE_IMAGE"] = "previous_layer"

            # Only the last layer is tagged and loaded into the image store;
            # the rest stay inside the build graph.
            if i == len(self.dockerfiles_) - 1:
                target["tags"] = [target_image_name]
                target["output"] = ["type=docker"]

            targets[target_name] = target
            previous_target_name = target_name

        return {"targets": targets}

    @staticmethod
    def as_hcl_str(bake_plan_dict: Dict) -> str:
        import io

        f = io.StringIO()

        def quoted_list(str_list: List[str]):
            return "[" + ", ".join([f'"{value}"' for value in str_list]) + "]"

        for target_name, target in bake_plan_dict["targets"].items():
            f.write(f'target "{target_name}" {{\n')

            def write_target_attr(attr_key, processor=None):
                if attr_key in target:
                    if processor:
                        value = processor(target[attr_key])
                    else:
                        value = f'"{target[attr_key]}"'
                    f.write(f"  {attr_key:10} = {value}\n")

            def write_target_map(attr_key):
                if attr_key not in target:
                    return
                f.write(f"  {attr_key:10} = {{\n")
                for key, value in target[attr_key].items():
                    f.write(f'    {key} = "{value}"\n')
                f.write("  }\n")

            write_target_attr("context")
            write_target_attr("dockerfile")
            write_target_attr("network")
            write_target_map("contexts")
            write_target_map("args")
            write_target_attr("tags", quoted_list)
            write_target_attr("output", quoted_list)
            f.write("}\n\n")
        return f.getvalue()


def resolve_dockerfiles(
    image_key: ImageKey,
    docker_search_dirs: List[Path],
    verbose=False,
) -> Optional[ImageBuildPlan]:
    """Greedily match the longest leading run of image ids to a Dockerfile.

    `a.b.c` prefers `Dockerfile.a.b.c`, then `Dockerfile.a.b`, then
    `Dockerfile.a`, so composite layers win over their individual parts.
    Layers are returned in build order.
    """
    dockerfiles = []
    image_ids = list(image_key.image_keys_)
    while image_ids:
        unmatched_id_count = len(image_ids)
        for i in reversed(range(len(image_ids))):
            matched = False
            layer_image_ids = image_ids[: i + 1]
            layer_image_suffix = ".".join(layer_image_ids)
            if verbose:
                print(f"Searching for {layer_image_suffix}")
            for docker_search_dir in docker_search_dirs:
                dockerfile = docker_search_dir / f"Dockerfile.{layer_image_suffix}"
                if dockerfile.is_file():
                    dockerfiles.append(
                        Dockerfile(dockerfile.absolute(), ImageKey(layer_image_ids))
                    )
                    image_ids = image_ids[i + 1 :]
                    if verbose:
                        print(
                            f"Matched {dockerfile}, remaining image keys: "
                            f"{'.'.join(image_ids)}"
                        )
                    matched = True
                    break
            if matched:
                break
        if unmatched_id_count == len(image_ids):
            print_error(
                f"Could not resolve Dockerfiles for image ids: {'.'.join(image_ids)}"
            )
            if dockerfiles:
                print_info("Partially resolved Dockerfiles:")
                for d in dockerfiles:
                    print_info(f"  {d}")
            return None
    return ImageBuildPlan(dockerfiles, image_key)


def parse_build_args(build_args: Optional[List[str]]) -> Dict[str, str]:
    """Parse NAME=VALUE build args, inheriting NAME from the environment."""
    parsed = {}
    for arg in build_args or []:
        name, sep, value = arg.partition("=")
        if not sep:
            if name not in os.environ:
                continue
            value = os.environ[name]
        parsed[name] = value
    return parsed


def absolute_path(path: str) -> Path:
    path = Path(path)
    return path if path.is_absolute() else (ROOT / path).resolve()


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Build a layered development image with docker buildx bake."
    )
    parser.add_argument(
        "-f", "--config", required=True, help="Environment config to build"
    )
    parser.add_argument("-i", "--image_key", help="Override the configured image key")
    parser.add_argument(
        "-n", "--image_name", help="Override the configured final image tag"
    )
    parser.add_argument("-b", "--base_image", help="Override the configured base image")
    parser.add_argument("-c", "--context_dir", help="Override the Docker build context")
    parser.add_argument(
        "-a",
        "--build_arg",
        action="append",
        default=[],
        help="Extra build argument, NAME=VALUE (repeatable)",
    )
    parser.add_argument(
        "-d",
        "--docker_arg",
        action="append",
        default=[],
        help="Extra docker buildx bake argument (repeatable). "
        "Use --docker_arg=--flag for arguments starting "
        "with a dash.",
    )
    parser.add_argument(
        "-r",
        "--rebuild",
        action="store_true",
        help="Build without Docker's layer cache",
    )
    parser.add_argument(
        "--print",
        dest="print_only",
        action="store_true",
        help="Print the generated Bake file without building",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Show the resolution steps and the generated Bake file",
    )
    args = parser.parse_args()

    config_file = Path(args.config)
    config = extract_env_vars(config_file, CONFIG_KEYS)
    if config is None:
        print_error(f"A valid environment config is required: {config_file}")
        return 1

    image_key_str = args.image_key or config.get("CONFIG_IMAGE_KEY")
    target_image_name = args.image_name or config.get("BUILT_IMAGE")
    base_image = args.base_image or config.get("DOCKER_BUILD_BASE_IMAGE")
    context_dir = absolute_path(
        args.context_dir or config.get("DOCKER_CONTEXT_DIR") or str(ROOT)
    )

    if not image_key_str:
        print_error("Image key not specified with --image_key or CONFIG_IMAGE_KEY.")
        return 1
    if not base_image:
        print_error(
            "Base image not specified with --base_image or DOCKER_BUILD_BASE_IMAGE."
        )
        return 1
    if not target_image_name:
        target_image_name = f"{image_key_str.replace('.', '-')}-image"
        print_warning(f"Image name not specified; using {target_image_name}.")

    search_dirs = [
        absolute_path(d) for d in config.get("CONFIG_DOCKER_SEARCH_DIRS") or []
    ]
    if not search_dirs:
        search_dirs = [ROOT / "dockerfiles"]

    print_info(
        f"Building layered image for key '{image_key_str}' as '{target_image_name}'"
    )
    print_info(f"Base image: {base_image}")
    print_info(f"Docker search paths: {' '.join(str(d) for d in search_dirs)}")
    print_info(f"Docker build context: {context_dir}")

    build_plan = resolve_dockerfiles(
        ImageKey.from_string(image_key_str), search_dirs, verbose=args.verbose
    )
    if build_plan is None:
        return 1

    print_info(f"Resolved {len(build_plan.dockerfiles_)} Dockerfiles:")
    for dockerfile in build_plan.dockerfiles_:
        print_info(f"  {dockerfile}")

    bake_dict = build_plan.generate_bake_dict(
        base_image=base_image,
        target_image_name=target_image_name,
        context_dir=context_dir,
        extra_build_args=parse_build_args(args.build_arg),
    )
    bake_hcl = ImageBuildPlan.as_hcl_str(bake_dict)

    if args.print_only or args.verbose:
        print(bake_hcl)
    if args.print_only:
        return 0

    with tempfile.TemporaryDirectory() as tempdir:
        bake_filepath = Path(tempdir) / "docker-bake.hcl"
        bake_filepath.write_text(bake_hcl)

        build_cmd = " ".join(
            [
                "docker buildx bake",
                build_plan.final_target_name(),
                f"--file {bake_filepath}",
                # The layers build with --network host; the fs entitlement covers
                # search dirs and contexts outside the working directory.
                "--allow=network.host",
                "--provenance=false",
                "--no-cache" if args.rebuild else "",
                *args.docker_arg,
            ]
        )
        try:
            run_shell(
                build_cmd,
                capture_output=False,
                verbose=args.verbose,
                check=True,
                env={"BUILDX_BAKE_ENTITLEMENTS_FS": "0"},
            )
        except subprocess.CalledProcessError:
            print_error(f"Failed to build: {target_image_name}")
            return 1

    print_success(f"Successfully built: {target_image_name}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

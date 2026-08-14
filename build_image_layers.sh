#!/bin/bash
# Adapted from:
# https://github.com/NVIDIA-ISAAC-ROS/isaac_ros_common/blob/release-3.2/scripts/build_image_layers.sh

set -e

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# shellcheck source=utils/print_color.sh
source "$ROOT/utils/print_color.sh"

function usage() {
    print_info "Usage: ${0##*/} --config <file> [options]"
    print_info "  -i | --image_key   <key>    Override the configured image key"
    print_info "  -n | --image_name  <name>   Override the configured final image tag"
    print_info "  -b | --base_image  <image>  Override the configured base image"
    print_info "  -c | --context_dir <dir>    Override the Docker build context"
    print_info "  -a | --build_arg   <arg>    Extra --build-arg (repeatable)"
    print_info "  -d | --docker_arg  <arg>    Extra docker build argument (repeatable)"
    print_info "  -r | --rebuild              Build without Docker's layer cache"
    print_info "  -k | --disable_buildkit     Disable BuildKit"
    print_info "  -h | --help"
}

DOCKER_BUILDKIT=1
CONFIG_FILE=""
TARGET_IMAGE_OVERRIDE=""
TARGET_NAME_OVERRIDE=""
BASE_IMAGE_OVERRIDE=""
CONTEXT_OVERRIDE=""
ADDITIONAL_BUILD_ARGS=()
ADDITIONAL_DOCKER_ARGS=()

VALID_ARGS=$(getopt -o hf:ri:n:b:c:a:d:k --long help,config:,rebuild,image_key:,image_name:,base_image:,context_dir:,build_arg:,docker_arg:,disable_buildkit -- "$@")
eval set -- "$VALID_ARGS"
while true; do
    case "$1" in
        -f | --config) CONFIG_FILE="$2"; shift 2 ;;
        -r | --rebuild) ADDITIONAL_DOCKER_ARGS+=("--no-cache"); shift ;;
        -i | --image_key) TARGET_IMAGE_OVERRIDE="$2"; shift 2 ;;
        -n | --image_name) TARGET_NAME_OVERRIDE="$2"; shift 2 ;;
        -b | --base_image) BASE_IMAGE_OVERRIDE="$2"; shift 2 ;;
        -c | --context_dir) CONTEXT_OVERRIDE="$2"; shift 2 ;;
        -a | --build_arg) ADDITIONAL_BUILD_ARGS+=("$2"); shift 2 ;;
        -d | --docker_arg) ADDITIONAL_DOCKER_ARGS+=("$2"); shift 2 ;;
        -k | --disable_buildkit) DOCKER_BUILDKIT=0; shift ;;
        -h | --help) usage; exit 0 ;;
        --) shift; break ;;
    esac
done

if [[ -z "$CONFIG_FILE" || ! -f "$CONFIG_FILE" ]]; then
    print_error "A valid environment config is required with --config."
    exit 1
fi

# shellcheck disable=SC1090
source "$CONFIG_FILE"

TARGET_IMAGE_STR="${TARGET_IMAGE_OVERRIDE:-${CONFIG_IMAGE_KEY:-}}"
TARGET_IMAGE_NAME="${TARGET_NAME_OVERRIDE:-${BUILT_IMAGE:-}}"
BASE_IMAGE_NAME="${BASE_IMAGE_OVERRIDE:-${DOCKER_BUILD_BASE_IMAGE:-}}"
DOCKER_CONTEXT_DIR="${CONTEXT_OVERRIDE:-${DOCKER_CONTEXT_DIR:-$ROOT}}"

if [[ -z "$TARGET_IMAGE_STR" ]]; then
    print_error "Image key not specified with --image_key or CONFIG_IMAGE_KEY."
    exit 1
fi

if [[ -z "$TARGET_IMAGE_NAME" ]]; then
    TARGET_IMAGE_NAME="${TARGET_IMAGE_STR//./-}-image"
    print_warning "Image name not specified; using ${TARGET_IMAGE_NAME}."
fi

if [[ -z "$BASE_IMAGE_NAME" ]]; then
    print_error "Base image not specified with --base_image or DOCKER_BUILD_BASE_IMAGE."
    exit 1
fi

if [[ "$DOCKER_CONTEXT_DIR" != /* ]]; then
    DOCKER_CONTEXT_DIR="$ROOT/$DOCKER_CONTEXT_DIR"
fi

DOCKER_SEARCH_DIRS=()
for SEARCH_DIR in "${CONFIG_DOCKER_SEARCH_DIRS[@]}"; do
    if [[ "$SEARCH_DIR" != /* ]]; then
        SEARCH_DIR="$ROOT/$SEARCH_DIR"
    fi
    DOCKER_SEARCH_DIRS+=("$SEARCH_DIR")
done

if [[ ${#DOCKER_SEARCH_DIRS[@]} -eq 0 ]]; then
    DOCKER_SEARCH_DIRS+=("$ROOT/dockerfiles")
fi

print_info "Building layered image for key '${TARGET_IMAGE_STR}' as '${TARGET_IMAGE_NAME}'"
print_info "Base image: ${BASE_IMAGE_NAME}"
print_info "Docker search paths: ${DOCKER_SEARCH_DIRS[*]}"
print_info "Docker build context: ${DOCKER_CONTEXT_DIR}"

# Resolve Dockerfiles using the greedy suffix matching from isaac_ros_common.
read -r -a IMAGE_IDS <<< "${TARGET_IMAGE_STR//./ }"
DOCKERFILES=()

until [[ ${#IMAGE_IDS[@]} -eq 0 ]]; do
    UNMATCHED_ID_COUNT=${#IMAGE_IDS[@]}

    for (( i=0; i<${#IMAGE_IDS[@]}; i++ )); do
        LAYER_IDS=("${IMAGE_IDS[@]:i}")
        LAYER_SUFFIX="${LAYER_IDS[*]}"
        LAYER_SUFFIX="${LAYER_SUFFIX// /.}"

        for SEARCH_DIR in "${DOCKER_SEARCH_DIRS[@]}"; do
            DOCKERFILE="$SEARCH_DIR/Dockerfile.$LAYER_SUFFIX"
            if [[ -f "$DOCKERFILE" ]]; then
                DOCKERFILES+=("$DOCKERFILE")
                IMAGE_IDS=("${IMAGE_IDS[@]:0:i}")
                break 2
            fi
        done
    done

    if [[ $UNMATCHED_ID_COUNT -eq ${#IMAGE_IDS[@]} ]]; then
        print_error "Could not resolve Dockerfiles for: ${IMAGE_IDS[*]}"
        exit 1
    fi
done

print_info "Resolved ${#DOCKERFILES[@]} Dockerfiles:"
for DOCKERFILE in "${DOCKERFILES[@]}"; do
    print_info "  ${DOCKERFILE}"
done

BUILD_ARGS=()
for BUILD_ARG in "${ADDITIONAL_BUILD_ARGS[@]}"; do
    BUILD_ARGS+=("--build-arg" "$BUILD_ARG")
done

# Build the layers from the base upward. Every layer uses the repository's
# configured context so Dockerfiles can COPY shared environment files.
CURRENT_BASE="$BASE_IMAGE_NAME"
for (( i=${#DOCKERFILES[@]}-1; i>=0; i-- )); do
    DOCKERFILE="${DOCKERFILES[$i]}"
    LAYER_SUFFIX="${DOCKERFILE##*/Dockerfile.}"
    IMAGE_NAME="${LAYER_SUFFIX//./-}-image"

    if [[ $i -eq 0 ]]; then
        IMAGE_NAME="$TARGET_IMAGE_NAME"
    fi

    print_warning "Building ${DOCKERFILE} as ${IMAGE_NAME} with base ${CURRENT_BASE}"
    DOCKER_BUILDKIT=$DOCKER_BUILDKIT docker build \
        -f "$DOCKERFILE" \
        --network host \
        -t "$IMAGE_NAME" \
        --build-arg "BASE_IMAGE=$CURRENT_BASE" \
        "${BUILD_ARGS[@]}" \
        "${ADDITIONAL_DOCKER_ARGS[@]}" \
        "$DOCKER_CONTEXT_DIR"

    CURRENT_BASE="$IMAGE_NAME"
done

print_success "Successfully built: ${TARGET_IMAGE_NAME}"

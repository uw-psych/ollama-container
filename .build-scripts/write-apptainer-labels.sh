#!/bin/sh
# shellcheck shell=sh

# Write the build labels to the build labels path for both the org.label-schema and org.opencontainers.image formats

[ -n "${XDEBUG:-}" ] && set -x

write_to_build_labels() {
	while [ $# -gt 1 ]; do
		eval "[ -n \"\${$#}\" ] && printf '%s %s\n' \"$1\" \"\${$#}\"" >>"${BUILD_LABELS_PATH:-/dev/stdout}"
		shift
	done
	return 0
}

write_apptainer_labels() {
	#[ -n "${APPTAINER_ROOTFS:-}" ] || return 1                                                       # Exit if not in an apptainer build
	#BUILD_LABELS_PATH="${BUILD_LABELS_PATH:-${APPTAINER_ROOTFS:+${APPTAINER_ROOTFS}/.build.labels}}" # Set the default build labels path
	if [ -n "${APPTAINER_ROOTFS:-}" ]; then
		BUILD_LABELS_PATH="${BUILD_LABELS_PATH:-${APPTAINER_ROOTFS}/.build.labels}"
	else
		BUILD_LABELS_PATH="${BUILD_LABELS_PATH:-/dev/stdout}"
	fi

	# Try to fill in the build labels via git if not already set and git is available
	if git tag >/dev/null 2>&1; then
		IMAGE_VCS_URL="${IMAGE_VCS_URL:-$(git remote get-url origin || true)}"                       # Set the default VCS URL to the origin remote
		[ -z "${IMAGE_URL:-}" ] && [ -n "${IMAGE_VCS_URL:-}" ] && IMAGE_URL="${IMAGE_VCS_URL%%.git}" # Set the default URL to the VCS URL without the .git extension
		IMAGE_VCS_REF="${IMAGE_VCS_REF:-$(git rev-parse --short HEAD || true)}"                      # Set the default VCS ref to the short hash of HEAD

		IMAGE_GIT_TAG="${GITHUB_REF_NAME:-"$(git tag --points-at HEAD --list '*@*' --sort=-"creatordate:iso" || true)"}" # Set the default git tag to the most recent tag matching the format *@* sorted by date

		if [ -n "${IMAGE_GIT_TAG:-}" ]; then
			if [ -z "${IMAGE_TAG:-}" ]; then
				IMAGE_TAG="$(echo "${IMAGE_GIT_TAG:-}" | sed -nE 's/.*[@]//; s/^v//; 1p')"
				[ -z "${IMAGE_TAG:-}" ] && IMAGE_TAG='latest'
			fi

			if [ -n "${IMAGE_TITLE:-}" ]; then
				IMAGE_TITLE="$(echo "${IMAGE_GIT_TAG}" | sed -nE 's/[@].*$//; 1p')"
			fi
		fi
	fi
	IMAGE_TAG="${IMAGE_TAG:-latest}"                     # Set the default tag to latest if no tag was found
	IMAGE_TITLE="${IMAGE_TITLE:-"$(basename "${PWD}")"}" # Set the default title to the current directory name
	IMAGE_VERSION="${IMAGE_VERSION:-${IMAGE_TAG:-}}"     # Set the default version to the tag if set, otherwise the tag if set, otherwise empty

	# If no image vendor is set, try to set it to the GitHub organization:
	if [ -z "${IMAGE_VENDOR:=${IMAGE_VENDOR:-}}" ]; then
		# If the GitHub organization is not set, try to set it to the GitHub organization of the upstream remote:
		[ -z "${GH_ORG:-}" ] && GH_ORG="$(git remote get-url upstream | sed -n 's/.*github.com[:/]\([^/]*\)\/.*/\1/p' || true)"
		# If the GitHub organization is not set, try to set it to the GitHub organization of the origin remote:
		[ -z "${GH_ORG:-}" ] && GH_ORG="$(git remote get-url origin | sed -n 's/.*github.com[:/]\([^/]*\)\/.*/\1/p' || true)"

		# Assign the image vendor to the GitHub organization or username if it is set, otherwise leave it empty:
		IMAGE_VENDOR="${GH_ORG:-}"

		# If the GitHub organization is set to uw-psych, set the image vendor to the University of Washington Department of Psychology:
		[ "${IMAGE_VENDOR:-}" = 'uw-psych' ] && IMAGE_VENDOR='University of Washington Department of Psychology'
	fi

	# Try to set image author from GITHUB_REPOSITORY_OWNER if not set:
	IMAGE_AUTHOR="${IMAGE_AUTHOR:-${GITHUB_REPOSITORY_OWNER:-}}"

	# If no image author is set, try to set it to the git author via git config:
	if [ -z "${IMAGE_AUTHOR:-}" ] && command -v git >/dev/null 2>&1; then
		[ -n "${IMAGE_AUTHOR_EMAIL:-}" ] || IMAGE_AUTHOR_EMAIL="$(git config --get user.email || git config --get github.email || true)"
		[ -n "${IMAGE_AUTHOR_NAME:-}" ] || IMAGE_AUTHOR_NAME="$(git config --get user.name || git config --get github.user || true)"
		IMAGE_AUTHOR="${IMAGE_AUTHOR_NAME:+${IMAGE_AUTHOR_NAME} }<${IMAGE_AUTHOR_EMAIL:-}>"
	fi

	# Write the build labels to the build labels path for both the org.label-schema and org.opencontainers.image formats:
	write_to_build_labels "org.label-schema.title" "org.opencontainers.image.title" "${IMAGE_TITLE:-}"
	write_to_build_labels "org.label-schema.url" "org.opencontainers.image.url" "${IMAGE_URL:-}"
	write_to_build_labels "org.label-schema.vcs-ref" "org.opencontainers.image.revision" "${IMAGE_VCS_REF:-}"
	write_to_build_labels "org.label-schema.vcs-url" "org.opencontainers.image.source" "${IMAGE_VCS_URL:-}"
	write_to_build_labels "org.label-schema.vendor" "org.opencontainers.image.vendor" "${IMAGE_VENDOR:-}"
	write_to_build_labels "MAINTAINER" "maintainer" "org.opencontainers.image.authors" "${IMAGE_AUTHOR:-}"
	write_to_build_labels "org.label-schema.description" "org.opencontainers.image.description" "${IMAGE_DESCRIPTION:-}"
	write_to_build_labels "org.label-schema.usage" "org.opencontainers.image.documentation" "${IMAGE_DOCUMENTATION:-}"
	write_to_build_labels "org.label-schema.version" "org.opencontainers.image.version" "${IMAGE_VERSION:-}"
}

! (return 0 2>/dev/null) || write_apptainer_labels "$@"

#!/usr/bin/env bash
set -euo pipefail
cd $(dirname $0)

REPO_DIR="arch"
REPO_NAME="personal"

AUR_HELPER="pikaur"
PKGEXT=".pkg.tar.zst"
MAKEPKG="makepkg"
REPO_ADD="repo-add"
REPO_REMOVE="repo-remove"
GIT="git"

function show_help {
  echo "Usage: $(basename $0) COMMAND PACKAGE"
  echo -e "Manage the AUR PACKAGE inside the repo\n"
  echo -e "Commands:"
  echo -e "\tdownload\t download the PKGBUILD for the PACKAGE"
  echo -e "\tbuild\t\t tbuild the downloaded PACKAGE using makepkg"
  echo -e "\tupdate\t\t update the repo using the built PACKAGE"
  echo -e "\tclean\t\t clean after the PACKAGE"
  echo -e "\tall\t\t perform all the steps automatically\n"
  echo -e "Options:"
  echo -e "\t-h, --help\t display this text"
}

POSITIONAL=()
while [[ $# -gt 0 ]]; do
  ARG="$1"
  case "${ARG}" in
    -h|--help )
      show_help
      exit
      ;;
    -* )
      echo "$(basename $0): unknown option: ${ARG}" >&2
      exit 1
      ;;
    * )
      POSITIONAL+=("${ARG}")
      shift
      ;;
  esac
done

set -- "${POSITIONAL[@]}"

if [ "$#" -ne 2 ]; then
  show_help
  exit 1
fi

COMMAND="$1"
PACKAGE="$2"

function download {
  if ! [ -x "$(command -v ${AUR_HELPER})" ]; then
    echo "$(basename $0): ${AUR_HELPER} is not installed" >&2
    exit 1
  fi

  "${AUR_HELPER}" -G "${PACKAGE}"
}

function build {
  export PKGEXT
  "${MAKEPKG}" -Ccsr
}

function git_add {
  "${GIT}" add -f *"${PKGEXT}"
  "${GIT}" add -f "${REPO_NAME}".{db,files}{,.tar.gz}
}

function update {
  "${REPO_REMOVE}" -R "${REPO_NAME}.db.tar.gz" "${PACKAGE}" || true
  cp "../${PACKAGE}/"*"${PKGEXT}" .
  "${REPO_ADD}" -n "${REPO_NAME}.db.tar.gz" *"${PKGEXT}"
  git_add
}

function clean {
  mv "${PACKAGE}" "old.${PACKAGE}.$(date +%s)"
}

case "${COMMAND}" in
  download )
    download
    ;;
  build )
    (cd "${PACKAGE}" && build)
    ;;
  update )
    (cd "${REPO_DIR}" && update)
    ;;
  clean )
    clean
    ;;
  all )
    download
    (cd "${PACKAGE}" && build)
    (cd "${REPO_DIR}" && update)
    clean
    ;;
  * )
    echo "$(basename $0): unknown command: ${COMMAND}" >&2
    exit 1
    ;;
esac


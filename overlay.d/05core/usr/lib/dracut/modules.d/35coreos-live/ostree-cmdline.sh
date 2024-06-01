#!/bin/bash
# With live PXE there's no ostree= argument on the kernel command line, so
# we need to find the tree path and pass it to ostree-prepare-root.  But
# ostree-prepare-root only knows how to read the path from
# /proc/cmdline, so we need to synthesize the proper karg and bind-mount
# it over /proc/cmdline.
# https://github.com/ostreedev/ostree/issues/1920

set -euo pipefail

case "${1:-unset}" in
    start)
        treepath="$(echo /sysroot/ostree/boot.1/*/*/0)"
        cmdline="$(cat /proc/cmdline)"
        if [[ "$cmdline" =~ ^.*ostree=.* ]]; then
            cmdline=$(echo $cmdline | sed -e "s,\(.*\)ostree=[^ ]*\(.*\),\1ostree=${treepath#/sysroot}\2,")
        else
            cmdline="${cmdline} ostree=${treepath#/sysroot}"
        fi
        echo "${cmdline}" > /tmp/cmdline
        mount --bind /tmp/cmdline /proc/cmdline
        ;;
    stop)
        umount -l /proc/cmdline
        rm /tmp/cmdline
        ;;
    *)
        echo "Usage: $0 {start|stop}" >&2
        exit 1
        ;;
esac

# magnum.sh - Devstack extras script to install magnum

# Save trace setting
XTRACE=$(set +o | grep xtrace)
set -o xtrace

echo_summary "magnum's plugin.sh was called..."
source $DEST/magnum/devstack/lib/magnum
(set -o posix; set)

if is_service_enabled magnum-api magnum-cond; then
    if [[ "$1" == "stack" && "$2" == "install" ]]; then
        echo_summary "Installing magnum"
        install_magnum

        # add image to glance
        if [[ "$ENABLED_SERVICES" =~ 'magnum-api' ]]; then
            # TODO Add a "latest" link to fedora release process
            # TODO(hongbin): Uncomment below when the mirror become stable
            #ATOMIC_IMAGE_NAME=$( \
            #    wget -qO- \
            #         "https://download.fedoraproject.org/pub/alt/atomic/stable/Cloud-Images/x86_64/Images/" 2>&1 | \
            #         grep qcow2 | \
            #         sed 's/^.*>\(.*\)<.*$/\1/' | \
            #         head -n 1 )
            #echo "Atomic Image: $ATOMIC_IMAGE_NAME"
            #MAGNUM_GUEST_IMAGE_URL=${MAGNUM_GUEST_IMAGE_URL:-"https://download.fedoraproject.org/pub/alt/atomic/stable/Cloud-Images/x86_64/Images/$ATOMIC_IMAGE_NAME"}
            MAGNUM_GUEST_IMAGE_URL=${MAGNUM_GUEST_IMAGE_URL:-"https://fedorapeople.org/groups/magnum/fedora-23-atomic-20160405.qcow2"}
            IMAGE_URLS+=",${MAGNUM_GUEST_IMAGE_URL}"
        fi

        LIBS_FROM_GIT="${LIBS_FROM_GIT},python-magnumclient"

        install_magnumclient
        cleanup_magnum
    elif [[ "$1" == "stack" && "$2" == "post-config" ]]; then
        echo_summary "Configuring magnum"
        configure_magnum

        # Hack a large timeout for now
        iniset /etc/keystone/keystone.conf token expiration 7200

        if is_service_enabled key; then
            create_magnum_accounts
        fi

    elif [[ "$1" == "stack" && "$2" == "extra" ]]; then
        # Initialize magnum
        init_magnum
        magnum_register_image

        # Start the magnum API and magnum taskmgr components
        echo_summary "Starting magnum"
        start_magnum

        configure_iptables
    fi

    if [[ "$1" == "unstack" ]]; then
        stop_magnum
    fi

    if [[ "$1" == "clean" ]]; then
        cleanup_magnum
    fi
fi

# Restore xtrace
$XTRACE

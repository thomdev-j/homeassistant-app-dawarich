# Load the addon's runtime environment into interactive shells.
#
# Addon options are only known at startup, so init-dawarich.sh resolves them
# with bashio and writes them to s6's container_environment. s6 injects those
# into services started with with-contenv — but not into a shell opened with
# `docker exec`, which therefore starts bare. Rails then aborts with
# "OTP_ENCRYPTION_PRIMARY_KEY required in production", because it derives its
# encryption keys from SECRET_KEY_BASE and that variable is missing.
#
# Interactive shells only: `su - postgres -c '...'` in the service scripts runs
# a NON-interactive login shell, which also reads this file. Exporting the
# container environment there would hand the postgres user root's HOME and the
# app's variables, so we stay out of its way.
case "$-" in
    *i*)
        if [ -d /var/run/s6/container_environment ]; then
            for _dw_f in /var/run/s6/container_environment/*; do
                [ -f "$_dw_f" ] || continue
                _dw_n=$(basename "$_dw_f")
                case "$_dw_n" in
                    # Never clobber the shell's own identity.
                    PATH|HOME|PWD|OLDPWD|SHELL|SHLVL|TERM|USER|LOGNAME|HOSTNAME|_) ;;
                    # Anything else that is a usable variable name.
                    [A-Za-z_]*) export "$_dw_n=$(cat "$_dw_f")" ;;
                esac
            done
            unset _dw_f _dw_n
        fi
        ;;
esac

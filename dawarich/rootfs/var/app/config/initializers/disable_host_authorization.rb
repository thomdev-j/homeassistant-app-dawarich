# Disable Rails HostAuthorization for the Home Assistant add-on.
# HA handles authentication via ingress; blocking hosts causes 403 errors
# for ingress proxied requests and direct LAN access.
Rails.application.config.hosts.clear

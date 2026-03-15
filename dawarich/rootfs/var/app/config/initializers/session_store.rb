# Persist session cookies for 1 year.
#
# By default Rails sets a "Session" cookie (no Expires/Max-Age), which the
# browser discards on close or during routine cleanup.  For the HA add-on
# this means users get logged out unexpectedly.
#
# expire_after adds a Max-Age attribute so the cookie survives browser
# restarts.  Each device keeps its own independent session — logging in on
# a second device does NOT invalidate the first.
Rails.application.config.session_store :cookie_store,
  key: '_dawarich_session',
  expire_after: 1.year

# Extend Devise timeouts if Devise is present (safety net in case the
# upstream app enables the :timeoutable or :rememberable modules).
Rails.application.config.after_initialize do
  if defined?(Devise)
    Devise.timeout_in  = 1.year if Devise.respond_to?(:timeout_in=)
    Devise.remember_for = 1.year if Devise.respond_to?(:remember_for=)
  end
end

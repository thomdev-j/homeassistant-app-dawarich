# Override Devise session persistence for the HA add-on.
#
# Named z_* so it loads AFTER the upstream devise.rb initializer and wins.
#
# - remember_for:             how long the "Remember me" cookie lives
# - extend_remember_period:   reset the timer on every visit (sliding window)
# - timeout_in:               safety net if upstream ever enables :timeoutable
Devise.setup do |config|
  config.remember_for            = 1.year
  config.extend_remember_period  = true
  config.timeout_in              = 1.year
end

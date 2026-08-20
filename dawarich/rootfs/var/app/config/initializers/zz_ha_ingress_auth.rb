# Sign people in from the identity Home Assistant already proved.
#
# Named zz_* so it loads after upstream's devise and omniauth initializers.
#
# Home Assistant puts the signed-in user in X-Remote-User-Id on ingress requests
# and strips any copy the browser sent, so through ingress that header is as
# trustworthy as HA's own login. nginx passes it on, together with the shared
# secret below, only for requests coming from Supervisor's address. Anything
# else, including port 3000 and other containers on the hassio network, arrives
# without an identity and gets the normal login form.
#
# The identity is only ever used to *find* an account, never to change one:
# an existing Dawarich user is adopted by stamping provider/uid on it, which
# leaves its points, tracks and settings exactly as they were.
module HomeAssistantIngressAuth
  PROVIDER = 'home_assistant'
  SECRET_HEADER = 'HTTP_X_DAWARICH_INGRESS_SECRET'
  USER_ID_HEADER = 'HTTP_X_REMOTE_USER_ID'
  USER_NAME_HEADER = 'HTTP_X_REMOTE_USER_NAME'
  DISPLAY_NAME_HEADER = 'HTTP_X_REMOTE_USER_DISPLAY_NAME'
  USER_MAP_PATH = '/data/dawarich/ha_user_map.json'
  # Signing out has to actually sign you out. Without this, the next request
  # would hand the session straight back and the button would look broken.
  OPT_OUT_COOKIE = :dawarich_ingress_auto_login_off
  OPT_OUT_FOR = 30.minutes
  REFUSAL_LOG_EVERY = 5.minutes

  class << self
    def enabled?
      ENV['INGRESS_AUTO_LOGIN'].to_s == 'on' && secret.present?
    end

    def create_unmatched?
      ENV['INGRESS_AUTH_CREATE_UNMATCHED'].to_s == 'true'
    end

    def secret
      @secret ||= ENV['INGRESS_AUTH_SECRET'].to_s
    end

    def identity(request)
      return nil unless enabled?
      return nil unless trusted?(request)

      id = request.get_header(USER_ID_HEADER).to_s.strip
      return nil if id.blank?

      {
        id: id,
        name: request.get_header(USER_NAME_HEADER).to_s.strip,
        display_name: request.get_header(DISPLAY_NAME_HEADER).to_s.strip
      }
    end

    # Look up, adopt, or (only where it is safe) create. Returns nil to mean
    # "let Devise show the login form", never an exception to the caller.
    def user_for(identity)
      existing = User.find_by(provider: PROVIDER, uid: identity[:id])
      return existing if existing

      mapped = mapped_user(identity)
      return adopt(mapped, identity) if mapped
      return create(identity) if create_unmatched?

      log_refusal(identity)
      nil
    end

    private

    def trusted?(request)
      given = request.get_header(SECRET_HEADER).to_s
      given.bytesize == secret.bytesize &&
        ActiveSupport::SecurityUtils.fixed_length_secure_compare(given, secret)
    rescue StandardError
      false
    end

    def mapped_user(identity)
      email = user_map[identity[:id]]
      return nil if email.blank?

      User.find_by(email: email)
    end

    # Built at boot by svc-dawarich from the person entities behind
    # ha_tracked_entities. Read fresh so a restart of the app picks up config
    # changes without a Rails restart.
    def user_map
      raw = File.read(USER_MAP_PATH)
      parsed = JSON.parse(raw)
      parsed.is_a?(Hash) ? parsed : {}
    rescue StandardError
      {}
    end

    def adopt(user, identity)
      user.update!(provider: PROVIDER, uid: identity[:id])
      Rails.logger.info(
        "[ha-ingress-auth] linked Home Assistant user #{describe(identity)} to existing account #{user.email}"
      )
      user
    end

    def create(identity)
      email = "#{slug(identity)}@homeassistant.local"
      user, created = Auth::FindOrCreateOauthUser.new(
        provider: PROVIDER,
        provider_label: 'Home Assistant',
        claims: { sub: identity[:id], email: email },
        email_verified: true,
        name_attrs: name_attrs(identity),
        on_email_collision: :raise_only
      ).call

      Rails.logger.info("[ha-ingress-auth] created account #{email} for Home Assistant user #{describe(identity)}") if created
      user
    rescue StandardError => e
      Rails.logger.warn("[ha-ingress-auth] could not create an account for #{describe(identity)}: #{e.class}: #{e.message}")
      nil
    end

    def name_attrs(identity)
      full = identity[:display_name].presence || identity[:name].presence
      return {} if full.blank?

      first, last = full.split(' ', 2)
      { first_name: first, last_name: last }.compact
    end

    def slug(identity)
      base = identity[:name].presence || identity[:display_name].presence || identity[:id]
      slug = ActiveSupport::Inflector.transliterate(base.to_s).downcase.gsub(/[^a-z0-9]+/, '-').gsub(/\A-+|-+\z/, '')
      slug.presence || "ha-#{identity[:id]}"
    end

    def describe(identity)
      identity[:display_name].presence || identity[:name].presence || identity[:id]
    end

    # One line per user per window: this fires on every request of every page
    # load, and the point is to be findable in the log, not to fill it.
    def log_refusal(identity)
      @refusals ||= {}
      last = @refusals[identity[:id]]
      return if last && last > REFUSAL_LOG_EVERY.ago

      @refusals[identity[:id]] = Time.current
      Rails.logger.info(
        "[ha-ingress-auth] no Dawarich account is mapped to Home Assistant user #{describe(identity)}, " \
        'showing the login form. Map their person entity with ha_tracked_entities to sign them in automatically.'
      )
    end
  end
end

ActiveSupport.on_load(:action_controller_base) do
  prepend_before_action :home_assistant_ingress_sign_in

  private

  def home_assistant_ingress_sign_in
    return unless HomeAssistantIngressAuth.enabled?

    if request.path.match?(%r{/users/sign_out\z})
      # Devise resets the session here, so the opt-out has to live in a cookie.
      cookies[HomeAssistantIngressAuth::OPT_OUT_COOKIE] = {
        value: '1',
        expires: HomeAssistantIngressAuth::OPT_OUT_FOR.from_now,
        httponly: true,
        path: '/'
      }
      return
    end
    return if cookies[HomeAssistantIngressAuth::OPT_OUT_COOKIE].present?

    identity = HomeAssistantIngressAuth.identity(request)
    return if identity.nil?

    signed_in = warden.user(:user)
    return if signed_in && signed_in.provider == HomeAssistantIngressAuth::PROVIDER && signed_in.uid == identity[:id]

    user = HomeAssistantIngressAuth.user_for(identity)
    return if user.nil?

    warden.set_user(user, scope: :user)
    redirect_to(root_path) if request.path.match?(%r{/users/sign_in\z})
  rescue StandardError => e
    # Never lock anyone out because this failed: fall through to the login form.
    Rails.logger.warn("[ha-ingress-auth] #{e.class}: #{e.message}")
  end
end

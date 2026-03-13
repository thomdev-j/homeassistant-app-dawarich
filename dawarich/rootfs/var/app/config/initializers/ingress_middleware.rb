# Rack middleware + view helper override for Home Assistant ingress support.
#
# Problem: HA ingress proxies under a dynamic subpath (/api/hassio_ingress/<token>/).
# Rails asset helpers use config.relative_url_root (global), but we need per-request
# prefixing so that ingress requests get prefixed URLs while direct access (port 3000,
# Cloudflare tunnel) stays clean.
#
# Solution:
# 1. Middleware sets SCRIPT_NAME + custom env key for ingress requests only
# 2. View helper override prepends ingress path to all asset URLs per-request
# 3. SCRIPT_NAME handles url_for, redirect_to, route helpers automatically

class IngressMiddleware
  def initialize(app)
    @app = app
    @ingress_path = ENV.fetch("INGRESS_PATH", "")
  end

  def call(env)
    if env["HTTP_X_INGRESS"] == "true" && !@ingress_path.empty?
      env["SCRIPT_NAME"] = @ingress_path
      env["dawarich.ingress_path"] = @ingress_path
    end
    @app.call(env)
  end
end

Rails.application.config.middleware.insert_before(0, IngressMiddleware)

# Override asset_path to respect per-request ingress path.
# This catches stylesheet_link_tag, javascript_include_tag, javascript_importmap_tags,
# image_tag, font_path, and any other helper that resolves through asset_path.
module IngressAwareAssetHelper
  def asset_path(source, options = {})
    result = super
    ingress_path = controller.request.env["dawarich.ingress_path"] if controller
    if ingress_path && result.is_a?(String) && result.start_with?("/") && !result.start_with?(ingress_path)
      "#{ingress_path}#{result}"
    else
      result
    end
  end
end

ActiveSupport.on_load(:action_view) do
  prepend IngressAwareAssetHelper
end

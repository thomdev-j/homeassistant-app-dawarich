# Rack middleware that sets SCRIPT_NAME for Home Assistant ingress requests.
# When HA proxies through ingress, nginx adds X-Ingress: true header.
# SCRIPT_NAME tells Rails to prefix all generated URLs with the ingress path,
# so assets, links, and redirects all work correctly in the HA sidebar.
# Direct access (port 3000) is unaffected — no header, no prefix.
class IngressMiddleware
  def initialize(app)
    @app = app
    @ingress_path = ENV.fetch("INGRESS_PATH", "")
  end

  def call(env)
    if env["HTTP_X_INGRESS"] == "true" && !@ingress_path.empty?
      env["SCRIPT_NAME"] = @ingress_path
    end
    @app.call(env)
  end
end

Rails.application.config.middleware.insert_before(0, IngressMiddleware)

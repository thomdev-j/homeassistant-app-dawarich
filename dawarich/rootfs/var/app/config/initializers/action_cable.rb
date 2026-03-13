Rails.application.config.after_initialize do
  ActionCable.server.config.disable_request_forgery_protection = true
end

# Give Sidekiq longer before it gives up on Redis.
#
# Named z_* so it loads AFTER the upstream sidekiq.rb initializer. `config.redis=`
# merges into what is already set, so the url and db upstream picks stay as they
# are and only the timeout changes.
#
# Redis writes its append-only file once a second. On the USB SSDs and SD cards
# Home Assistant hosts run on, that fsync can take seconds whenever Postgres, the
# recorder or a backup are writing at the same time — Redis says so itself with
# "Asynchronous AOF fsync is taking too long (disk is busy?)". It blocks while
# that happens, and Sidekiq's 3 second default was short enough that its
# heartbeat gave up and reconnected a few hundred times a day. No job was ever
# lost, the heartbeat simply retried, but the errors buried everything else in
# the log.
Sidekiq.configure_server do |config|
  config.redis = { timeout: 10 }
end

Sidekiq.configure_client do |config|
  config.redis = { timeout: 10 }
end

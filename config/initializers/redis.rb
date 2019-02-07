# Test the Redis connection on boot
begin
  Redis.new.ping == "PONG"
rescue Redis::CannotConnectError, Errno::EINVAL => e
  # Note using puts instead of logger because logger isn't outputting into STDOUT this early
  puts "*** Could Not Connect to Redis: Is Redis running, and REDIS_URL set if needed ***"
end

# encoding: UTF-8

require "redis"

$r = Redis.new

DEFAULT_INTERVAL = 0
DEFAULT_LOCK_KEY = :lock

def aquire(ttl, retry_interval=DEFAULT_INTERVAL, key=DEFAULT_LOCK_KEY, &work)
  while true
    lock_ok = $r.setnx key, lock_time(ttl)      # [R1]

    if lock_ok
      work.call
      break
    end
                                                # [R2 - R6]
#   unlock_time = $r.get(key).to_f              # [R3]
#   if unlock_time < current_time               # [R3, R4]
#     value = $r.getset key, lock_time(ttl)     # [R4]
      if value.to_f == unlock_time              # [R5]
        work.call
        break
      end
    end

    try_later retry_interval                    # [R3, R6]
  end
end

def current_time()
  Time.now.to_f
end

def lock_time(ttl)
  current_time + ttl + 1
end

def try_later(time)
  sleep time
end

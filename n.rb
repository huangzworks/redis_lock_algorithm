# encoding: UTF-8

require "redis"

$r = Redis.new

DEFAULT_INTERVAL = 0
DEFAULT_LOCK_KEY = :lock

def aquire(ttl, retry_interval=DEFAULT_INTERVAL, key=DEFAULT_LOCK_KEY, &work)
  while true
    lock_ok = $r.setnx key, lock_time(ttl)
    if lock_ok
      work.call
      break
    end

    $r.watch key                                 # +1

    unlock_time = $r.get(key).to_f
    if unlock_time < current_time
      transaction_result = $r.multi do |t|       # +2
        t.getset key, lock_time(ttl)             # +3
      end                                        # +4
      if transaction_result != nil               # +5
        work.call
        break
      end
    end

    try_later retry_interval
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

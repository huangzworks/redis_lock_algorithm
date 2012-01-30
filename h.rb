# encoding: UTF-8

require "redis"

$r = Redis.new

DEFAULT_INTERVAL = 0
DEFAULT_LOCK_KEY = :lock
DEFAULT_LOCK_VALUE = "locking!"

PERSIST = -1
LOCK_KEY_ERR_MSG = "lock key error"

def aquire(ttl, retry_interval=DEFAULT_INTERVAL, key=DEFAULT_LOCK_KEY, value=DEFAULT_LOCK_VALUE, &work)
  while true
    $r.watch key

    locked = $r.exists key                              # 1
    if locked                                           # 1
      $r.unwatch                                        # 1
    else
      transaction_result = $r.multi do |t|              # 2
        t.setex key, ttl, value                         # 2
      end                                               # 2
      if transaction_result != nil
        work.call
        break
      end
    end

    try_later retry_interval
  end
end

def try_later(time)
  sleep time
end

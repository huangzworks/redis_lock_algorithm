# encoding: UTF-8

require "redis"

$r = Redis.new

DEFAULT_INTERVAL = 0
DEFAULT_LOCK_KEY = :lock
DEFAULT_LOCK_ID = "locking!"

def aquire(ttl, retry_interval=DEFAULT_INTERVAL, key=DEFAULT_LOCK_KEY, identity=DEFAULT_LOCK_ID, &work)
  while true
    $r.watch key

    locked = $r.exists key
    if locked
      $r.unwatch
    else
      transaction_result = $r.multi do |t|
        t.setex key, ttl, identity
      end
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

DELETE_OK = 1

def release(key=DEFAULT_LOCK_KEY, identity=DEFAULT_LOCK_ID)
  $r.watch key

  if identity == $r.get(key)
    transaction_result = $r.multi do |t|
      t.del key
    end
    transaction_result != nil & (transaction_result[0] == DELETE_OK)
  else
    $r.unwatch
    false
  end
end

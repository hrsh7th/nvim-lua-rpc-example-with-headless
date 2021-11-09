local session = require('rpc.session')

local pipe = function()
  return {
    _running = false,
    _buffer = '',
    _callback = function() end,
    write = function(self, chunk)
      self._buffer = self._buffer .. chunk

      if self._running then
        return
      end
      self._running = true

      local loop
      loop = vim.schedule_wrap(function()
        if self._buffer == '' then
          self._running = false
          return
        end

        local off = math.min(#self._buffer, 2)
        self._callback(nil, string.sub(self._buffer, 1, off))
        self._buffer = string.sub(self._buffer, off + 1)
        loop()
      end)
      loop()
    end,
    read_start = function(self, callback)
      self._callback = callback
    end,
  }
end

describe('rpc.session', function()
  it('request & response', function()
    local client = { i = pipe(), o = pipe() }
    local server = { i = pipe(), o = pipe() }
    local c = session.new(client.i, server.o)
    local s = session.new(server.o, client.i)
    c:connect()
    s:connect()
    s.on_request['test'] = function(params, callback)
      callback(params)
    end
    assert.are.same(c:request('test', { test = 1 })(), { test = 1 })
  end)
  it('notification', function()
    local client = { i = pipe(), o = pipe() }
    local server = { i = pipe(), o = pipe() }
    local c = session.new(client.i, server.o)
    local s = session.new(server.o, client.i)
    c:connect()
    s:connect()
    local done = false
    s.on_notification['test'] = function(params)
      assert.are.same(params, { test = 1 })
      done = true
    end
    c:notify('test', { test = 1 })
    vim.wait(5000, function()
      return done
    end)
  end)
end)

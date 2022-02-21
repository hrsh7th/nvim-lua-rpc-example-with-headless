local mpack = require('mpack')
local logger = require('rpc.logger')
local promise = require('rpc.promise')

local session = {}

session.REQUEST = '0' -- I can't understand but it must be a string. If we use number, it will be converted as `10`.
session.RESPONSE = 1
session.NOTIFICATION = 2

session.new = function(reader, writer)
  local self = setmetatable({}, { __index = session })
  self.reader = reader
  self.writer = writer
  self.buffer = ''
  self.request_id = 0
  self.on_request = {}
  self.on_notification = {}
  self.pending_requests = {}
  return self
end

session.connect = function(self)
  self.reader:read_start(function(err, data)
    if err then
      error(err)
    end
    data = data or ''
    if self.buffer == '' then
      self.buffer = data
      self:consume()
    else
      self.buffer = self.buffer .. data
    end
  end)
end

session.request = function(self, method, params)
  self.request_id = self.request_id + 1
  self:_write({ session.REQUEST, self.request_id, method, params })

  return promise.new(function(resolve, reject)
    self.pending_requests[self.request_id] = function(err, res)
      if err then
        reject(err)
      else
        resolve(res)
      end
    end
  end)
end

session.notify = function(self, method, params)
  self:_write({ session.NOTIFICATION, method, params })
end

session.consume = function(self)
  while self.buffer ~= '' do
    local res, off = mpack.Unpacker()(self.buffer)
    if not res then
      return
    end
    self.buffer = string.sub(self.buffer, off)

    logger.write('res', { res, off })

    if res[1] == session.REQUEST then
      if self.on_request[res[3]] then
        local ok, err = pcall(function()
          self.on_request[res[3]](res[4], function(result)
            self:_write({ session.RESPONSE, res[2], nil, result })
          end)
        end)
        if not ok then
          self:_write({ session.RESPONSE, res[2], err, nil })
        end
      end
    elseif res[1] == session.RESPONSE then
      if self.pending_requests[res[2]] then
        self.pending_requests[res[2]](res[3], res[4])
        self.pending_requests[res[2]] = nil
      end
    elseif res[1] == session.NOTIFICATION then
      if self.on_notification[res[2]] then
        pcall(function()
          self.on_notification[res[2]](res[3])
        end)
      end
    end
  end
end

session._write = function(self, msg)
  self.writer:write(mpack.Packer()(msg))
end

return session


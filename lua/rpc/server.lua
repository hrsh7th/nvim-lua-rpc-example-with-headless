local pipe = require('rpc.pipe')
local session = require('rpc.session')

local server = {}

server.new = function()
  local self = setmetatable({}, { __index = server })
  self.session = session.new(pipe(), {
    write = function(_, data)
      if self.channel and data then
        vim.fn.chansend(self.channel, data)
      end
    end
  })
  return self
end

server.connect = function(self)
  self.channel = vim.fn.stdioopen({
    on_stdin = function(_, data, _)
      self.session.reader:write(table.concat(data, ''))
    end,
  })
  self.session:connect()
end

server.request = function(self, method, params)
  return self.session:request(method, params)
end

server.notify = function(self, method, params)
  return self.session:notify(method, params)
end

return server


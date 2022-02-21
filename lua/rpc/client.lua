local pipe = require('rpc.pipe')
local session = require('rpc.session')

local client = {}

client.new = function()
  local self = setmetatable({}, { __index = client })
  self.channel = nil
  self.session = session.new(pipe(), {
    write = function(_, data)
      if self.channel and data then
        vim.fn.chansend(self.channel, data)
      end
    end
  })
  return self
end

client.connect = function(self)
  if self.channel then
    return
  end

  self.channel = vim.fn.jobstart({ 'nvim', '--headless', '-u', 'NONE', '-c', ('luafile %s'):format(vim.api.nvim_get_runtime_file('lua/rpc/_bootstrap.lua', false)[1]) }, {
    env = {
      runtimepath = vim.o.runtimepath,
    },
    on_stdout = function(_, data, _)
      self.session.reader:write(table.concat(data, ''))
    end,
  })
  self.session:connect()
end

client.request = function(self, method, params)
  return self.session:request(method, params)
end

client.notify = function(self, method, params)
  return self.session:notify(method, params)
end

return client


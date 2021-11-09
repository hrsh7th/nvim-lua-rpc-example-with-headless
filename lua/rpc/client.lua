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

  -- TODO: the -c will load all of plugins. We don't want to load the any plugins automatically (plugin/*.{vim,lua}).
  self.channel = vim.fn.jobstart('nvim --headless -c "lua require(\'rpc.server\').new():connect()"', {
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


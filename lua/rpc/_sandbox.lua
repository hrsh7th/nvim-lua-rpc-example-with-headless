local client = require('rpc.client')

local c = client.new()
c:connect()
function _G.run()
  c:notify('notify', {
    text = 'echo'
  })
  c:request('request', {
    text = 'echo'
  })(function(err, res1)
    c:request('request', {
      text = 'echo'
    })(function(err, res2)
      print(vim.inspect({ res1, res2 }))
    end)
  end)
end


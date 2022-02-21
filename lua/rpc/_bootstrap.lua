vim.o.runtimepath = os.getenv('runtimepath')

local server = require('rpc.server').new()

server.connect()

require(os.getenv('runtimepath'))(server)


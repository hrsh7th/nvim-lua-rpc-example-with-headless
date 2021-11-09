local logger = {}

logger.path = '/tmp/rpc.log'

logger.write = function(...)
  local f = io.open(logger.path, 'a')
  f:write(vim.inspect({ ... }) .. '\n')
  f:flush()
  f:close()
end

return logger


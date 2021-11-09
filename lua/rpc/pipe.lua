return function()
  return {
    callback = function()end,
    read_start = function(self, callback)
      self.callback = callback
    end,
    write = function(self, data)
      self.callback(nil, data)
    end
  }
end

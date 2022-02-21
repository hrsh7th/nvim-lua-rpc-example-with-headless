local state = {}

function state:initiate(params, callback)
end

function state:initiate(params, callback)
end

return function(server)
  local bind = function(method, receiver)
    return function(...)
      return method(receiver, ...)
    end
  end
  server.session.on_request.initiate = bind(state.initiate, state)
end


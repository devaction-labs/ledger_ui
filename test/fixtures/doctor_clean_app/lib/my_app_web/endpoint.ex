defmodule MyAppWeb.Endpoint do
  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options], compress: true]
end

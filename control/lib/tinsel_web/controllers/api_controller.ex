defmodule TinselWeb.ApiController do
  use TinselWeb, :controller

  require Logger

  def new_post(conn, params) do
    Logger.info(inspect(params))

    TinselWeb.Endpoint.broadcast_from!(
      self(),
      # "updates/" <> id,
      "updates/",
      "data",
      %{message: params["message"]}
    )

    json(conn, %{})
  end
end

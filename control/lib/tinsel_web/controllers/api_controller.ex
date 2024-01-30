defmodule TinselWeb.ApiController do
  use TinselWeb, :controller

  alias Tinsel.Chat

  require Logger

  def new_post(conn, params) do
    Logger.info(inspect(params))

    # actually I think posting to updates/ is alright?
    # for now we'll keep it user id based, but the user id
    # should be gotten from the API key

    Chat.new_thread(1, params["content"])

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

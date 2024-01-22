defmodule Tinsel.Browse do
  require Logger
  require HTTPoison

  def handle_call(%{"url" => url}) do
    case HTTPoison.get(url, [], follow_redirect: true) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}

      err ->
        Logger.error(inspect(err))
        {:error, "Getting the requested site failed"}
    end
  end
end

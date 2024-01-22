defmodule Tinsel.Language do
  alias Tinsel.Tools

  require Logger
  require HTTPoison

  def simplify_message(%{
        "choices" => [%{"finish_reason" => "tool_calls", "message" => message}]
      }) do
    message
  end

  def simplify_message(unknown) do
    Logger.info("unknown")
    Logger.info(inspect(unknown))
    unknown
  end

  def simplify_messages(messages) do
    messages |> Enum.map(fn message -> simplify_message(message) end)
  end

  def get_completions(messages) do
    url = "localhost:5000/v1/chat/completions"
    headers = ["Content-Type": "application/json"]

    messages = simplify_messages(messages)

    messages_with_default =
      case length(messages) do
        1 ->
          [
            %{
              content:
                "You are a helpful assistant that is curt and to the point.",
              role: "system"
            }
          ] ++ messages

        _ ->
          messages
      end

    body =
      %{
        messages: messages_with_default,
        tools: Tools.get_enabled_tools(),
        max_tokens: 512
      }
      |> Jason.encode!()

    case HTTPoison.post(url, body, headers,
           timeout: 50_000,
           recv_timeout: 50_000
         ) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, %{status_code: status_code, body: body}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, %{reason: reason}}
    end
  end
end

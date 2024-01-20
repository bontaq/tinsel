defmodule Tinsel.Tools do
  alias Tinsel.Browse
  require Logger

  # reminder
  # get a website
  def get_tools() do
    [
      %{
        type: "function",
        function: %{
          name: "get_website",
          description: "Retrieve the contents of a website",
          parameters: %{
            type: "object",
            properties: %{
              url: %{
                type: "string",
                description: "The url of the website"
              }
            },
            required: ["url"]
          }
        }
      }
    ]
  end

  def get_enabled_tools() do
    get_tools()
  end

  # %{"choices" => [%{"finish_reason" => "tool_calls", "index" => 0, "logprobs" => nil, "message" => %{"content" => nil, "function_call" => nil, "role" => "assistant", "tool_calls" => [%{"function" => %{"arguments" => "{\"url\": \"https://news.ycombinator.com/\"}", "name" => "get_website"}, "id" => "call_445505f3fbaf4306bda920d9d51feab3", "type" => "function"}]}}], "created" => 1705768944, "id" => "mistralai/Mixtral-8x7B-Instruct-v0.1-yf0Iv1zdTIhNp0_Ka1Dug5dwuGq6asQ3cu0VMpZl9BA", "model" => "mistralai/Mixtral-8x7B-Instruct-v0.1", "object" => "text_completion", "system_fingerprint" => nil, "usage" => %{"completion_tokens" => 71, "prompt_tokens" => 466, "total_tokens" => 537}}

  def is_tool_call(message) do
    case message do
      %{"choices" => [%{"finish_reason" => "tool_calls"}]} -> true
      _ -> false
    end
  end

  def call_tool(%{
        "function" => %{"arguments" => arguments, "name" => name},
        "id" => id
      }) do
    case name do
      "get_website" ->
        reply = Browse.handle_call(arguments |> Jason.decode!())

        # messages.append({
        # "role": "tool", "content": content, "tool_call_id": tool_id, "name": tool_name}
        case reply do
          {:ok, content} ->
            TinselWeb.Endpoint.broadcast_from!(
              self(),
              # "updates/" <> id,
              "updates/",
              "data",
              %{type: "tool", role: "tool", content: content, tool_call_id: id, name: name}
            )
        end
    end
  end

  def handle_tool_call(message) do
    tool_calls =
      case message do
        %{"choices" => [%{"message" => %{"tool_calls" => tool_calls}}]} ->
          tool_calls

        _ ->
          []
      end

    tool_calls |> Enum.map(fn call -> call_tool(call) end)
  end
end

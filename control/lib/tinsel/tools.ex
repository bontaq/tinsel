defmodule Tinsel.Tools do
  alias Tinsel.Browse
  require Logger

  # reminder
  # get a website
  def get_tools() do
    [
      #      %{
      #        type: "function",
      #        function: %{
      #          name: "get_website",
      #          description: "Retrieve the contents of a website",
      #          parameters: %{
      #            type: "object",
      #            properties: %{
      #              url: %{
      #                type: "string",
      #                description: "The url of the website"
      #              }
      #            },
      #            required: ["url"]
      #          }
      #        }
      #      },
      %{
        type: "function",
        function: %{
          name: "pipeline",
          description: "Perform the next part of a task",
          parameters: %{
            type: "object",
            properties: %{
              continuation: %{
                type: "string",
                description: "The next part of the task to perform"
              }
            },
            required: ["continuation"]
          }
        }
      },
      %{
        type: "function",
        function: %{
          name: "set_reminder",
          description: "Schedule something to happen at a set time",
          parameters: %{
            type: "object",
            properties: %{
              time: %{
                type: "string",
                description:
                  "The time at which the event should happen in elixir UTC format"
              }
            },
            required: ["time"]
          }
        }
      },
      %{
        type: "function",
        function: %{
          name: "get_time",
          description: "Get the current time",
          parameters: %{
            type: "object",
            properties: %{},
            required: []
          }
        }
      }
    ]
  end

  def get_enabled_tools() do
    get_tools()
  end

  # %{"choices" => [%{"finish_reason" => "tool_calls", "index" => 0, "logprobs" => nil, "message" => %{"content" => nil, "function_call" => nil, "role" => "assistant", "tool_calls" => [%{"function" => %{"arguments" => "{\"url\": \"https://news.ycombinator.com/\"}", "name" => "get_website"}, "id" => "call_445505f3fbaf4306bda920d9d51feab3", "type" => "function"}]}}], "created" => 1705768944, "id" => "mistralai/Mixtral-8x7B-Instruct-v0.1-yf0Iv1zdTIhNp0_Ka1Dug5dwuGq6asQ3cu0VMpZl9BA", "model" => "mistralai/Mixtral-8x7B-Instruct-v0.1", "object" => "text_completion", "system_fingerprint" => nil, "usage" => %{"completion_tokens" => 71, "prompt_tokens" => 466, "total_tokens" => 537}}

  def get_tool_calls(%{
        "choices" => [%{"finish_reason" => "tool_calls", "message" => message}]
      }) do
    message
  end

  def is_tool_call(message) do
    case message do
      %{"choices" => [%{"finish_reason" => "tool_calls"}]} -> true
      _ -> false
    end
  end

  def call_tool(topic, %{
        "function" => %{"arguments" => arguments, "name" => name},
        "id" => id
      }) do
    case name do
      "set_reminder" ->
        args =
          arguments
          |> Jason.decode!()
          |> Map.put("user_id", 1)
          |> Map.put("tool_call_id", id)

        Tinsel.Schedule.set_reminder(args)

      "pipeline" ->
        args = arguments |> Jason.decode!()

        TinselWeb.Endpoint.broadcast_from!(
          self(),
          topic,
          "data",
          %{
            type: "tool_reply",
            role: "tool",
            content: args["continuation"],
            tool_call_id: id,
            name: name
          }
        )

      "get_time" ->
        %{
          role: "tool",
          content: "#{DateTime.utc_now()}",
          tool_call_id: id,
          name: name
        }

      "get_website" ->
        reply = Browse.handle_call(arguments |> Jason.decode!())

        case reply do
          {:ok, content} ->
            %{
              type: "tool_reply",
              role: "tool",
              content: content,
              tool_call_id: id,
              name: name
            }
        end
    end
  end

  def handle_tool_call(topic, message) do
    tool_calls =
      case message do
        %{"choices" => [%{"message" => %{"tool_calls" => tool_calls}}]} ->
          tool_calls

        _ ->
          []
      end

    tool_calls |> Enum.map(fn call -> call_tool(topic, call) end)
  end
end

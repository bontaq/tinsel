defmodule Tinsel.Coordinator do
  alias Tinsel.Tools
  alias Tinsel.Language

  require Logger

  def run_chat(topic, messages) do
    # this will take responses, determine if they're a tool call, and continue
    reply = Language.get_completion(messages.messages)

    Logger.info("run chat entrance")

    case reply do
      {:ok, message} ->
        TinselWeb.Endpoint.broadcast_from!(
          self(),
          topic,
          "new_response",
          %{type: "reply", message: message}
        )

        Logger.info("run chat message")

        # I think this will have to look at the last message?
        if Tools.is_tool_call(message) do
          Logger.info("run chat tool call")

          reply = Tools.handle_tool_call(topic, message)

          case reply do
            [tool_reply] ->
              TinselWeb.Endpoint.broadcast_from!(
                self(),
                topic,
                "new_response",
                %{type: "reply", message: tool_reply}
              )

              # now we have to put the reply into messages and run it again
              Logger.info("repeating, tool reply #{inspect(tool_reply)}")

              new_messages =
                messages.messages ++
                  [%{type: "tool_request", raw: Tools.get_tool_calls(message)}] ++
                  [%{type: "tool_reply", raw: tool_reply}]

              run_chat(topic, %{messages: new_messages})
          end
        end
    end
  end
end

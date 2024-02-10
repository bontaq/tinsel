defmodule TinselWeb.ThreadLive do
  use TinselWeb, :live_view
  alias Tinsel.Language
  alias Tinsel.Tools
  alias Tinsel.Models.Message
  alias Tinsel.Models.Thread
  import Ecto.Query
  alias Tinsel.Repo

  require Logger

  @topic "updates/thread/"

  def mount(params, session, socket) do
    # thread_id = session["thread_id"]
    %{"thread_id" => thread_id, "user_id" => user_id} = session
    thread = Repo.get(Thread, thread_id) |> Repo.preload([:messages])

    form = to_form(%{"message" => nil})

    TinselWeb.Endpoint.subscribe(@topic <> "#{user_id}/#{thread.id}")

    {:ok,
     assign(socket,
       form: form,
       messages: thread.messages,
       thread_id: thread_id,
       topic: @topic <> "#{user_id}/#{thread.id}",
       user_id: user_id
     )}
  end

  def handle_event("delete_thread", _params, socket) do
    Repo.get(Thread, socket.assigns.thread_id) |> Repo.delete!()
    {:noreply, socket}
  end

  def handle_event("add_message", %{"message" => message}, socket) do
    topic = socket.assigns.topic
    current_messages = socket.assigns.messages

    # so I think you were considering,
    # each message has a type and a raw?
    # it's kind of an ugly format man this
    # annoys me
    # buhh flatmap.  with no fucking types!
    # it always wants the messages in choices.  ok.
    # message =
    #   Message.changeset(%Message{}, %{
    #     type: "user",
    #     raw: %{role: "user", content: message},
    #     thread_id: socket.assigns.thread_id
    #   })
    #   |> Repo.insert!()

    messages = current_messages ++ [%{type: "user", raw: %{role: "user", content: message}}]

    Task.start(fn ->
      TinselWeb.Endpoint.broadcast_from!(
        self(),
        topic,
        "data",
        %{type: "user", message: messages}
      )
    end)

    {:noreply, assign(socket, messages: messages)}
  end

  def display_message(message) do
    # Logger.error(inspect(message))

    case message |> Map.get(:type) do
      "api" ->
        %{type: "message", content: "api"}

      "user" ->
        %{
          type: "message",
          content: message.raw["content"] || message.raw.content
        }

      _ ->
        %{type: "message", content: inspect message}
    end

    #    case message do
    #      %{content: content, role: "user"} ->
    #        %{type: "message", content: content}
    #
    #      %{"choices" => [%{"finish_reason" => "tool_calls"}]} ->
    #        %{type: "tool_call", content: "Tool calls"}
    #
    #      %{type: "tool_reply"} ->
    #        %{type: "tool_reply", content: "Tool reply"}
    #
    #      %{
    #        "choices" => [
    #          %{"finish_reason" => "stop", "message" => %{"content" => content}}
    #        ]
    #      } ->
    #        %{type: "ai_reply", content: content}
    #    end
  end

  def display_messages(messages) do
    messages |> Enum.map(fn message -> display_message(message) end)
  end

  def messages(assigns) do
    ~H"""
    <div class="messages">
      <%= for message <- display_messages(@messages) do %>
        <div class="message">
          <%= case message.type do %>
            <% "message" -> %>
              <p><%= message.content %></p>
            <% "tool_call" -> %>
              <p>Tool call</p>
            <% "tool_reply" -> %>
              <p>Tool reply</p>
            <% "ai_reply" -> %>
              <p><%= message.content %></p>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div class="thread">
      <button phx-click="delete_thread">Delete</button>
      <.messages messages={@messages} />
      <.simple_form for={@form} id="chat_form" phx-submit="add_message">
        <.input type="text" field={@form[:message]} />
        <button>Send</button>
      </.simple_form>
    </div>
    """
  end

  # define your types
  # user
  # reply
  # tool_request

  def run_chat(topic, payload) do
        Logger.error("run_chat.user")
        Logger.info(inspect(payload))
    case payload.type do
      "user" ->
        reply = Language.get_completions(payload.message)


        case reply do
          {:ok, message} ->
            TinselWeb.Endpoint.broadcast_from!(
              self(),
              topic,
              "data",
              %{type: "reply", message: message}
            )
        end

      "reply" ->
        reply = Language.get_completions(payload.message)

        case reply do
          {:ok, message} ->
            TinselWeb.Endpoint.broadcast_from!(
              self(),
              topic,
              "data",
              %{type: "reply", message: message}
            )
        end

      "tool_request" ->
        Logger.error("Tool request")
        # this should probably be syncronous?
        reply = Tools.handle_tool_call(topic, payload.message |> List.last())

        Logger.info(inspect reply)

        case reply do
          [reply] ->
            TinselWeb.Endpoint.broadcast_from!(
              self(),
              topic,
              "data",
              %{type: "tool_reply", raw: reply}
            )
        end

      other ->
        Logger.info("other")
        Logger.info(inspect(other))
     end
  end

  def handle_info(%{event: "data", payload: payload}, socket) do
    topic = socket.assigns.topic

    Logger.info(inspect(payload))

    case payload.type do
      "user" ->
        Task.start(fn -> run_chat(topic, payload) end)
        {:noreply, socket}

      "reply" ->
        messages = socket.assigns.messages ++ [payload.message]

        Logger.error("handle_info.reply")

        if Tools.is_tool_call(payload.message) do
          Task.start(fn ->
            run_chat(topic, %{type: "tool_request", message: messages})
          end)
        end

        {:noreply, assign(socket, messages: messages)}

      "tool_reply" ->
        messages = socket.assigns.messages ++ [payload]

        Task.start(fn ->
          run_chat(topic, %{type: "reply", message: messages})
        end)

        {:noreply, assign(socket, messages: messages)}

      other ->
        Logger.info("other")
        Logger.info(inspect(other))
        {:noreply, assign(socket, messages: payload.messages)}
    end
  end
end

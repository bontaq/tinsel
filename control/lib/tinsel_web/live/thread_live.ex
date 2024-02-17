defmodule TinselWeb.ThreadLive do
  use TinselWeb, :live_view
  alias Tinsel.Language
  alias Tinsel.Tools
  alias Tinsel.Coordinator
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

    TinselWeb.Endpoint.subscribe(@topic <> "#{thread.id}")

    {:ok,
     assign(socket,
       form: form,
       messages: thread.messages,
       thread_id: thread_id,
       topic: @topic <> "#{thread.id}",
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

    messages =
      current_messages ++
        [%{type: "user", raw: %{role: "user", content: message}}]

    Task.start(fn ->
      TinselWeb.Endpoint.broadcast_from!(
        self(),
        topic,
        "user_message",
        %{messages: messages}
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
        message
        # %{type: "reply", content: inspect(message)}
    end
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
            <% "ai_reply" -> %>
              <p><%= message.content %></p>
            <% "tool_reply" -> %>
              <p>Tool reply</p>
            <% "tool_calls" -> %>
              <p>Tool call</p>
            <% "reply" -> %>
              <p><%= message.raw["content"] %></p>
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

  def handle_info(
        %{
          event: "new_response",
          payload: %{
            :message => %{
              "choices" => [%{"finish_reason" => "stop", "message" => message}]
            }
          }
        },
        socket
      ) do
    current_messages = socket.assigns.messages

    messages = current_messages ++ [%{type: "reply", raw: message}]

    {:noreply, assign(socket, messages: messages)}
  end

  def handle_info(
        %{
          event: "new_response",
          payload: %{
            :message => %{
              "choices" => [
                %{"finish_reason" => "tool_calls", "message" => message}
              ]
            }
          }
        },
        socket
      ) do
    current_messages = socket.assigns.messages

    messages = current_messages ++ [%{type: "tool_calls", raw: message}]

    {:noreply, assign(socket, messages: messages)}
  end

  def handle_info(
        %{
          event: "new_response",
          payload: %{:message => message}
        },
        socket
      ) do
    current_messages = socket.assigns.messages

    messages = current_messages ++ [%{type: "tool_reply", raw: message}]

    {:noreply, assign(socket, messages: messages)}
  end

  def handle_info(%{event: "user_message", payload: payload}, socket) do
    topic = socket.assigns.topic

    Logger.info("handle_info")
    Logger.info(Jason.encode!(payload))

    Task.start(fn -> Coordinator.run_chat(topic, payload) end)

    {:noreply, socket}
  end
end

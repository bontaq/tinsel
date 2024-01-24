defmodule TinselWeb.HomeLive do
  require Logger
  alias Tinsel.Language
  alias Tinsel.Tools
  use TinselWeb, :live_view

  # async replies
  # tool handling
  # background prompt should be customizable like the main thread

  @topic "updates/"

  def handle_event("add_message", %{"message" => message}, socket) do
    current_messages = socket.assigns.messages

    message_with_role = %{
      content: message,
      role: "user"
    }

    messages = current_messages ++ [message_with_role]

    user = socket.assigns.current_user

    Task.start(fn ->
      TinselWeb.Endpoint.broadcast_from!(
        self(),
        "updates/#{user.id}",
        "data",
        %{messages: messages, type: "user"}
      )
    end)

    {:noreply, assign(socket, messages: messages)}
  end

  def clean_message(message) do
    Logger.error(inspect(message))

    case message do
      %{content: content, role: "user"} ->
        %{type: "message", content: content}

      %{"choices" => [%{"finish_reason" => "tool_calls"}]} ->
        %{type: "tool_call", content: "Tool calls"}

      %{type: "tool_reply"} ->
        %{type: "tool_reply", content: "Tool reply"}

      %{
        "choices" => [
          %{"finish_reason" => "stop", "message" => %{"content" => content}}
        ]
      } ->
        %{type: "ai_reply", content: content}
    end
  end

  def clean_messages(messages) do
    messages |> Enum.map(fn message -> clean_message(message) end)
  end

  def messages(assigns) do
    ~H"""
    <div class="messages">
      <%= for message <- clean_messages(@messages) do %>
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
    <div class="">
      <.messages messages={@messages} />
      <.simple_form for={@form} id="chat_form" phx-submit="add_message">
        <.input type="text" field={@form[:message]} />
        <button>+</button>
      </.simple_form>
    </div>
    """
  end

  def mount(params, session, socket) do
    user = socket.assigns.current_user

    Logger.info("Current user #{user.id}")

    TinselWeb.Endpoint.subscribe(@topic <> "#{user.id}")

    form = to_form(%{"message" => nil})

    {:ok, assign(socket, form: form, messages: []),
     temporary_assigns: [form: form]}
  end

  def run_chat(user, payload) do
    channel = @topic <> "#{user.id}"

    case payload.type do
      "user" ->
        reply = Language.get_completions(payload.messages)

        case reply do
          {:ok, message} ->
            TinselWeb.Endpoint.broadcast_from!(
              self(),
              channel,
              "data",
              %{message: message, type: "reply"}
            )
        end

      "reply" ->
        reply = Language.get_completions(payload.message)

        case reply do
          {:ok, message} ->
            TinselWeb.Endpoint.broadcast_from!(
              self(),
              channel,
              "data",
              %{message: message, type: "reply"}
            )
        end

      "tool_request" ->
        Tools.handle_tool_call(user, payload.message |> List.last())

      other ->
        Logger.info("other")
        Logger.info(inspect(other))
    end
  end

  def handle_info(%{event: "data", payload: payload}, socket) do
    user = socket.assigns.current_user

    case payload.type do
      "user" ->
        Task.start(fn -> run_chat(user, payload) end)
        {:noreply, assign(socket, messages: payload.messages)}

      "reply" ->
        messages = socket.assigns.messages ++ [payload.message]

        if Tools.is_tool_call(payload.message) do
          Task.start(fn ->
            run_chat(user, %{type: "tool_request", message: messages})
          end)
        end

        {:noreply, assign(socket, messages: messages)}

      "tool_reply" ->
        messages = socket.assigns.messages ++ [payload]

        Task.start(fn -> run_chat(user, %{type: "user", messages: messages}) end)

        {:noreply, assign(socket, messages: messages)}

      other ->
        Logger.info("other")
        Logger.info(inspect(other))
        {:noreply, assign(socket, messages: payload.messages)}
    end
  end
end

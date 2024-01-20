defmodule TinselWeb.LandingLive do
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

    Task.start(fn ->
      TinselWeb.Endpoint.broadcast_from!(
        self(),
        # "updates/" <> id,
        "updates/",
        "data",
        %{messages: messages, type: "user"}
      )
    end)

    {:noreply, assign(socket, messages: messages)}
  end

  def messages(assigns) do
    Logger.error(inspect(assigns))

    ~H"""
    <div class="message">
      <%= for message <- @messages do %>
        <p><%= inspect(message) %></p>
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
    # TinselWeb.Endpoint.subscribe(@topic <> id)
    TinselWeb.Endpoint.subscribe(@topic)

    form = to_form(%{"message" => nil})

    {:ok, assign(socket, form: form, messages: []),
     temporary_assigns: [form: form]}
  end

  def run_chat(payload) do
    case payload.type do
      "user" ->
        reply = Language.get_completions(payload.messages)

        case reply do
          {:ok, message} ->
            TinselWeb.Endpoint.broadcast_from!(
              self(),
              # "updates/" <> id,
              "updates/",
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
              # "updates/" <> id,
              "updates/",
              "data",
              %{message: message, type: "reply"}
            )
        end
      "tool" ->
        Tools.handle_tool_call(payload.message |> List.last())

      other ->
        Logger.info("other")
        Logger.info(inspect(other))
    end
  end

  def handle_info(%{event: "data", payload: payload}, socket) do
    Logger.info("Made it")
    Logger.info(inspect(payload))

    case payload.type do
      "user" ->
        Task.start(fn -> run_chat(payload) end)
        {:noreply, assign(socket, messages: payload.messages)}
      "reply" ->
        messages = socket.assigns.messages ++ [payload.message]
        if Tools.is_tool_call(payload.message) do
          Task.start(fn ->
            run_chat(%{ type: "tool", message: messages})
          end)
        end
        {:noreply, assign(socket, messages: messages)}
      "tool" ->
        messages = socket.assigns.messages ++ [payload]
        Task.start(fn -> run_chat(%{ type: "user", messages: messages }) end)
        {:noreply, assign(socket, messages: messages)}
      other ->
        Logger.info("other")
        Logger.info(inspect(other))
        {:noreply, assign(socket, messages: payload.messages)}
     end

    # we want to display the message
    # messages = socket.assigns.messages ++ [payload]

    # reply = Language.get_completions(messages)

    # Logger.info(inspect messages)

    # case reply do
    #   {:ok, message} ->
    #     {:noreply, assign(socket, messages: messages ++ [message])}

    #   err ->
    #     Logger.error(inspect err)
    #     {:noreply, socket}
    # end

    # {:noreply, socket}
  end
end

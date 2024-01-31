defmodule TinselWeb.HomeLive do
  require Logger
  alias Tinsel.Language
  alias Tinsel.Tools
  alias Tinsel.Chat
  alias Tinsel.Models.Thread
  alias TinselWeb.ThreadLive

  import Ecto.Query
  alias Tinsel.Repo
  use TinselWeb, :live_view

  # async replies
  # tool handling
  # background prompt should be customizable like the main thread
  @topic "updates/"

  # <.live_component module={HeroComponent} id="hero" content={@content} />

  def render(assigns) do
    # <.live_component
    #  module={ThreadLive}
    #  id={thread_id}
    #  thread_id={thread_id}
    #  current_user={@current_user}
    # />
    ~H"""
    <div class="">
      <button phx-click="new_thread">New Thread</button>
      <div class="threads">
        <%= for thread_id <- @thread_ids do %>
          <%= live_render(
            @socket,
            ThreadLive,
            id: thread_id,
            session: %{"thread_id" => thread_id, "user_id" => @current_user.id}
          ) %>
        <% end %>
      </div>
    </div>
    """
  end

  def handle_event("new_thread", _value, socket) do
    {:ok, %{:thread_id => thread_id}} =
      Chat.new_thread(socket.assigns.current_user.id)

    thread_ids = [thread_id] ++ socket.assigns.thread_ids
    {:noreply, assign(socket, :thread_ids, thread_ids)}
  end

  def mount(params, session, socket) do
    user = socket.assigns.current_user

    Logger.info("Current user #{user.id}")

    thread_ids =
      from(p in Thread,
        select: p.id,
        where: p.user_id == ^user.id
      )
      |> Repo.all()

    # TinselWeb.Endpoint.subscribe(@topic <> "#{user.id}")

    {:ok, assign(socket, :thread_ids, thread_ids), temporary_assigns: []}
  end
end

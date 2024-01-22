defmodule TinselWeb.ToolsLive do
  use TinselWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="">
      <p>prompt</p>
      <p>tools</p>
    </div>
    """
  end

  def mount(params, session, socket) do
    user = socket.assigns.current_user

    Logger.info("Current user #{user.id}")

    form = to_form(%{"message" => nil})

    {:ok, assign(socket, form: form, messages: []),
     temporary_assigns: [form: form]}
  end
end

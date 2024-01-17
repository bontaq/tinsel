defmodule TinselWeb.LandingLive do
  use TinselWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="">
      <.simple_form for={@form} id="chat_form" action={~p"/"}>
      </.simple_form>
    </div>
    """
  end

  def mount(params, session, socket) do
    {:ok, socket}
  end
end

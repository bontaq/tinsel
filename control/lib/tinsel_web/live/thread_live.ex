defmodule TinselWeb.ThreadLive do
  use TinselWeb, :live_component

  def update(assigns, socket) do
    user = Repo.get!(User, assigns.id)
    {:ok, assign(socket, :user, user)}
  end

  def render(assigns) do
    ~H"""
    <div class="hero">hello</div>
    """
  end
end

defmodule TinselWeb.LandingLive do
  require Logger
  alias Tinsel.Language
  alias Tinsel.Tools
  use TinselWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="">
      <h1>Hello</h1>
    </div>
    """
  end

  def mount(params, session, socket) do
    form = to_form(%{"message" => nil})

    {:ok, assign(socket, form: form, messages: []),
     temporary_assigns: [form: form]}
  end
end

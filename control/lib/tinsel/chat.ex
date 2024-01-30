defmodule Tinsel.Chat do
  alias Tinsel.Models.Message
  alias Tinsel.Models.Thread

  alias Tinsel.Repo
  import Ecto.Changeset

  def new_thread(user_id, message) do
    # create the message then the thread
    thread =
      Thread.changeset(%Thread{}, %{title: "Nameless", user_id: user_id})
      |> Repo.insert!()

    Message.changeset(%Message{}, %{
      type: "api",
      raw: %{type: "message", content: message},
      thread_id: thread.id
    })
    |> Repo.insert!()

    {:ok, %{user_id: user_id, thread_id: thread.id}}
  end

  def new_thread(user_id) do
    # create the message then the thread
    thread =
      Thread.changeset(%Thread{}, %{title: "Nameless", user_id: user_id})
      |> Repo.insert!()

    {:ok, %{user_id: user_id, thread_id: thread.id}}
  end
end

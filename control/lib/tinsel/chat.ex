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



    {:ok, thread.id}
  end
end

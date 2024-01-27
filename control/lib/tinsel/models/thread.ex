defmodule Tinsel.Models.Thread do
  alias Tinsel.Accounts.User
  alias Tinsel.Models.Message

  import Ecto.Changeset

  use Ecto.Schema

  schema "threads" do
    field(:title, :string)
    belongs_to(:users, User)
    has_many(:messages, Message)
  end

  @doc false
  def changeset(data, attrs) do
    data
    |> cast(attrs, [:title, :user_id])
    |> validate_required([:title, :user_id])
  end

end

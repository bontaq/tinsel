defmodule Tinsel.Models.Message do
  alias Tinsel.Models.Thread

  import Ecto.Changeset

  use Ecto.Schema

  schema "messages" do
    field(:type, :string)
    field(:raw, :map)
    field(:thread_id, :integer)
    belongs_to(:threads, Thread)
  end

  @doc false
  def changeset(data, attrs) do
    data
    |> cast(attrs, [:title, :user_id])
    |> validate_required([:title, :user_id])
  end
end

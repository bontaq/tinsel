defmodule Tinsel.Models.Message do
  alias Tinsel.Models.Thread

  import Ecto.Changeset

  use Ecto.Schema

  schema "messages" do
    field(:type, :string)
    field(:raw, :map)
    belongs_to(:thread, Thread)

    timestamps()
  end

  @doc false
  def changeset(data, attrs) do
    data
    |> cast(attrs, [:type, :raw, :thread_id])
    |> validate_required([:type, :raw, :thread_id])
  end
end

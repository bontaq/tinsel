defmodule Tinsel.Repo.Migrations.AddThreadsMessages do
  use Ecto.Migration

  def change do
    create table(:threads) do
      add :title, :string
      add :user_id, references(:users)

      timestamps()
    end

    create table(:messages) do
      add :type, :string
      add :raw, :jsonb
      add :thread_id, references(:threads)

      timestamps()
    end

    create index(:messages, [:thread_id])
  end
end

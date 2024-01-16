defmodule Tinsel.Repo do
  use Ecto.Repo,
    otp_app: :tinsel,
    adapter: Ecto.Adapters.Postgres
end

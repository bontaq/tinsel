defmodule Tinsel.Schedule do
  use Oban.Worker, queue: :events

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"user_id" => id} = args}) do
    TinselWeb.Endpoint.broadcast_from!(
      self(),
      "updates/#{id}",
      "data",
      %{
        type: "tool_reply",
        role: "tool",
        content: "15:34:00",
        tool_call_id: "",
        name: "set_reminder"
      }
    )

    :ok
  end

  def set_reminder(%{
        "user_id" => user_id,
        "time" => time,
        "tool_call_id" => tool_call_id
      }) do
    Logger.info("Scheduling for #{user_id} at #{time}")
    #    %{user_id: 1}
    #    |> Tinsel.Schedule.new(scheduled_at: ~U[2020-12-25 19:00:56.0Z])
    #    |> Oban.insert()

    {:ok, date_time, offset} =
      DateTime.from_iso8601("2024-01-24 02:06:00.000000Z")

    TinselWeb.Endpoint.broadcast_from!(
      self(),
      "updates/#{user_id}",
      "data",
      %{
        type: "tool_reply",
        role: "tool",
        content: time,
        tool_call_id: tool_call_id,
        name: "set_reminder"
      }
    )
  end
end

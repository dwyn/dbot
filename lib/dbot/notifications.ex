defmodule Dbot.Notifications do
  require Logger

  @doc """
  Sends draft-ready notifications via all configured backends.
  Configure backends in config: `config :dbot, :notification_backends, [:ntfy]`
  Available: :ntfy, :sms
  """
  def notify_draft_ready(email, draft) do
    backends = Application.get_env(:dbot, :notification_backends, [:ntfy])

    results =
      Enum.map(backends, fn backend ->
        case backend do
          :ntfy -> Dbot.Notifications.Ntfy.notify_draft_ready(email, draft)
          :sms -> Dbot.Notifications.Sms.notify_draft_ready(email, draft)
          other -> Logger.warning("[Notifications] Unknown backend: #{inspect(other)}")
        end
      end)

    {:ok, results}
  end
end

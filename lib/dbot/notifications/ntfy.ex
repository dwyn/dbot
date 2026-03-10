defmodule Dbot.Notifications.Ntfy do
  require Logger

  def notify_draft_ready(email, draft) do
    topic = Application.get_env(:dbot, :ntfy_topic)

    if is_nil(topic) do
      Logger.warning("[Ntfy] Topic not configured — skipping")
      {:ok, :skipped}
    else
      url = "https://ntfy.sh/#{topic}"
      message = compose(email, draft)
      title = "dbot: Draft Ready"
      tags = if draft.is_snarky, do: "warning", else: "email"

      case Req.post(url,
             body: message,
             headers: [
               {"title", title},
               {"tags", tags},
               {"priority", "default"}
             ]
           ) do
        {:ok, %{status: status}} when status in 200..299 ->
          Logger.info("[Ntfy] Notification sent to topic #{topic}")
          {:ok, :sent}

        {:ok, %{status: status, body: body}} ->
          Logger.error("[Ntfy] Failed (#{status}): #{inspect(body)}")
          {:error, body}

        {:error, reason} ->
          Logger.error("[Ntfy] Request failed: #{inspect(reason)}")
          {:error, reason}
      end
    end
  end

  defp compose(email, draft) do
    type = if draft.is_snarky, do: "Snarky fallback", else: "AI draft reply"
    subject = truncate(email.subject, 40)

    "#{type} ready for email from #{email.from_address}.\nSubject: \"#{subject}\"\nCheck Gmail drafts."
  end

  defp truncate(nil, _), do: "(no subject)"

  defp truncate(str, max) do
    if String.length(str) > max, do: String.slice(str, 0, max) <> "...", else: str
  end
end

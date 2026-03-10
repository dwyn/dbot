defmodule Dbot.Notifications.Sms do
  require Logger

  def notify_draft_ready(email, draft) do
    to = Application.get_env(:dbot, :notification_phone)
    from = Application.get_env(:dbot, :twilio_from_number)

    if is_nil(to) or is_nil(from) do
      Logger.warning("[SMS] Phone numbers not configured — skipping")
      {:ok, :skipped}
    else
      message = compose(email, draft)

      case ExTwilio.Message.create(to: to, from: from, body: message) do
        {:ok, msg} ->
          Logger.info("[SMS] Sent, SID: #{msg.sid}")
          {:ok, msg}

        {:error, msg, code} ->
          Logger.error("[SMS] Failed (#{code}): #{msg}")
          {:error, msg}
      end
    end
  end

  defp compose(email, draft) do
    type = if draft.is_snarky, do: "snarky fallback", else: "AI draft reply"
    subject = truncate(email.subject, 40)

    "dbot: #{type} ready for email from #{email.from_address}. Subject: \"#{subject}\". Check Gmail drafts."
  end

  defp truncate(nil, _), do: "(no subject)"

  defp truncate(str, max) do
    if String.length(str) > max, do: String.slice(str, 0, max) <> "...", else: str
  end
end

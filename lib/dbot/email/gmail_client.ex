defmodule Dbot.Email.GmailClient do
  alias GoogleApi.Gmail.V1.Api.Users
  alias GoogleApi.Gmail.V1.Connection

  def connection do
    {:ok, %{token: token}} = Goth.fetch(Dbot.Goth)
    Connection.new(token)
  end

  def list_messages(opts \\ []) do
    Users.gmail_users_messages_list(connection(), "me",
      q: Keyword.get(opts, :q, "in:inbox is:unread"),
      maxResults: Keyword.get(opts, :max, 20)
    )
  end

  def get_message(message_id) do
    Users.gmail_users_messages_get(connection(), "me", message_id, format: "full")
  end

  def list_sent(opts \\ []) do
    Users.gmail_users_messages_list(connection(), "me",
      q: "in:sent",
      maxResults: Keyword.get(opts, :max, 500)
    )
  end

  def create_draft(to, subject, body, thread_id \\ nil) do
    raw = build_raw(to, subject, body, thread_id)

    Users.gmail_users_drafts_create(connection(), "me",
      body: %GoogleApi.Gmail.V1.Model.Draft{
        message: %GoogleApi.Gmail.V1.Model.Message{
          raw: Base.url_encode64(raw, padding: false),
          threadId: thread_id
        }
      }
    )
  end

  defp build_raw(to, subject, body, thread_id) do
    lines = [
      "To: #{to}",
      "Subject: #{subject}",
      "MIME-Version: 1.0",
      "Content-Type: text/plain; charset=UTF-8"
    ]

    lines = if thread_id, do: lines ++ ["In-Reply-To: #{thread_id}"], else: lines
    Enum.join(lines, "\r\n") <> "\r\n\r\n" <> body
  end
end

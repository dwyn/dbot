defmodule Dbot.Email do
  alias Dbot.{Repo, Email.Email}
  alias Dbot.Email.{GmailClient, Processor}
  import Ecto.Query, warn: false

  def fetch_and_process_new do
    case GmailClient.list_messages(q: "in:inbox is:unread") do
      {:ok, %{messages: nil}} ->
        {:ok, 0}

      {:ok, %{messages: messages}} ->
        new_msgs = Enum.reject(messages, fn %{id: id} -> already_seen?(id) end)
        Enum.each(new_msgs, &Processor.process_async/1)
        {:ok, length(new_msgs)}

      {:error, _} = err ->
        err
    end
  end

  def already_seen?(gmail_id) do
    Repo.exists?(from(e in Email, where: e.gmail_id == ^gmail_id))
  end

  def create_email(attrs) do
    %Email{} |> Email.changeset(attrs) |> Repo.insert()
  end

  def update_email(%Email{} = email, attrs) do
    email |> Email.changeset(attrs) |> Repo.update()
  end

  def list_recent(limit \\ 20) do
    Repo.all(
      from(e in Email,
        order_by: [desc: e.inserted_at],
        limit: ^limit,
        preload: [:drafts]
      )
    )
  end
end

defmodule Dbot.Training.Importer do
  alias Dbot.{Repo, Training.TrainingExample}
  import Ecto.Query, warn: false
  require Logger

  @default_local_path "priv/training_data/local_import.jsonl"

  @doc """
  Import training pairs from a local JSONL file.
  Each line should be: {"input": "received email", "output": "your reply"}
  Optionally include "subject" and "from" fields for metadata.
  """
  def import_local(path \\ @default_local_path) do
    case File.read(path) do
      {:ok, content} ->
        lines = String.split(content, "\n", trim: true)

        {imported, skipped} =
          Enum.reduce(lines, {0, 0}, fn line, {imp, skip} ->
            case parse_and_insert(line) do
              :ok -> {imp + 1, skip}
              :skipped -> {imp, skip + 1}
              :error -> {imp, skip + 1}
            end
          end)

        Logger.info("[Importer] Local import complete: #{imported} imported, #{skipped} skipped")
        {:ok, imported}

      {:error, reason} ->
        Logger.error("[Importer] Could not read #{path}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp parse_and_insert(line) do
    case Jason.decode(line) do
      {:ok, %{"input" => input, "output" => output} = data} when input != "" and output != "" ->
        attrs = %{
          source: "local",
          input: input,
          output: output,
          metadata: %{
            subject: data["subject"],
            from: data["from"]
          }
        }

        case %TrainingExample{}
             |> TrainingExample.changeset(attrs)
             |> Repo.insert() do
          {:ok, _} -> :ok
          {:error, _} -> :skipped
        end

      {:ok, _} ->
        :skipped

      {:error, _} ->
        Logger.warning("[Importer] Skipping malformed line: #{String.slice(line, 0, 80)}")
        :error
    end
  end

  @doc """
  Import sent email history directly from Gmail API.
  Requires Google credentials to be configured.
  """
  def import_from_gmail(limit \\ 200) do
    alias Dbot.Email.{GmailClient, Parser}

    case GmailClient.list_sent(max: limit) do
      {:ok, %{messages: nil}} ->
        {:ok, 0}

      {:ok, %{messages: messages}} ->
        count =
          messages
          |> Enum.reject(&already_imported_from_gmail?/1)
          |> Enum.reduce(0, fn msg, acc ->
            case build_gmail_pair(msg.id) do
              nil ->
                acc

              attrs ->
                %TrainingExample{}
                |> TrainingExample.changeset(attrs)
                |> Repo.insert(on_conflict: :nothing)

                acc + 1
            end
          end)

        {:ok, count}

      {:error, _} = err ->
        err
    end
  end

  defp already_imported_from_gmail?(%{id: id}) do
    Repo.exists?(
      from(t in TrainingExample,
        where: fragment("metadata->>'gmail_sent_id' = ?", ^id)
      )
    )
  end

  defp build_gmail_pair(sent_msg_id) do
    alias Dbot.Email.{GmailClient, Parser}

    with {:ok, sent_msg} <- GmailClient.get_message(sent_msg_id),
         sent = Parser.parse(sent_msg),
         thread_id when not is_nil(thread_id) <- sent.thread_id,
         {:ok, %{messages: messages}} when is_list(messages) <-
           GmailClient.list_messages(q: "rfc822msgid:#{thread_id}"),
         %{id: prev_id} <- find_preceding(messages, sent_msg_id),
         {:ok, prev_msg} <- GmailClient.get_message(prev_id),
         received = Parser.parse(prev_msg),
         true <- received.body_text != "" and sent.body_text != "" do
      %{
        source: "gmail",
        input: received.body_text,
        output: sent.body_text,
        metadata: %{
          subject: sent.subject,
          gmail_sent_id: sent_msg_id,
          from: received.from_address
        }
      }
    else
      _ -> nil
    end
  end

  defp find_preceding(messages, sent_id) do
    idx = Enum.find_index(messages, fn m -> m.id == sent_id end)
    if idx && idx > 0, do: Enum.at(messages, idx - 1), else: nil
  end
end

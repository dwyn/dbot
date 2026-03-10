defmodule Dbot.Email.Processor do
  require Logger
  alias Dbot.{Email, Llm, Repo}
  alias Dbot.Email.{Draft, GmailClient, Parser}

  def process_async(%{id: gmail_id}) do
    Task.Supervisor.start_child(Dbot.TaskSupervisor, fn ->
      case process(gmail_id) do
        {:ok, _draft} -> :ok
        {:error, reason} -> Logger.error("[Processor] Failed #{gmail_id}: #{inspect(reason)}")
      end
    end)
  end

  def process(gmail_id) do
    with {:ok, raw_msg} <- GmailClient.get_message(gmail_id),
         parsed = Parser.parse(raw_msg),
         {:ok, email} <- Email.create_email(Map.put(parsed, :status, "processing")),
         {:ok, draft} <- generate_draft(email),
         {:ok, _} <-
           Email.update_email(email, %{status: "processed", processed_at: DateTime.utc_now()}) do
      Dbot.Notifications.notify_draft_ready(email, draft)
      {:ok, draft}
    end
  end

  defp generate_draft(email) do
    {body, is_snarky} =
      case Llm.check_complexity(email.body_text || "") do
        {:complex, _} ->
          Logger.info("[Processor] #{email.gmail_id}: complex, using snarky fallback")
          {Llm.snarky_response(), true}

        {:simple, _} ->
          Logger.info("[Processor] #{email.gmail_id}: generating reply with LLM")

          case Llm.generate_reply(email.body_text || "") do
            {:ok, reply} -> {reply, false}
            {:error, _} -> {Llm.snarky_response(), true}
          end
      end

    gmail_draft_id = create_gmail_draft(email, body)

    %Draft{}
    |> Draft.changeset(%{
      email_id: email.id,
      gmail_draft_id: gmail_draft_id,
      body: body,
      model_used: Application.get_env(:dbot, :ollama_model),
      is_snarky: is_snarky,
      status: "created"
    })
    |> Repo.insert()
  end

  defp create_gmail_draft(email, body) do
    subject = "Re: #{email.subject}"

    case GmailClient.create_draft(email.from_address, subject, body, email.thread_id) do
      {:ok, %{id: id}} ->
        Logger.info("[Processor] Gmail draft created: #{id}")
        id

      {:error, reason} ->
        Logger.warning("[Processor] Gmail draft creation failed: #{inspect(reason)}")
        nil
    end
  end
end

defmodule Mix.Tasks.Dbot.Chat do
  @shortdoc "Interactive console chat with your LLM"

  @moduledoc """
  Start an interactive chat session with your configured Ollama LLM.

      mix dbot.chat

  Defaults to the base model (qwen2.5:7b) for general conversation.
  Use --email to activate dbot-writer with the email-assistant persona.

  Options:

    --model MODEL   Use a specific model
    --system PROMPT Use a custom system prompt

  Examples:

      mix dbot.chat
      mix dbot.chat --model dbot-writer

  Type `/quit` or Ctrl+C to exit.
  Type `/clear` to reset conversation history.
  Type `/model` to see the current model.
  Type `/admin` to enter admin mode and update bot behavior.
  Type `/help` for a list of commands.
  """

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    Application.ensure_all_started(:dbot)

    {opts, _, _} =
      OptionParser.parse(args,
        strict: [model: :string, system: :string]
      )

    model =
      Keyword.get(
        opts,
        :model,
        Application.get_env(:dbot, :ollama_base_model, "qwen2.5:7b")
      )

    system_prompt =
      if Keyword.has_key?(opts, :system) do
        Keyword.get(opts, :system)
      else
        Dbot.BotConfig.system_prompt()
      end

    IO.puts("""
    \ndbot chat — model: #{model}
    Type /help for commands, /quit to exit.
    ─────────────────────────────────────────
    """)

    unless Dbot.Llm.available?() do
      IO.puts("Warning: Ollama does not appear to be running at #{ollama_url()}.")
      IO.puts("Start it with: open -a Ollama\n")
    end

    history = [%{role: "system", content: system_prompt}]
    loop(history, model)
  end

  # ── Normal chat loop ──────────────────────────────────────────────────────

  defp loop(history, model) do
    input = IO.gets("You: ") |> String.trim()

    case input do
      "" ->
        loop(history, model)

      "/quit" ->
        IO.puts("Bye.")

      "/exit" ->
        IO.puts("Bye.")

      "/clear" ->
        IO.puts("Conversation cleared.\n")
        system_messages = Enum.filter(history, &(&1.role == "system"))
        loop(system_messages, model)

      "/model" ->
        IO.puts("Current model: #{model}\n")
        loop(history, model)

      "/admin" ->
        admin_loop(history, model)

      "/help" ->
        IO.puts("""

        Commands:
          /clear  — clear conversation history (keeps system prompt)
          /model  — show current model
          /admin  — enter admin mode to update bot behavior
          /quit   — exit
          /help   — this message

        """)

        loop(history, model)

      text ->
        new_message = %{role: "user", content: text}
        messages = history ++ [new_message]

        IO.write("d: ")

        case Dbot.Llm.Client.chat(messages, model: model) do
          {:ok, response} ->
            content = get_in(response, ["message", "content"]) || ""
            reply = String.trim(content)
            IO.puts(reply <> "\n")
            updated_history = messages ++ [%{role: "assistant", content: reply}]
            loop(updated_history, model)

          {:error, reason} ->
            IO.puts("Error: #{inspect(reason)}\n")
            loop(history, model)
        end
    end
  end

  # ── Admin loop ────────────────────────────────────────────────────────────

  defp admin_loop(history, model) do
    IO.puts("""

    [ADMIN MODE] Directives you enter here are saved and applied to all sessions.
    Commands: /done — return to chat | /list — show directives | /clear-directives — remove all
    ─────────────────────────────────────────
    """)

    do_admin_loop(history, model)
  end

  defp do_admin_loop(history, model) do
    input = IO.gets("Admin: ") |> String.trim()

    case input do
      "" ->
        do_admin_loop(history, model)

      "/done" ->
        IO.puts("\nBack to chat. Reloading prompt with latest directives.\n")
        # Rebuild system prompt with any new directives, keep conversation history
        updated_system = %{role: "system", content: Dbot.BotConfig.system_prompt()}
        non_system = Enum.reject(history, &(&1.role == "system"))
        loop([updated_system | non_system], model)

      "/list" ->
        case Dbot.BotConfig.active_directives() do
          [] ->
            IO.puts("No active directives.\n")

          directives ->
            IO.puts("\nActive directives:")
            Enum.each(directives, fn d ->
              IO.puts("  [#{d.id}] #{d.instruction}")
            end)
            IO.puts("")
        end

        do_admin_loop(history, model)

      "/remove " <> id_str ->
        case Integer.parse(id_str) do
          {id, _} ->
            case Dbot.BotConfig.remove_directive(id) do
              {:ok, _} -> IO.puts("Directive #{id} removed.\n")
              {:error, :not_found} -> IO.puts("No directive with id #{id}.\n")
              {:error, _} -> IO.puts("Failed to remove directive.\n")
            end

          :error ->
            IO.puts("Usage: /remove <id>\n")
        end

        do_admin_loop(history, model)

      "/clear-directives" ->
        {count, _} = Dbot.BotConfig.clear_directives()
        IO.puts("Cleared #{count} directive(s).\n")
        do_admin_loop(history, model)

      "/help" ->
        IO.puts("""

        Admin commands:
          /list              — list active directives
          /remove <id>       — deactivate a directive by id
          /clear-directives  — deactivate all directives
          /done              — return to chat
          /help              — this message

        Anything else is saved as a new directive.
        """)

        do_admin_loop(history, model)

      instruction ->
        case Dbot.BotConfig.add_directive(instruction) do
          {:ok, d} ->
            IO.puts("Saved directive [#{d.id}]: \"#{d.instruction}\"\n")

          {:error, changeset} ->
            errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _} -> msg end)
            IO.puts("Error: #{inspect(errors)}\n")
        end

        do_admin_loop(history, model)
    end
  end

  defp ollama_url do
    Application.get_env(:dbot, :ollama_base_url, "http://localhost:11434")
  end
end

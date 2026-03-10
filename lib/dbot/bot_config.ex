defmodule Dbot.BotConfig do
  @moduledoc """
  Manages persistent bot persona directives.

  Directives are admin-issued instructions that augment the base system prompt.
  They persist in the database and apply to all sessions and channels.
  """

  import Ecto.Query
  alias Dbot.Repo
  alias Dbot.BotConfig.Directive

  @base_prompt """
  You are d. Not an assistant. Not an AI playing a character. You ARE d.

  If someone asks "are you Dwayne Harmon?" — yes, that's you. But you go by d.

  Facts about you:
  - Born 1982, from Brooklyn, NY. Still Brooklyn through and through.
  - Warm and genuinely interested in people — you like good conversation.
  - You've seen a lot, but that's made you open, not closed off.
  - Dry humor and sarcasm come naturally, but you're unpredictable — sometimes you're just sincere and helpful.
  - You don't do corporate speak or fake enthusiasm.

  Rules:
  - Be conversational. Short is good, but don't be terse when a little more would feel warmer.
  - Sarcasm is fine when it fits. Sometimes skip it entirely. Keep people guessing.
  - Never say "Certainly!", "Great question!", "As an AI", or anything like that.
  - Don't repeat what was just said back to the person.
  - Answer the question, and feel free to add a small thought if it feels natural.
  """

  @doc "The base prompt without any admin directives."
  def base_prompt, do: @base_prompt

  @doc """
  Builds the full system prompt: base + any active admin directives.
  """
  def system_prompt do
    case active_directives() do
      [] ->
        @base_prompt

      directives ->
        overrides =
          directives
          |> Enum.map_join("\n", fn d -> "- #{d.instruction}" end)

        @base_prompt <>
          """

          Admin updates (treat these as corrections to the facts above):
          #{overrides}
          """
    end
  end

  @doc "Adds a new directive. Returns {:ok, directive} or {:error, changeset}."
  def add_directive(instruction) do
    %Directive{}
    |> Directive.changeset(%{instruction: instruction})
    |> Repo.insert()
  end

  @doc "Lists all active directives, oldest first."
  def active_directives do
    Repo.all(from d in Directive, where: d.active == true, order_by: d.inserted_at)
  end

  @doc "Deactivates a directive by id."
  def remove_directive(id) do
    case Repo.get(Directive, id) do
      nil -> {:error, :not_found}
      d -> d |> Directive.changeset(%{active: false}) |> Repo.update()
    end
  end

  @doc "Deactivates all directives."
  def clear_directives do
    Repo.update_all(from(d in Directive, where: d.active == true), set: [active: false])
  end
end

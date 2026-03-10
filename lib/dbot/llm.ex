defmodule Dbot.Llm do
  alias Dbot.Llm.{Client, PromptBuilder, Complexity, Snarky}

  def generate_reply(email_body) do
    messages = PromptBuilder.reply_messages(email_body)

    case Client.chat(messages) do
      {:ok, response} ->
        content = get_in(response, ["content", Access.at(0), "text"])
        {:ok, String.trim(content || "")}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def check_complexity(email_body), do: Complexity.check(email_body)

  def snarky_response, do: Snarky.random_response()

  def available? do
    Application.get_env(:dbot, :anthropic_api_key) not in [nil, ""]
  end
end

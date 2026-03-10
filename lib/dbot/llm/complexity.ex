defmodule Dbot.Llm.Complexity do
  alias Dbot.Llm.{Client, PromptBuilder}

  def check(email_body) do
    messages = PromptBuilder.complexity_messages(email_body)

    case Client.chat(messages) do
      {:ok, response} ->
        content = get_in(response, ["content", Access.at(0), "text"]) || ""

        case Jason.decode(String.trim(content)) do
          {:ok, %{"complex" => true}} -> {:complex, nil}
          {:ok, %{"complex" => false}} -> {:simple, nil}
          _ -> {:simple, :parse_error}
        end

      {:error, _reason} ->
        {:simple, :llm_error}
    end
  end
end

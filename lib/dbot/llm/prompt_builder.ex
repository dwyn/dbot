defmodule Dbot.Llm.PromptBuilder do
  @email_addendum """

  Write exactly as d would write an email reply:
  - Reply body only — no subject line, no extra metadata.
  - Conversational but efficient. A few sentences is fine when it helps.
  - Never say "Certainly!", "Great question!", or anything like that.
  """

  def reply_messages(incoming_body) do
    system_prompt = Dbot.BotConfig.system_prompt() <> @email_addendum

    few_shot =
      Dbot.Training.sample_for_prompt()
      |> Enum.flat_map(fn {input, output} ->
        [
          %{role: "user", content: "Write a reply to this email:\n\n#{input}"},
          %{role: "assistant", content: output}
        ]
      end)

    [%{role: "system", content: system_prompt}] ++
      few_shot ++
      [%{role: "user", content: "Write a reply to this email:\n\n#{incoming_body}"}]
  end

  def complexity_messages(email_body) do
    [
      %{
        role: "system",
        content: """
        Assess if this email needs a complex response.
        Respond ONLY with valid JSON: {"complex": true} or {"complex": false}.
        Complex = requires research, decisions, commitments, or multi-step coordination.
        Simple = acknowledgement, scheduling, short answers, pleasantries.
        """
      },
      %{role: "user", content: email_body}
    ]
  end
end

defmodule Dbot.Llm.Snarky do
  @responses [
    "This one's a bit above my pay grade. The human will handle it.",
    "Looked at this. Decided it was above my skill level. You're welcome.",
    "I've forwarded this to my manager (the human). They'll surface eventually.",
    "Fascinating email. I've chosen not to respond automatically. Consider it a gift.",
    "I thought about it. I'm passing. The human will deal with it when ready."
  ]

  def random_response, do: Enum.random(@responses)
end

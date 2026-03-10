defmodule Dbot.Llm.Client do
  @api_url "https://api.anthropic.com/v1/messages"
  @api_version "2023-06-01"

  def chat(messages, opts \\ []) do
    model = Keyword.get(opts, :model, Application.get_env(:dbot, :anthropic_model, "claude-sonnet-4-6"))
    api_key = Application.get_env(:dbot, :anthropic_api_key) || raise "ANTHROPIC_API_KEY not configured"

    {system, user_messages} = extract_system(messages)

    body = %{model: model, max_tokens: 1024, messages: user_messages}
    body = if system, do: Map.put(body, :system, system), else: body

    case Req.post(@api_url,
           json: body,
           headers: [
             {"x-api-key", api_key},
             {"anthropic-version", @api_version}
           ]
         ) do
      {:ok, %{status: 200, body: response}} -> {:ok, response}
      {:ok, %{status: status, body: body}} -> {:error, {status, body}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp extract_system(messages) do
    system = Enum.find_value(messages, fn m -> if m[:role] == "system", do: m[:content] end)
    user_messages = Enum.reject(messages, &(&1[:role] == "system"))
    {system, user_messages}
  end
end

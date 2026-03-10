defmodule Dbot.Email.Parser do
  alias GoogleApi.Gmail.V1.Model.Message

  def parse(%Message{} = msg) do
    headers = index_headers(msg.payload && msg.payload.headers)

    %{
      gmail_id: msg.id,
      thread_id: msg.threadId,
      from_address: extract_email(headers["from"] || ""),
      from_name: extract_name(headers["from"] || ""),
      subject: headers["subject"] || "(no subject)",
      body_text: extract_body(msg.payload),
      received_at: parse_timestamp(msg.internalDate)
    }
  end

  defp index_headers(nil), do: %{}

  defp index_headers(headers) do
    Map.new(headers, fn h -> {String.downcase(h.name), h.value} end)
  end

  defp extract_body(nil), do: ""

  defp extract_body(%{mimeType: "text/plain", body: %{data: data}}) when is_binary(data) do
    Base.url_decode64!(data, padding: false)
  end

  defp extract_body(%{parts: parts}) when is_list(parts) do
    plain = Enum.find(parts, fn p -> p.mimeType == "text/plain" end)
    html = Enum.find(parts, fn p -> p.mimeType == "text/html" end)

    cond do
      plain -> extract_body(plain)
      html -> strip_html(extract_body(html))
      true -> ""
    end
  end

  defp extract_body(_), do: ""

  defp strip_html(html) do
    html
    |> String.replace(~r/<[^>]+>/, " ")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  defp extract_email(from) do
    case Regex.run(~r/<([^>]+)>/, from) do
      [_, email] -> email
      _ -> from
    end
  end

  defp extract_name(from) do
    case Regex.run(~r/^"?([^"<]+)"?\s*</, from) do
      [_, name] -> String.trim(name)
      _ -> nil
    end
  end

  defp parse_timestamp(nil), do: nil

  defp parse_timestamp(ms_str) do
    ms_str |> String.to_integer() |> div(1000) |> DateTime.from_unix!()
  end
end

defmodule Dbot.Training.Export do
  alias Dbot.{Repo, Training.TrainingExample}
  import Ecto.Query, warn: false

  def export_jsonl(path \\ "priv/training_data/dataset.jsonl") do
    examples =
      Repo.all(
        from(t in TrainingExample,
          where: t.approved == true,
          order_by: [asc: t.id]
        )
      )

    lines =
      Enum.map(examples, fn ex ->
        Jason.encode!(%{
          messages: [
            %{role: "user", content: ex.input},
            %{role: "assistant", content: ex.output}
          ]
        })
      end)

    File.mkdir_p!(Path.dirname(path))

    case File.write(path, Enum.join(lines, "\n")) do
      :ok -> {:ok, length(examples)}
      {:error, reason} -> {:error, reason}
    end
  end
end

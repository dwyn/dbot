defmodule Dbot.Training do
  alias Dbot.{Repo, Training.TrainingExample}
  import Ecto.Query, warn: false

  def list_examples(opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    Repo.all(
      from(t in TrainingExample,
        order_by: [desc: t.inserted_at],
        limit: ^limit
      )
    )
  end

  def toggle_approved(id) do
    example = Repo.get!(TrainingExample, id)

    example
    |> TrainingExample.changeset(%{approved: !example.approved})
    |> Repo.update()
  end

  def count_examples do
    Repo.aggregate(TrainingExample, :count)
  end

  def count_approved do
    Repo.aggregate(
      from(t in TrainingExample, where: t.approved == true),
      :count
    )
  end

  @doc """
  Returns a random sample of approved examples for few-shot prompting.
  """
  def sample_for_prompt(limit \\ 8) do
    Repo.all(
      from t in TrainingExample,
        where: t.approved == true,
        order_by: fragment("RANDOM()"),
        limit: ^limit,
        select: {t.input, t.output}
    )
  end
end

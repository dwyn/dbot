defmodule Dbot.Training.TrainingExample do
  use Ecto.Schema
  import Ecto.Changeset

  schema "training_examples" do
    field :source, :string, default: "gmail"
    field :input, :string
    field :output, :string
    field :metadata, :map
    field :approved, :boolean, default: true

    timestamps()
  end

  def changeset(example, attrs) do
    example
    |> cast(attrs, [:source, :input, :output, :metadata, :approved])
    |> validate_required([:input, :output])
  end
end

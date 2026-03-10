defmodule Dbot.Repo.Migrations.CreateTrainingExamples do
  use Ecto.Migration

  def change do
    create table(:training_examples) do
      add :source, :string, null: false, default: "gmail"
      add :input, :text, null: false
      add :output, :text, null: false
      add :metadata, :map
      add :approved, :boolean, null: false, default: true

      timestamps()
    end
  end
end

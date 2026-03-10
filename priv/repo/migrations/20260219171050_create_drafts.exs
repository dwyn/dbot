defmodule Dbot.Repo.Migrations.CreateDrafts do
  use Ecto.Migration

  def change do
    create table(:drafts) do
      add :email_id, references(:emails, on_delete: :delete_all), null: false
      add :gmail_draft_id, :string
      add :body, :text, null: false
      add :model_used, :string
      add :is_snarky, :boolean, null: false, default: false
      add :status, :string, null: false, default: "created"

      timestamps()
    end

    create index(:drafts, [:email_id])
  end
end

defmodule Dbot.Repo.Migrations.CreateEmails do
  use Ecto.Migration

  def change do
    create table(:emails) do
      add :gmail_id, :string, null: false
      add :thread_id, :string
      add :from_address, :string, null: false
      add :from_name, :string
      add :subject, :string
      add :body_text, :text
      add :body_html, :text
      add :received_at, :utc_datetime
      add :status, :string, null: false, default: "pending"
      add :processed_at, :utc_datetime

      timestamps()
    end

    create unique_index(:emails, [:gmail_id])
  end
end

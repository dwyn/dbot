defmodule Dbot.Repo.Migrations.CreateBotDirectives do
  use Ecto.Migration

  def change do
    create table(:bot_directives) do
      add :instruction, :text, null: false
      add :active, :boolean, null: false, default: true

      timestamps()
    end
  end
end

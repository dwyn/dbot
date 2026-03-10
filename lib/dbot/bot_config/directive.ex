defmodule Dbot.BotConfig.Directive do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bot_directives" do
    field :instruction, :string
    field :active, :boolean, default: true

    timestamps()
  end

  def changeset(directive, attrs) do
    directive
    |> cast(attrs, [:instruction, :active])
    |> validate_required([:instruction])
    |> validate_length(:instruction, min: 3)
  end
end

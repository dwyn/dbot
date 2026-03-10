defmodule Dbot.Email.Draft do
  use Ecto.Schema
  import Ecto.Changeset

  schema "drafts" do
    field :gmail_draft_id, :string
    field :body, :string
    field :model_used, :string
    field :is_snarky, :boolean, default: false
    field :status, :string, default: "created"

    belongs_to :email, Dbot.Email.Email

    timestamps()
  end

  def changeset(draft, attrs) do
    draft
    |> cast(attrs, [:email_id, :gmail_draft_id, :body, :model_used, :is_snarky, :status])
    |> validate_required([:email_id, :body])
  end
end

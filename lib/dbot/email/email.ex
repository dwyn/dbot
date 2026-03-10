defmodule Dbot.Email.Email do
  use Ecto.Schema
  import Ecto.Changeset

  schema "emails" do
    field :gmail_id, :string
    field :thread_id, :string
    field :from_address, :string
    field :from_name, :string
    field :subject, :string
    field :body_text, :string
    field :body_html, :string
    field :received_at, :utc_datetime
    field :status, :string, default: "pending"
    field :processed_at, :utc_datetime

    has_many :drafts, Dbot.Email.Draft

    timestamps()
  end

  def changeset(email, attrs) do
    email
    |> cast(attrs, [
      :gmail_id,
      :thread_id,
      :from_address,
      :from_name,
      :subject,
      :body_text,
      :body_html,
      :received_at,
      :status,
      :processed_at
    ])
    |> validate_required([:gmail_id, :from_address])
    |> unique_constraint(:gmail_id)
  end
end

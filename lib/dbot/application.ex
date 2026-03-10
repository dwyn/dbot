defmodule Dbot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        DbotWeb.Telemetry,
        Dbot.Repo,
        {DNSCluster, query: Application.get_env(:dbot, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: Dbot.PubSub},
        {Task.Supervisor, name: Dbot.TaskSupervisor}
      ] ++
        maybe_goth() ++
        [
          Dbot.Email.Poller,
          # Start to serve requests, typically the last entry
          DbotWeb.Endpoint
        ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Dbot.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp maybe_goth do
    credentials =
      case Application.get_env(:dbot, :google_credentials_json) do
        json when is_binary(json) and json != "" ->
          Jason.decode!(json)

        _ ->
          case Application.get_env(:dbot, :google_credentials_path) do
            nil -> nil
            path -> path |> File.read!() |> Jason.decode!()
          end
      end

    case credentials do
      nil -> []
      creds -> [{Goth, name: Dbot.Goth, source: {:refresh_token, creds, []}}]
    end
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DbotWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

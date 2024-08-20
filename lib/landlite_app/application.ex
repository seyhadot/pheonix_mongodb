defmodule LandliteApp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      LandliteAppWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:landlite_app, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: LandliteApp.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: LandliteApp.Finch},
      # Start a worker by calling: LandliteApp.Worker.start_link(arg)
      # {LandliteApp.Worker, arg},
      # Start to serve requests, typically the last entry
      LandliteAppWeb.Endpoint,
      LandliteApp.MongoDB

    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LandliteApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LandliteAppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

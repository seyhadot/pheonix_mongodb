defmodule LandliteApp.MongoDB do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    url = Application.get_env(:landlite_app, :mongodb)[:url]
    {:ok, conn} = Mongo.start_link(url: url)
    {:ok, %{conn: conn}}
  end

  def get_connection do
    GenServer.call(__MODULE__, :get_connection)
  end

  def handle_call(:get_connection, _from, state) do
    {:reply, state.conn, state}
  end
end

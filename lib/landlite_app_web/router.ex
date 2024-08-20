defmodule LandliteAppWeb.Router do
  use LandliteAppWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", LandliteAppWeb do
    pipe_through :api

    scope "/v1", API.V1, as: :v1 do
      resources "/users", UserController
      get "/messages/:user_id", MessageController, :index
      post "/messages", MessageController, :create
      get "/users/:id/conversations", UserController, :conversations
    end
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:landlite_app, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: LandliteAppWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end

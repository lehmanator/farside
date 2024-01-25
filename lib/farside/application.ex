defmodule Farside.Application do
  @moduledoc false

  use Application
  farside_port = Application.compile_env!(:farside, :port)
  data_dir = Application.compile_env!(:farside, :data_dir)

  @impl true
  def start(_type, _args) do
    IO.puts "Running on http://localhost:#{farside_port}"

    children = [
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: Farside.Router,
        options: [
          port: String.to_integer(farside_port)
        ]
      ),
      {PlugAttack.Storage.Ets, name: Farside.Throttle.Storage, clean_period: 60_000},
      {CubDB, [data_dir: data_dir, name: CubDB, auto_compact: true]},
      Farside.Scheduler,
      Farside.Server
    ]

    opts = [strategy: :one_for_one, name: Farside.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

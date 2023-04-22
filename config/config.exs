import Config

config :logger, level: :error

config :phoenix, :json_library, Jason
config :elixir, ansi_enabled: true

config :dragon, from: "."

use Mix.Config

config :postgrex_cache, :postgrex,
  [pool: DBConnection.Poolboy,
   pool_size: 5]

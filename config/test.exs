use Mix.Config

config :ironman,
  hex_repo: "https://hex.pm",
  http_client: Ironman.MockHttpClient,
  io: Ironman.MockIO

import Config

config :git_hooks,
  hooks: [
    pre_commit: [
      verbose: true,
      tasks: [
        {:cmd, "mix format --check-formatted"}
      ]
    ],
    pre_push: [
      verbose: true,
      tasks: [
        {:cmd, "mix clean"},
        {:cmd, "mix compile --warnings-as-errors"},
        {:cmd, "mix credo --strict"},
        {:cmd, "mix dialyzer --halt-exit-status"}
      ]
    ]
  ]

config :ironman, hex_repo: "https://hex.pm"

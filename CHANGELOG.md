# Changelog

## 0.4.6

- Add :inets
- Handle missing /config or /config/config.exs

## 0.4.5

- Update git hooks config to new syntax

## 0.4.4

- Better handling of comments in deps detection, install, and update
- Ask before running check_all_deps check
- Warn instead of crash when dep is not found on hex
- Remove earmark check (it is now a dependency of :ex_doc)

## 0.4.3

- Add check to update all outdated installed dependencies.
- Retry if `mix deps.get` times out (can happen if ElixirLS kicks it off before Ironman does)

## 0.4.2

- Enabled credo config check

## 0.4.1

- Reworked credo default config import.

## 0.4.0

- Ask at end if user wants to install any other dependencies
- Add pre-check for presence of mix.exs file
- Add pre-check for uncommitted files (to allow ironman changes to be in their own commit)
- Add timer sleep before deps.get to reduce collision with ElixirLS

## 0.3.3

- Add :coveralls config check

## 0.3.2

- Add :credo config check
- Use parent folder for app name if :app not defined in mix.exs (e.g. umbrella)
- Add app_name.plt.hash to .gitignore for :dialyzer_config
- Separate `:skip` and `:no` returns for checks

## 0.3.1

- Add mix clean prior to mix compile on git push hook to catch warnings.

## 0.3.0

- Add :git_hooks config check
- Improve test coverage
- Reworked config internal manipulation

## 0.2.0

- Change dependency checking to use regex
- Clear dialyzer ignores fixed in elixir 1.8.1
- Change format of IO questions
- Add :git_hooks check
- Add :dialyzer_config check
- Mox/Impl all File operations

## 0.1.2

- Add self version checking
- Refactor dependency version retrieval

## 0.1.0

- Initial release

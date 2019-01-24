# Ironman

`mix new` is like Tony Stark: Awesome and can do great things, but not bulletproof. When he suits up, however, his vulnerabilities are covered. Similarly, the Ironman project takes an elixir project (existing or newly created) and configures it in a way that protects it from getting in a bad state. It does this by adding dependencies for best practices such as `:credo` and `:dialyxir`, adding ci configuration for these tools, setting run configuration such as `warnings_as_errors`, etc...

Each step of suiting up is confirmed with the end user before changing, and can be rejected individually.

## Installation

Ironman is a mix archive that can be installed by running:

`mix archive.install hex ironman`

## Suiting Up

Ironman can be run from the root of any project by calling:

`mix suit_up`

## Contributing

Contributions welcome. Specifically looking to:

* Complete items in current progress below.

## Current Progress

### Add Dependencies

* [X] [`:ex_doc`](https://github.com/elixir-lang/ex_doc)
* [X] [`:earmark`](https://github.com/pragdave/earmark)
* [X] [`:dialyxir`](https://github.com/jeremyjh/dialyxir)
* [X] [`:mix_test_watch`](https://github.com/lpil/mix-test.watch)
* [X] [`:credo`](https://github.com/rrrene/credo)
* [X] [`:excoveralls`](https://github.com/parroty/excoveralls)
* [ ] [`:git_hooks`](https://github.com/qgadrian/elixir_git_hooks)

### Add Configuration

* [ ] [`:dialyxir`](https://github.com/jeremyjh/dialyxir)
* [ ] [`:credo`](https://github.com/rrrene/credo)
* [ ] [`:excoveralls`](https://github.com/parroty/excoveralls)
* [ ] [`:git_hooks`](https://github.com/qgadrian/elixir_git_hooks)

### Additional Features

* [ ] Self check/upgrade version
* [ ] Check all dependencies for updates
* [ ] Ask what additional dependencies to add

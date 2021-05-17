.PHONY: build-elixir-pony
build-elixir-pony:
	docker-compose build elixir-pony
	docker-compose run elixir-pony bash -c "mix deps.get"

### Local testing of elixir-pony (inside Docker)

.PHONY: elixir-pony
elixir-pony:
	docker-compose run elixir-pony bash -c "iex -S mix"

.PHONY: elixir-pony
test-elixir-pony:
	docker-compose run elixir-pony bash -c "mix test --trace --no-start"
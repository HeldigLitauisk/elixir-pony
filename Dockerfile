FROM elixir:1.12.0-rc.1
ENV MIX_ENV test

WORKDIR /app
COPY ./ .

RUN mix local.hex --force
RUN mix local.rebar --force

RUN mix deps.get && mix deps.compile
RUN mix compile
CMD bash

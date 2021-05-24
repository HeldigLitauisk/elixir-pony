defmodule Maze.Application do
  use Application

  def start(_type, _args) do
    maze_id = Maze.PonyApi.get_map_id()
#    maze_id = "aae9182b-6824-4f9a-8996-e307a49ad81a"
    IO.puts("Starting app #{inspect(maze_id)}")
    Maze.PonyApi.print_maze(maze_id)
    state = Maze.PonyApi.get_current_state(maze_id)
    pony_loc = Maze.Locator.locate_pony(state)
    domokun_loc = Maze.Locator.locate_domokun(state)
    finish_loc = Maze.Locator.locate_finish(state)

    children = [
        %{
          id: Maze.Population,
          start: {Maze.Population, :start_link, [state, pony_loc, domokun_loc, finish_loc]}, type: :worker
        },
        %{
          id: Maze.PonyController,
          start: {Maze.PonyController, :start_link, [maze_id, finish_loc]}, type: :worker
        }
    ]

      opts = [strategy: :one_for_one, name: __MODULE__]
      Supervisor.start_link(children, opts)
    end

end
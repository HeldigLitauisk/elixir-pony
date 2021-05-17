defmodule MazeTest do
  use ExUnit.Case

  test "common Pony API calls" do
#    maze_id = Maze.PonyApi.get_map_id()
    maze_id = "6682fa81-205a-408b-9fea-b29b580790ef"
    Maze.PonyApi.print_maze(maze_id)

    Maze.PonyApi.move_pony(maze_id, "west")
    Maze.PonyApi.move_pony(maze_id, "south")

    Maze.PonyApi.print_maze(maze_id)

    state = Maze.PonyApi.get_current_state(maze_id)
    Maze.Locator.get_valid_pony_directions(state)

    Maze.Locator.locate_pony(state)
    Maze.Locator.locate_domokun(state)
    loc = Maze.Locator.locate_finish(state)
    Maze.Locator.get_valid_directions_at(state, loc)
  end

  #TODO: add unit tests
end

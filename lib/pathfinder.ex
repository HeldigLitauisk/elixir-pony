#TODO: combine with Genetic algorithm fitness function

defmodule Maze.Pathfinder do

  def get_nearby_finish(state) do
    loc = Maze.Locator.locate_finish(state)
    Maze.Locator.get_valid_directions_at(state, loc)
    |> Enum.map(fn direction -> Maze.Locator.get_new_location(direction, loc) end)
  end

  def get_nearby(state, loc) do
    Maze.Locator.get_valid_directions_at(state, loc)
    |> Enum.map(fn direction -> Maze.Locator.get_new_location(direction, loc) end)
  end

  def recursive_search(_state, _locations, found_locations, depth) when depth == 0, do: found_locations
  def recursive_search(_state, locations, found_locations, _depth) when length(locations) == 0 do
    IO.puts("no more to search")
    found_locations
  end

  def recursive_search(state, locations, found_locations, depth) do
    new_locations = []
    Enum.map(locations, fn loc ->
      unless Enum.member?(found_locations, loc) do
        new_locations = get_nearby(state, loc)
        found_locations = found_locations ++ new_locations
        IO.puts("found loca #{inspect(found_locations)}")
      end
    end)
    IO.puts("found new loca #{inspect(new_locations)}")
    recursive_search(state, new_locations, found_locations, depth - 1)
  end

end
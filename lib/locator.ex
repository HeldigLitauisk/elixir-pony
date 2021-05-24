defmodule Maze.Locator do
  @height 25
  @width 25

  def locate_pony(%{"pony" => pony}), do: print_location(pony)
  def locate_domokun(%{"domokun" => domokun}), do: print_location(domokun)
  def locate_finish(%{"end-point" => finish}), do: print_location(finish)

  def get_valid_pony_directions(state) do
    loc = locate_pony(state)
    get_valid_directions_at(state, loc)
  end

  def get_valid_directions_at(state, location) do
    data = get_maze_data(state)
    north_west = Enum.at(data, location)
    south = check_south(data, location)
    east = check_east(data, location)

    [check_north(north_west), check_west(north_west), south, east]
    |> Enum.filter(& !is_nil(&1))
  end

  def get_new_location(direction, old_loc) do
    case direction do
      "west" -> resolve_west(old_loc)
      "east" -> resolve_east(old_loc)
      "south" -> resolve_south(old_loc)
      "north" -> resolve_north(old_loc)
    end
  end

  ## Private methods

  defp check_south(data, location) do
    unless location+@height > @height*@width-1 do
      map = Enum.at(data, location+@height)
      unless Enum.member?(map, "north"), do: "south"
    end
  end

  defp check_east(data, location) do
    unless rem(resolve_east(location), @width) == 0 do
      map = Enum.at(data, resolve_east(location))
      unless Enum.member?(map, "west"), do: "east"
    end
  end

  defp get_maze_data(%{"data" => data}), do: data

  defp print_location(item), do: Enum.at(item, 0)

  defp check_north(map) do
    unless Enum.member?(map, "north"), do: "north"
  end

  defp check_west(map) do
    unless Enum.member?(map, "west"), do: "west"
  end

  defp resolve_west(old_loc), do: old_loc-1
  defp resolve_east(old_loc), do: old_loc+1
  defp resolve_south(old_loc), do: old_loc+@height
  defp resolve_north(old_loc), do: old_loc-@height

end
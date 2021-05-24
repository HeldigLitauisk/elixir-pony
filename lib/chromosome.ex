defmodule Maze.Chromosome do
  @path_length 2000
  @nearby_domokun 100000
  @repetitive_move 10
  @nearby_finish 10000
  @mutation_prob 0.9

  use GenServer

  def start_link(maze_state, pony_loc, domokun_loc, finish_loc) do
    GenServer.start_link(__MODULE__, [maze_state, pony_loc, domokun_loc, finish_loc])
  end

  ## API

  def get_fitness_and_path() do
    GenServer.call(__MODULE__, {:get_fitness_and_path})
  end

  def mutate(path) do
    GenServer.cast(__MODULE__, {:mutate, path})
  end

  def elites(path) do
    GenServer.cast(__MODULE__, {:elites, path})
  end

  def init([maze_state, pony_loc, domokun_loc, finish_loc]) do
    state = %{maze: maze_state, pony_loc: pony_loc, domokun_loc: domokun_loc, finish_loc: finish_loc, fitness: 0, path: [], last_loc: pony_loc}
    {:ok, state, {:continue, :gen_path}}
  end

  def handle_continue(:gen_path, state = %{maze: maze, pony_loc: loc, path: path, domokun_loc: domokun_loc, finish_loc: finish_loc, last_loc: last_loc}) do
    new_path = generate_path(maze, loc, path, Enum.count(path))
    fitness = calc_fitness(new_path, domokun_loc, finish_loc, maze, last_loc)
    {:noreply, %{state | path: new_path, fitness: fitness}}
  end

  def handle_call({:get_fitness_and_path}, _from, state = %{fitness: fitness, path: path}) do
    {:reply, {fitness, path}, state}
  end

  def handle_cast({:elites, path}, state = %{maze: maze, domokun_loc: domokun_loc, finish_loc: finish_loc, last_loc: last_loc}) do
    {head, _tail} = Enum.split(path, 1)
    {_dir, loc} = Enum.at(head, -1)
    new_path = generate_path(maze, loc, head, length(head))
    fitness = calc_fitness(new_path, domokun_loc, finish_loc, maze, last_loc)
    {:noreply, %{state | path: new_path, fitness: fitness, last_loc: loc}}
  end

  def handle_cast({:mutate, path}, state = %{maze: maze, domokun_loc: domokun_loc, finish_loc: finish_loc, last_loc: last_loc}) do
    {head, _tail} =
      if :rand.uniform(1) < @mutation_prob do
        Enum.split(path, Enum.random(1..length(path)-trunc(0.5*length(path))))
    else
        Enum.split(path, 1)
    end

    {_dir, loc} = Enum.at(head, -1)
    new_path = generate_path(maze, loc, head, length(head))
    fitness = calc_fitness(new_path, domokun_loc, finish_loc, maze, last_loc)
    {:noreply, %{state | path: new_path, fitness: fitness, last_loc: loc}}
  end

  def handle_cast({:mutate, _path}, state) do
    IO.puts("Mutation didn't match #{inspect(state)}")
    {:noreply, state}
  end

  def handle_cast({:refresh_chromosome, maze_state, new_loc, _domokun_loc}, state = %{last_loc: last_loc}) do
    new_path = generate_path(maze_state, new_loc, [], 0)
    domokun_loc = Maze.Locator.locate_domokun(maze_state)
    fitness = calc_fitness(new_path, domokun_loc, Maze.Locator.locate_finish(maze_state), maze_state, last_loc)
    {:noreply, %{state | maze: maze_state, pony_loc: new_loc, domokun_loc: domokun_loc, fitness: fitness, path: new_path}}
  end

  def generate_path(maze_state, pony_loc, path, path_length) when path_length == 0 do
    direction =
      Maze.Locator.get_valid_directions_at(maze_state, pony_loc)
      |> Enum.random

    new_loc = Maze.Locator.get_new_location(direction, pony_loc)
    new_path = path ++ [{direction, new_loc}]
    generate_path(maze_state, new_loc, new_path, Enum.count(new_path))
  end

  def generate_path(maze_state, pony_loc, path, path_length) when path_length < @path_length do
    directions = Maze.Locator.get_valid_directions_at(maze_state, pony_loc)
    {dir, _loc} = Enum.at(path, -1)
    direction =
      case length(directions) > 1 do
        true ->
          List.delete(directions, opposite_direction(dir))
          |> Enum.random
        false ->
          Enum.at(directions, 0)
      end

    new_loc = Maze.Locator.get_new_location(direction, pony_loc)
    new_path = path ++ [{direction, new_loc}]
    generate_path(maze_state, new_loc, new_path, Enum.count(new_path))
  end

  def generate_path(_maze_state, _pony_loc, path, _path_length), do: path

  def opposite_direction("south"), do: "north"
  def opposite_direction("north"), do: "south"
  def opposite_direction("east"), do: "west"
  def opposite_direction("west"), do: "east"

  ## Private methods

  defp punish_nearby_domokun(path, domokun_loc, maze) do
    {_dir, loc} = Enum.at(path, -1)
    if loc == domokun_loc, do: @nearby_domokun, else: is_nearby_domokun(loc, get_nearby(maze, domokun_loc))
  end

  defp return_duplicates(list) do
    list
    |> Enum.group_by(&(&1))
    |> Enum.filter(fn {_, [_,_|_]} -> true; _ -> false end)
    |> Enum.map(fn {x, _} -> x end)
  end

  defp punish_repetitive_moves(path, finish_loc, maze) do
    finish_locations = get_nearby(maze, finish_loc)
    locations = Enum.map(path, fn {_dir, loc} -> loc end)
    dupl = return_duplicates(locations)
    Enum.reduce_while(locations, 0, fn x, acc ->
      unless Enum.member?(finish_locations, x) do
        case Enum.member?(dupl, x) do
          true -> {:cont, acc - @repetitive_move}
          false -> {:cont, acc}
        end
      else
        {:halt, acc}
      end
    end)
  end

  defp reward_finish(path, finish_loc, maze) do
    finish_locations = get_nearby(maze, finish_loc)
    Enum.reduce_while(path, 0, fn {_dir, loc}, acc ->
      unless Enum.member?(finish_locations, loc) do
        {:cont, acc}
      else
        {:halt, acc + @nearby_finish}
      end
    end)
  end

  defp punish_repeat_last(path, last_loc) do
    {_dir, loc} = Enum.at(path, -1)
    case loc == last_loc do
      true -> @nearby_finish
      false -> 0
    end
  end

  defp calc_fitness(path, domokun_loc, finish_loc, maze, last_loc) do
    punish_repetitive_moves(path, finish_loc, maze) + reward_finish(path, finish_loc, maze) - punish_nearby_domokun(path, domokun_loc, maze) - punish_repeat_last(path, last_loc)
  end

  defp get_nearby(state, loc) do
    Maze.Locator.get_valid_directions_at(state, loc)
    |> Enum.map(fn direction -> Maze.Locator.get_new_location(direction, loc) end)
  end

  defp is_nearby_domokun(loc, locations) do
    case Enum.member?(locations, loc) do
      true -> @nearby_domokun
      false -> 0
    end
  end

end
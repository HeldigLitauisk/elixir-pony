defmodule Maze.Chromosome do
  @path_length 1000
  @nearby_domokun -5
  @nearby_finish 10

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

  def handle_cast({:mutate, path}, state = %{maze: maze, domokun_loc: domokun_loc, finish_loc: finish_loc, last_loc: last_loc}) do
    {head, _tail} = Enum.split(path, Enum.random(1..length(path)-10))
    {_dir, loc} = Enum.at(head, -1)
    new_path = generate_path(maze, loc, head, length(head))
    fitness = calc_fitness(new_path, domokun_loc, finish_loc, maze, last_loc)
    {:noreply, %{state | path: new_path, fitness: fitness, last_loc: loc}}
  end

  def handle_cast({:mutate, _path}, state) do
    IO.puts("Mutation didn't match #{inspect(state)}")
    {:noreply, state}
  end

  def handle_cast({:refresh_chromosome, maze_state, new_loc, domokun_loc}, state = %{last_loc: last_loc}) do
    new_path = generate_path(maze_state, new_loc, [], 0)
    fitness = calc_fitness(new_path, domokun_loc, Maze.Locator.locate_finish(maze_state), maze_state, last_loc)
    {:noreply, %{state | maze: maze_state, pony_loc: new_loc, domokun_loc: domokun_loc, fitness: fitness, path: new_path}}
  end

  def generate_path(maze_state, pony_loc, path, path_length) when path_length < @path_length do
    direction =
      Maze.Locator.get_valid_directions_at(maze_state, pony_loc)
      |> Enum.random

    new_loc = Maze.Locator.get_new_location(direction, pony_loc)
    new_path = path ++ [{direction, new_loc}]
    generate_path(maze_state, new_loc, new_path, Enum.count(new_path))
  end

  def generate_path(_maze_state, _pony_loc, path, _path_length), do: path

  ## Private methods
  defp calc_fitness(path, domokun_loc, finish_loc, maze, last_loc) do
    {_dir, loc} = Enum.at(path, -1)
    case last_loc == loc do
      true -> Enum.reduce(path, 0, fn loc, acc -> sum_fitness(loc, domokun_loc, finish_loc, maze) + acc end) + length(Enum.uniq(path)) -1000
      false ->
        Enum.reduce(path, 0, fn loc, acc -> sum_fitness(loc, domokun_loc, finish_loc, maze) + acc end) + length(Enum.uniq(path))
    end
  end

  defp sum_fitness({_direction, loc}, _domokun_loc, finish_loc, maze) do
#    domokun_nearby = get_nearby(maze, domokun_loc)
    finish_nearby = get_nearby(maze, finish_loc)
    is_nearby_finish(loc, finish_nearby) #+ is_nearby_domokun(loc, domokun_nearby)
  end

  defp get_nearby(state, loc) do
    Maze.Locator.get_valid_directions_at(state, loc)
    |> Enum.map(fn direction -> Maze.Locator.get_new_location(direction, loc) end)
  end

  defp is_nearby_finish(loc, locations) do
    case Enum.member?(locations, loc) do
      true -> @nearby_finish
      false -> 0
    end
  end

  defp is_nearby_domokun(loc, locations) do
    case Enum.member?(locations, loc) do
      true -> @nearby_domokun
      false -> 0
    end
  end

end
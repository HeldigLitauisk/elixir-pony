defmodule Maze.Population do
  @population_size 200
  @generation_count 25
  @interval 1_000

  use GenServer

  def start_link(maze_state, pony_loc, domokun_loc, finish_loc) do
    GenServer.start_link(__MODULE__, [maze_state, pony_loc, domokun_loc, finish_loc], name: __MODULE__)
  end

  ## API

  def get_fittest() do
    GenServer.call(__MODULE__, {:get_fittest})
  end

  def refresh_population(maze_state) do
    GenServer.cast(__MODULE__, {:refresh_population, maze_state})
  end

  def init([maze_state, pony_loc, domokun_loc, finish_loc]) do
    state = %{maze: maze_state, pony_loc: pony_loc, domokun_loc: domokun_loc, finish_loc: finish_loc, gen_count: @generation_count, fittest: {0, "west"}}
    {:ok, state, {:continue, :spawn_offsprings}}
  end

  def handle_continue(:spawn_offsprings, state = %{maze: maze, pony_loc: loc, domokun_loc: domokun_loc, finish_loc: finish_loc}) do
    IO.puts("reached spawn_offsprings")
    Task.async_stream(0..@population_size, fn id -> init_chromosome(maze, loc, domokun_loc, finish_loc, id) end, timeout: 5_000)
      |> Enum.each(&({:ok, _pid} = &1))
    IO.puts("1st generation created")
    Process.send_after(self(), :next_generation, @interval)
    {:noreply, state}
  end

  def handle_call({:get_fittest}, _from, state = %{fittest: {best, direction}}) do
    {:reply, {best, direction}, state}
  end

  def handle_cast({:refresh_population, maze_state}, state) do
    IO.puts("refresh_population")
    pony = Maze.Locator.locate_pony(maze_state)
    domokun = Maze.Locator.locate_domokun(maze_state)

    Enum.map(0..@population_size, fn id ->
      GenServer.cast(get_atom_name(id), {:refresh_chromosome, maze_state, pony, domokun})
    end)
    {:noreply, %{state | gen_count: @generation_count, maze: maze_state, pony_loc: pony, domokun_loc: domokun}}
  end

  def handle_info(:next_generation, state = %{gen_count: gen_count}) when gen_count > 0 do
    fit = get_all_fitnesses()
          |> get_top_ten()
          |> apply_mutations()
    {best, path} = Enum.at(fit, 0)
    direction = Enum.at(path, 0)
    IO.puts("Best: #{inspect(best)}, direction #{inspect(direction)}")
    Process.send_after(self(), :next_generation, @interval)
    {:noreply, %{state | gen_count: gen_count - 1, fittest: {best, direction}}}
  end

  def handle_info(:next_generation, state) do
    IO.puts("All generations finished")
    {:noreply, state}
  end

  defp init_chromosome(maze, loc, domokun_loc, finish_loc, id) do
    case GenServer.start_link(Maze.Chromosome, [maze, loc, domokun_loc, finish_loc], name: get_atom_name(id)) do
      {:error, err} ->
        IO.puts("Could not start chromosome #{inspect(err)}")
        {:ok, err}
      {:ok, pid} -> {:ok, pid}
    end
  end

  defp apply_mutations(top_ten) do
    IO.puts("Applying mutations")
    Enum.map(0..@population_size, fn id ->
      {_fit, rand_path} = Enum.random(top_ten)
      GenServer.cast(get_atom_name(id), {:mutate, rand_path})
    end)
    top_ten
  end

  defp get_top_ten(fitnesses) do
    Enum.sort(fitnesses)
    |> Enum.take(-10)
  end

  defp get_all_fitnesses() do
    Enum.map(0..@population_size, fn id -> GenServer.call(get_atom_name(id), {:get_fitness_and_path}) end)
  end

  defp get_atom_name(id), do: String.to_atom("generation_1_chromosome_#{inspect(id)}")

#  def handle_call({:get_fitness_and_path}, _from, state = %{fitness: fitness, path: path}) do
#    {:reply, {fitness, path}, state}
#  end
#
#  def handle_call({:recalculate_path, _path}, _from, state) do
#    {:reply, :ok, state}
#  end




end
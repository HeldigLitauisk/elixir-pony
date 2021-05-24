defmodule Maze.PonyController do
  use GenServer

  @interval 3_000

  def start_link(maze_id, finish_loc) do
    GenServer.start_link(__MODULE__, [maze_id, finish_loc], name: __MODULE__)
  end

  ## API

  def move_pony() do
    GenServer.call(__MODULE__, {:move_pony})
  end

  def init([maze_id, finish_loc]) do
    {:ok, %{maze_id: maze_id, finish_loc: finish_loc}, {:continue, :auto_movement}}
  end

  def handle_continue(:auto_movement, state) do
    IO.puts("reached auto_movement")
    Process.send_after(self(), :next_move, @interval)
    {:noreply, state}
  end

  def handle_call({:move_pony}, _from, _state = %{maze_id: maze_id, finish_loc: finish_loc}) do
    {:reply, :ok, move_and_refresh(maze_id, finish_loc)}
  end

  def handle_info(:next_move, state = %{automove: false}) do
    {:noreply, state}
  end

  def handle_info(:next_move, %{maze_id: maze_id, finish_loc: finish_loc}) do
    state = move_and_refresh(maze_id, finish_loc)
    Process.send_after(self(), :next_move, @interval)
    {:noreply, state}
  end

  defp move_and_refresh(maze_id, finish_loc) do
    {_best, {direction, loc}} = Maze.Population.get_fittest()

    Maze.PonyApi.move_pony(maze_id, direction)
    Maze.PonyApi.print_maze(maze_id)
    maze_state = Maze.PonyApi.get_current_state(maze_id)

    case finish_loc == loc do
      true ->
        IO.puts("Finish reached succesfully!!!!")
        %{maze_id: maze_id, finish_loc: finish_loc, automove: false}
      false ->
        Maze.Population.refresh_population(maze_state)
        %{maze_id: maze_id, finish_loc: finish_loc, automove: true}
    end
  end
end
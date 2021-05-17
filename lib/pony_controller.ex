defmodule Maze.PonyController do
  use GenServer

  @interval 5_000

  def start_link(maze_id) do
    GenServer.start_link(__MODULE__, [maze_id], name: __MODULE__)
  end

  ## API

  def move_pony() do
    GenServer.call(__MODULE__, {:move_pony})
  end

  def init([maze_id]) do
    {:ok, %{maze_id: maze_id}, {:continue, :auto_movement}}
  end

  def handle_continue(:auto_movement, state) do
    IO.puts("reached auto_movement")
    Process.send_after(self(), :next_move, @interval)
    {:noreply, state}
  end

  def handle_call({:move_pony}, _from, state = %{maze_id: maze_id}) do
    move_and_refresh(maze_id)
    {:reply, :ok, state}
  end

  def handle_info(:next_move, state = %{maze_id: maze_id}) do
    move_and_refresh(maze_id)
    Process.send_after(self(), :next_move, @interval)
    {:noreply, state}
  end

  defp move_and_refresh(maze_id) do
    {_best, {direction, _id}} = Maze.Population.get_fittest()
    Maze.PonyApi.move_pony(maze_id, direction)
    Maze.PonyApi.print_maze(maze_id)
    maze_state = Maze.PonyApi.get_current_state(maze_id)
    Maze.Population.refresh_population(maze_state)
  end

end
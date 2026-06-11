defmodule MusicLearningPlatform.State.StateModelTest do
  use ExUnit.Case, async: false

  alias MusicLearningPlatform.State.{StateModel, PlaybackState}

  setup do
    PlaybackState.init_table()
    session_id = "test-session-#{System.unique_integer()}"

    on_exit(fn -> StateModel.delete_state(session_id) end)

    {:ok, session_id: session_id}
  end

  defp create_session(session_id) do
    PlaybackState.create_session(session_id, 1, 1, [])
  end

  describe "put_state/1 and get_state/1" do
    test "stores and retrieves state", %{session_id: session_id} do
      create_session(session_id)
      assert {:ok, state} = StateModel.get_state(session_id)
      assert state.session_id == session_id
    end

    test "returns error for unknown session", %{session_id: _} do
      assert {:error, :not_found} = StateModel.get_state("nonexistent")
    end
  end

  describe "set_playing/2" do
    test "updates is_playing", %{session_id: session_id} do
      create_session(session_id)
      {:ok, state} = StateModel.set_playing(session_id, true)
      assert state.is_playing
    end
  end

  describe "set_position/2" do
    test "updates current_time", %{session_id: session_id} do
      create_session(session_id)
      {:ok, state} = StateModel.set_position(session_id, 12.5)
      assert_in_delta state.current_time, 12.5, 0.001
    end
  end

  describe "reset_position/1" do
    test "resets time to 0 and stops playback", %{session_id: session_id} do
      create_session(session_id)
      StateModel.set_playing(session_id, true)
      StateModel.set_position(session_id, 5.0)

      {:ok, state} = StateModel.reset_position(session_id)
      assert state.current_time == 0.0
      refute state.is_playing
    end
  end

  describe "set_speed/2" do
    test "updates speed", %{session_id: session_id} do
      create_session(session_id)
      {:ok, state} = StateModel.set_speed(session_id, 1.5)
      assert_in_delta state.speed, 1.5, 0.001
    end
  end

  describe "delete_state/1" do
    test "removes state from ETS", %{session_id: session_id} do
      create_session(session_id)
      StateModel.delete_state(session_id)
      assert {:error, :not_found} = StateModel.get_state(session_id)
    end
  end
end

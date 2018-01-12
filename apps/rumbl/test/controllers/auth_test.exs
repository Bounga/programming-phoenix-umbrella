defmodule Rumbl.AuthTest do
  use Rumbl.ConnCase

  alias Rumbl.Auth

  setup %{conn: conn} do
    conn =
      conn
      |> bypass_through(Rumbl.Router, :browser)
      |> get("/")

    {:ok, %{conn: conn}}
  end

  test "authenticate_user halts when no current_user available", %{conn: conn} do
    conn = Auth.authenticate_user(conn, [])

    assert conn.halted
  end

  test "authenticate_user continue when current_user available", %{conn: conn} do
    conn =
      conn
      |> assign(:current_user, %Rumbl.User{})
      |> Auth.authenticate_user([])

    refute conn.halted
  end

  test "login add user into the session", %{conn: conn} do
    login_conn =
      conn
      |> Auth.login(%Rumbl.User{id: 123})
      |> send_resp(:ok, "")

    next_conn = get(login_conn, "/")
    assert get_session(next_conn, :user_id) == 123
  end

  test "logout remove user from the session", %{conn: conn} do
    logout_conn =
      conn
      |> put_session(:user_id, 123)
      |> Auth.logout()
      |> send_resp(:ok, "")

    next_conn = get(logout_conn, "/")
    refute get_session(next_conn, :user_id)
  end

  test "login with valid username and password", %{conn: conn} do
    user = insert_user(username: "foo", password: "secret")
    {:ok, conn} =
      Auth.login_by_username_and_pass(conn, user.username, user.password, repo: Repo)

    assert conn.assigns.current_user.id == user.id
  end

  test "login with invalid username", %{conn: conn} do
    assert {:error, :not_found, _conn} =
      Auth.login_by_username_and_pass(conn, "me", "pass", repo: Repo)
  end

  test "login with invalid password", %{conn: conn} do
    user = insert_user(username: "foo", password: "secret")

    assert {:error, :unauthorized, _conn} =
      Auth.login_by_username_and_pass(conn, user.username, "wrong", repo: Repo)

  end

  test "call use user into session to set assign", %{conn: conn} do
    user = insert_user()
    conn =
      conn
      |> put_session(:user_id, user.id)
      |> Auth.call(Repo)

    assert conn.assigns.current_user.id == user.id
  end

  test "call with no user in session set assign to nil", %{conn: conn} do
    conn = Auth.call(conn, Repo)

    assert conn.assigns.current_user == nil
  end
end

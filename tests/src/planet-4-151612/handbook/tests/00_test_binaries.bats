#!/usr/bin/env bats
set -e

load env

@test "wget" {
  run run_docker_binary "$image" wget --version
  [ $status -eq 0 ]
}

@test "dockerize" {
  run run_docker_binary "$image" dockerize --version
  [ $status -eq 0 ]
}

@test "mysql" {
  run run_docker_binary "$image" mysql --version
  [ $status -eq 0 ]
}

@test "rsync" {
  run run_docker_binary "$image" rsync --version
  [ $status -eq 0 ]
}

@test "wp-cli" {
  run run_docker_binary "$image" wp --version
  [ $status -eq 0 ]
}

@test "composer" {
  run run_docker_binary "$image" composer --no-ansi --version
  [ $status -eq 0 ]
}

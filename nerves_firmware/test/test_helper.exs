ExUnit.start()

for file <- Path.wildcard(Path.join(__DIR__, "support/**/*.exs")) do
  Code.require_file(file)
end

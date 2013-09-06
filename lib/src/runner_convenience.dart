
part of cli;

var _runner = new Runner();

/// Convenience for [Runner.start].
Future<Process> start(
    Command command,
    {Environment environment: const Environment()}) =>
        _runner.start(
            command,
            environment: environment);

/// Convenience for [Runner.run].
Future<ProcessResult> run(
    Command command,
    {Environment environment: const Environment(),
      Encoding stdoutEncoding: SYSTEM_ENCODING,
      Encoding stderrEncoding: SYSTEM_ENCODING}) =>
          _runner.run(
              command,
              environment: environment,
              stdoutEncoding: stdoutEncoding,
              stderrEncoding: stderrEncoding);

/// Convenience for [Runner.runSync].
ProcessResult runSync(
    Command command,
    {Environment environment: const Environment(),
      Encoding stdoutEncoding: SYSTEM_ENCODING,
      Encoding stderrEncoding: SYSTEM_ENCODING}) =>
          _runner.runSync(
              command,
              environment: environment,
              stdoutEncoding: stdoutEncoding,
              stderrEncoding: stderrEncoding);

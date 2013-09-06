
part of cli;

/// Runs [Command]s in [Environment]s.
class Runner {

  /// Forwards [command] and [environment] fields to [Process.start].
  Future<Process> start(
      Command command,
      {Environment environment: const Environment()}) => Process.start(
      command.executable,
      command.arguments,
      workingDirectory: environment.workingDirectory,
      environment: environment.customVariables,
      includeParentEnvironment: environment.includeParentVariables,
      runInShell: environment.runInShell);

  /// Forwards [command] and [environment] fields to [Process.run].
  Future<ProcessResult> run(
      Command command,
      {Environment environment: const Environment(),
       Encoding stdoutEncoding: SYSTEM_ENCODING,
       Encoding stderrEncoding: SYSTEM_ENCODING}) => Process.run(
      command.executable,
      command.arguments,
      workingDirectory: environment.workingDirectory,
      environment: environment.customVariables,
      includeParentEnvironment: environment.includeParentVariables,
      runInShell: environment.runInShell,
      stdoutEncoding: stdoutEncoding,
      stderrEncoding: stderrEncoding);

  /// Forwards [command] and [environment] fields to [Process.runSync].
  ProcessResult runSync(
      Command command,
      {Environment environment: const Environment(),
       Encoding stdoutEncoding: SYSTEM_ENCODING,
       Encoding stderrEncoding: SYSTEM_ENCODING}) => Process.runSync(
      command.executable,
      command.arguments,
      workingDirectory: environment.workingDirectory,
      environment: environment.customVariables,
      includeParentEnvironment: environment.includeParentVariables,
      runInShell: environment.runInShell,
      stdoutEncoding: stdoutEncoding,
      stderrEncoding: stderrEncoding);
}

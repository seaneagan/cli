
part of cli;

/// An environment in which a command can be run.
///
/// For field descriptions, see corresponding parameters in
/// [Process.start], [Process.run], and [Process.runSync].
class Environment {

  final String workingDirectory;
  final bool includeParentVariables;
  final bool runInShell;

  Map<String, String> get variables {
    var vars = <String, String> {};
    if(this.includeParentVariables) {
      vars = Platform.environment;
    }
    if(customVariables != null) {
      vars.addAll(customVariables);
    }
    return vars;
  }
  final Map<String, String> customVariables;

  const Environment(
      {this.workingDirectory,
       Map<String, String> environment,
       this.includeParentVariables: true,
       this.runInShell: false})
      : this.customVariables = environment;
}

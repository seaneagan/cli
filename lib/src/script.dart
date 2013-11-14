
part of cli;

/// A base class for script argument annotations.
class _Arg {
  final String help;
  final String abbr;

  const _Arg({this.help, this.abbr});
}

/// An annotation to use on named method parameters,
/// marking them as command line options.
///
/// See the corresponding method parameters to [ArgParser.addOption]
/// for descriptions of the fields.
class Option extends _Arg {
  final List<String> allowed;
  final Map<dynamic, String> allowedHelp;
  final bool allowMultiple;
  final bool hide;

  const Option({
      String help,
      String abbr,
      this.allowed,
      this.allowedHelp,
      this.allowMultiple,
      this.hide})
      : super(help: help, abbr: abbr);
}

/// An annotation to use on named method parameters,
/// marking them as command line flags.
///
/// See the corresponding method parameters to [ArgParser.addFlag]
/// for descriptions of the fields.
class Flag extends _Arg {
  final bool negatable;

  const Flag({
      String help,
      String abbr,
      this.negatable})
      : super(help: help, abbr: abbr);
}

/// An annotation which marks the last positional parameter of a method
/// as a rest argument.  If the parameter has a type annotation,
/// it should be `List` or `List<String>`.
// TODO: If dart ever gets real rest parameters, remove this.
class Rest {
  const Rest();
}

/// An annotation which marks a method as corresponding to a sub-command.
class SubCommand {
  const SubCommand();
}


abstract class Script {

  /// A simple description of what this script does, for use in help text.
  final String description;

  /// The parser associated with this script.
  ArgParser get parser {
    if(_parser == null) {
      _parser = _getParser();
    }
    return _parser;
  }
  ArgParser _parser;
  ArgParser _getParser();

  Script._({this.description});

  /// Executes this script.
  ///
  /// * Parses the [arguments].
  /// * On success passes the [ArgResults] to [handleResults].
  /// * On failure, outputs the error and help information.
  execute(List<String> arguments) {

    ArgResults results;
    try {
      results = parser.parse(arguments);
    } catch(e) {
      print('$e\n');
      printUsage();
      exitCode = 1;
      return;
    }
    handleResults(results);
  }

  /// Handles successfully parsed [results].
  handleResults(ArgResults results);

  /// Prints usage information for this script.
  // TODO: Integrate with Loggers.
  printUsage() {
    print(_getFullUsage(parser, description: description));
  }

}

/// A [Script] whose interface and behavior is defined by a [Function].
///
/// The function's parameters must be marked with a [bool] type annotation or a
/// [Flag] metadata annotation to mark them as a flag, or with a [String] or
/// [dynamic] type annotation or [Option] metadata annotation to mark them as an
/// option.
///
/// When [execute]d, the command line arguments are injected into their
/// corresponding function arguments.
class SimpleScript extends Script {

  final Function _function;

  MethodMirror get _methodMirror =>
      (reflect(_function) as ClosureMirror).function;

  ArgParser _getParser() => _getParserFromFunction(_methodMirror);

  SimpleScript(this._function, {String description})
      : super._(description: description);

  handleResults(ArgResults results) {
    var positionalParameterInfo = _getPositionalParameterInfo(_methodMirror);
    var restParameterIndex = positionalParameterInfo[1] ?
        positionalParameterInfo[0] :
        null;
    var invocation = new ArgResultsToInvocationConverter(
        restParameterIndex).convert(results);
    Function.apply(
        _function,
        invocation.positionalArguments,
        invocation.namedArguments);
  }
}

/// A [Script] whose interface and behavior is defined by a class.
///
/// The class must have an unnamed constructor, and it's parameters define the
/// top-level options for this script.
/// Methods of the class can be annotated as [SubCommand]s.  The parameters of
/// these methods define the sub-command's arguments.
///
/// When [execute]d, the base command line arguments (before the command)
/// are injected into the their corresponding constructor arguments, to create
/// an instance of the class.  Then, the method corresponding to the
/// sub-command that was specified on the command line is invoked on the
/// instance.
///
/// If no sub-command was specified, then [onNoSubCommand] is invoked.
class CommandScript extends Script {

  Type _class;

  ArgParser _getParser() => _getParserFromClass(_class);

  CommandScript(this._class, {String description})
      : super._(description: description);

  /// Forward the arguments to
  handleResults(ArgResults results) {
    var classMirror = reflectClass(_class);

    // Handle constructor.
    var constructorInvocation = new ArgResultsToInvocationConverter(
        _getRestParameterIndex(_getUnnamedConstructor(classMirror))).convert(results);
    var instanceMirror = classMirror.newInstance(
        const Symbol(''),
        constructorInvocation.positionalArguments,
        constructorInvocation.namedArguments);

    // Handle command.
    var commandResults = results.command;
    if(commandResults == null) {
      onNoSubCommand(results);
      return;
    }
    var commandName = commandResults.name;
    var commandSymbol = new Symbol(separatorsToCamelCase.encode(commandName));
    var commandMethod = classMirror.declarations[commandSymbol] as MethodMirror;
    var commandConverter = new ArgResultsToInvocationConverter(
        _getRestParameterIndex(commandMethod), memberName: commandSymbol);
    var commandInvocation = commandConverter.convert(commandResults);
    instanceMirror.delegate(commandInvocation);
  }

  /// Called if no sub-command was provided.
  ///
  /// The default implementation treats this as an error, and calls
  /// [printUsage].
  onNoSubCommand(ArgResults results) {
    print('A sub-command must be specified.\n');
    printUsage();
  }

}

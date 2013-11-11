
part of cli;

/// A script argument.
class Arg {
  final String help;
  final String abbr;

  const Arg({this.help, this.abbr});
}

/// A script option.
class Option extends Arg {
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

/// A script flag.
class Flag extends Arg {
  final bool negatable;

  const Flag({
      String help,
      String abbr,
      this.negatable})
      : super(help: help, abbr: abbr);
}

/// An annotation to use on the last positional parameter of a Function passed
/// to [Script] to mark it as a rest argument.  If the parameter has a type
/// annotation, it should be `List` or `List<String>`.
class Rest {
  const Rest();
}

/// A script command.
class ScriptCommand {
  const ScriptCommand();
}

abstract class Script {

  final String description;

  ArgParser get parser {
    if(_parser == null) {
      _parser = _getParser();
    }
    return _parser;
  }
  ArgParser _parser;
  ArgParser _getParser();

  factory Script(Function function) = _BasicScript;
  factory Script.withCommands(Type type) = _CommandScript;

  Script._({this.description});

  execute(List<String> arguments) {

    ArgResults results;
    try {
      results = parser.parse(arguments);
    } catch(e) {
      print(_getFullUsage(parser, description: description));
      print(e);
      exitCode = 1;
      return;
    }
    _actuallyExecute(results);
  }

  _actuallyExecute(ArgResults results);
}

class _BasicScript extends Script {

  final Function _function;

  MethodMirror get _methodMirror =>
      (reflect(_function) as ClosureMirror).function;

  ArgParser _getParser() => _getParserFromFunction(_methodMirror);

  _BasicScript(this._function, {String description})
      : super._(description: description);

  _actuallyExecute(ArgResults results) {
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

class _CommandScript extends Script {

  Type _class;

  ArgParser _getParser() => _getParserFromClass(_class);

  _CommandScript(this._class, {String description})
      : super._(description: description);

  _actuallyExecute(ArgResults results) {
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
    if(commandResults == null) return;
    var commandName = commandResults.name;
    var commandSymbol = new Symbol(commandName);
    var commandMethod = classMirror.declarations[commandSymbol] as MethodMirror;
    var commandConverter = new ArgResultsToInvocationConverter(
        _getRestParameterIndex(commandMethod), memberName: commandSymbol);
    var commandInvocation = commandConverter.convert(commandResults);
    instanceMirror.delegate(commandInvocation);
  }
}

// Returns a List whose elements are the required argument count, and whether
// there is a Rest parameter.
List _getPositionalParameterInfo(MethodMirror methodMirror) {
  var positionals = methodMirror.parameters.where((parameter) =>
      !parameter.isNamed);

  // TODO: Support optional positionals.
  if(positionals.any((positional) => positional.isOptional)) {
    throw new UnimplementedError('Cannot use optional positional parameters.');
  }
  var requiredPositionals =
      positionals.where((parameter) => !parameter.isOptional);

  var isRest = false;
  if(requiredPositionals.isNotEmpty) {

    var lastFuncPositional = requiredPositionals.last;

    var isRestAnnotated = lastFuncPositional.metadata
        .map((annotation) => annotation.reflectee)
        .any((metadata) => metadata is Rest);
    // TODO: How to check if the type is List or List<String> ?
    // var isList = lastFuncPositional.type == reflectClass(List);
    isRest = isRestAnnotated;// || isList;
  }

  return [requiredPositionals.length - (isRest ? 1 : 0), isRest];
}

_getRestParameterIndex(MethodMirror methodMirror) {
  var positionalParameterInfo = _getPositionalParameterInfo(methodMirror);
  return positionalParameterInfo[1] ?
      positionalParameterInfo[0] :
        null;
}

MethodMirror _getUnnamedConstructor(ClassMirror classMirror) {
  var constructors = classMirror.declarations.values
  .where((d) => d is MethodMirror && d.isConstructor);

  return constructors.firstWhere((constructor) =>
      constructor.constructorName == const Symbol(''), orElse: () => null);
}

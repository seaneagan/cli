
part of cli;

/// Returns full usage text for the current dart script,
/// including a [description].
String _getFullUsage(ArgParser parser, {String description}) {

  if(description == null) description = '';

  if(description.isNotEmpty) {
    description = '''$description
''';
  }

  var scriptName = basename(Platform.script.path);
  var usesShebang = extension(scriptName).isNotEmpty;
  var executable = usesShebang ? '' : 'dart ';
  var options = parser.options.isEmpty ? '' : ''' [options]

Options:

${parser.getUsage()}''';

  return '''

$description
Usage:

    $executable$scriptName$options''';
}

/// Adds a standard help option to [parser].
void _addHelp(ArgParser parser) {
  parser.addFlag(
      'help',
      help: 'Print this usage information.', negatable: false);
}

ArgParser _getParserFromFunction(
    MethodMirror methodMirror,
    [Map<String, ArgParser> commands]) {

  var parser = new ArgParser();

  var parameters = methodMirror.parameters;

  parameters.where((parameter) => parameter.isNamed).forEach((parameter) {

    _Arg arg;
    var type = parameter.type;
    var defaultValue;

    if(type == reflectClass(String)) {
      arg = new Option();
    } else if(type == reflectClass(bool)) {
      arg = new Flag();
    }
    // TODO: handle List, List<String> as Options with allowMultiple = true.

    InstanceMirror argAnnotation = parameter.metadata.firstWhere((annotation) =>
        annotation.reflectee is _Arg, orElse: () => null);

    if(argAnnotation != null) {
      arg = argAnnotation.reflectee;
    }

    var name = MirrorSystem.getName(parameter.simpleName);

    if(parameter.hasDefaultValue) {
      defaultValue = parameter.defaultValue.reflectee;
    }

    if(arg == null) {
      throw 'Parameter $name is not a Flag, Option, Rest, List, String, bool';
    }

    _addArgToParser(parser, separatorsToCamelCase.decode(name), defaultValue, arg);
  });

  if(commands != null) {
    commands.forEach((command, commandParser) {
      parser.addCommand(command, commandParser);
    });
  }

  return parser;
}

ArgParser _getParserFromClass(Type theClass) {

  var classMirror = reflectClass(theClass);

  // TODO: Include inherited methods, when supported by 'dart:mirrors'.
  var methods = classMirror.declarations.values
      .where((d) =>
          d is MethodMirror &&
          d.isRegularMethod &&
          !d.isStatic);

  Map<MethodMirror, SubCommand> subCommands = {};

  methods.forEach((methodMirror) {
    var subCommand = methodMirror.metadata
        .map((im) => im.reflectee)
        .firstWhere(
            (v) => v is SubCommand,
            orElse: () => null);

    if(subCommand != null) {
      subCommands[methodMirror] = subCommand;
    }
  });

  var commands = {};

  subCommands.forEach((methodMirror, subCommand) {
    var usage = _getParserFromFunction(methodMirror);
    var commandName = separatorsToCamelCase
        .decode(MirrorSystem.getName(methodMirror.simpleName));
    commands[commandName] = usage;
  });

  var constructors = classMirror.declarations.values
      .where((d) => d is MethodMirror && d.isConstructor);

  var unnamedConstructor = _getUnnamedConstructor(classMirror);

  return _getParserFromFunction(unnamedConstructor, commands);
}

void _addArgToParser(ArgParser parser, String name, defaultValue, _Arg arg) {

  var parserMirror = reflect(parser);

  var namedParameters = {};

  InstanceMirror argMirror = reflect(arg);

  setNamedParameter(Symbol name) {
    var fieldValue = argMirror.getField(name).reflectee;

    if(fieldValue != null) {
      namedParameters[name] = fieldValue;
    }
  }

  mergeProperties(Type type) {
    reflectClass(type)
      .declarations
      .values
      .where((DeclarationMirror d) => d is MethodMirror && d.isGetter)
      .map((methodMirror) => methodMirror.simpleName)
      .forEach(setNamedParameter);
  }

  mergeProperties(_Arg);

  var suffix;

  if(arg is Option) {

    suffix = 'Option';

    mergeProperties(Option);
  }

  if(arg is Flag) {

    suffix = 'Flag';

    mergeProperties(Flag);
  }

  if(defaultValue != null) {
    namedParameters[#defaultsTo] = defaultValue;
  }

  var parserMethod = 'add$suffix';

  print('Adding option: "$name"');

  parserMirror.invoke(new Symbol(parserMethod), [name], namedParameters);
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

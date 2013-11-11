
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

    Arg arg;
    var type = parameter.type;
    var defaultValue;

    if(type == reflectClass(String)) {
      arg = new Option();
    } else if(type == reflectClass(bool)) {
      arg = new Flag();
    }
    // TODO: handle List, List<String> as Options with allowMultiple = true.

    InstanceMirror argAnnotation = parameter.metadata.firstWhere((annotation) =>
        annotation.reflectee is Arg, orElse: () => null);

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

    _addArgToParser(parser, name, defaultValue, arg);
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

  Map<MethodMirror, ScriptCommand> subCommands = {};

  methods.forEach((methodMirror) {
    var subCommand = methodMirror.metadata
        .map((im) => im.reflectee)
        .firstWhere(
            (v) => v is ScriptCommand,
            orElse: () => null);

    if(subCommand != null) {
      subCommands[methodMirror] = subCommand;
    }
  });

  var commands = {};

  subCommands.forEach((methodMirror, subCommand) {
    var usage = _getParserFromFunction(methodMirror);
    commands[MirrorSystem.getName(methodMirror.simpleName)] = usage;
  });

  var constructors = classMirror.declarations.values
      .where((d) => d is MethodMirror && d.isConstructor);

  var unnamedConstructor = _getUnnamedConstructor(classMirror);

  return _getParserFromFunction(unnamedConstructor, commands);
}

void _addArgToParser(ArgParser parser, String name, defaultValue, Arg arg) {

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

  mergeProperties(Arg);

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

  parserMirror.invoke(new Symbol(parserMethod), [name], namedParameters);
}

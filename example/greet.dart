#!/usr/bin/env dart

import 'package:cli/cli.dart';

/// A simple comand line script which outputs a greeting.
main(arguments) => new SimpleScript(greet).execute(arguments);

greet(@Rest() who, {String salutation : 'Hello', bool exclaim : false}) =>
    print('$salutation ${who.join(' ')}${exclaim ? '!' : ''}')

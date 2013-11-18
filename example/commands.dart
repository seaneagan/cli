#!/usr/bin/env dart

import 'package:cli/cli.dart';

/// A simple comand line script with commands.
main(arguments) => new CommandScript(
    Commands,
    description: 'Does command-y stuff')
    .execute(arguments);

class Commands {

  @SubCommand()
  foo({bool fooFlag}) {
    print('foo');
    print('fooFlag: $fooFlag');
  }
  @SubCommand()
  bar() {
    print('bar');
  }
  @SubCommand()
  baz() {
    print('baz');
  }
}

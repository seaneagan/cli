// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library cli;

import 'dart:io';
import 'dart:async';
import 'dart:convert';

/// A cli command which can be run with a [Runner].
class Command {

  final String executable;
  final List<String> arguments;

  Command(this.executable, this.arguments);

  String toString() =>
      '$executable ${arguments.join(' ')}';
}

/// An environment in which a command can be run.
class Environment {

  final String workingDirectory;
  final Map<String, String> environment;
  final bool includeParentEnvironment;
  final bool runInShell;

  const Environment(
      {this.workingDirectory,
       this.environment,
       this.includeParentEnvironment: true,
       this.runInShell: false});
}

var _runner = new Runner();

Future<Process> start(
    Command command,
    {Environment environment: const Environment()}) =>
        _runner.start(
            command,
            environment: environment);

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

Future<ProcessResult> runSync(
    Command command,
    {Environment environment: const Environment(),
      Encoding stdoutEncoding: SYSTEM_ENCODING,
      Encoding stderrEncoding: SYSTEM_ENCODING}) =>
          _runner.run(
              command,
              environment: environment,
              stdoutEncoding: stdoutEncoding,
              stderrEncoding: stderrEncoding);

class Runner {

  Future<Process> start(
      Command command,
      {Environment environment: const Environment()}) => Process.start(
      command.executable,
      command.arguments,
      workingDirectory: environment.workingDirectory,
      environment: environment.environment,
      includeParentEnvironment: environment.includeParentEnvironment,
      runInShell: environment.runInShell);

  Future<ProcessResult> run(
      Command command,
      {Environment environment: const Environment(),
       Encoding stdoutEncoding: SYSTEM_ENCODING,
       Encoding stderrEncoding: SYSTEM_ENCODING}) => Process.run(
      command.executable,
      command.arguments,
      workingDirectory: environment.workingDirectory,
      environment: environment.environment,
      includeParentEnvironment: environment.includeParentEnvironment,
      runInShell: environment.runInShell,
      stdoutEncoding: stdoutEncoding,
      stderrEncoding: stderrEncoding);

  ProcessResult runSync(
      Command command,
      {Environment environment: const Environment(),
       Encoding stdoutEncoding: SYSTEM_ENCODING,
       Encoding stderrEncoding: SYSTEM_ENCODING}) => Process.runSync(
      command.executable,
      command.arguments,
      workingDirectory: environment.workingDirectory,
      environment: environment.environment,
      includeParentEnvironment: environment.includeParentEnvironment,
      runInShell: environment.runInShell,
      stdoutEncoding: stdoutEncoding,
      stderrEncoding: stderrEncoding);
}

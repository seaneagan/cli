// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:io' as io show pid;
import 'dart:async';
import 'dart:convert';
import 'package:cli/cli.dart';
import 'package:unittest/mock.dart';

class MockRunner extends Mock implements Runner {
  MockRunner(MockCommandHandler handler)
      : super.spy(new _MockRunner(handler));
}

class _MockRunner implements Runner {
  final MockCommandHandler handler;

  _MockRunner(this.handler);

  Future<Process> start(
      Command command,
      {Environment environment: const Environment()}) => new Future(() =>
      throw new UnimplementedError('MockCommandExecutor.start'));

  Future<ProcessResult> run(
      Command command,
      {Environment environment: const Environment(),
       Encoding stdoutEncoding: SYSTEM_ENCODING,
       Encoding stderrEncoding: SYSTEM_ENCODING}) =>
          new Future(() => runSync(command));

  ProcessResult runSync(
    Command command,
    {Environment environment: const Environment(),
      Encoding stdoutEncoding: SYSTEM_ENCODING,
      Encoding stderrEncoding: SYSTEM_ENCODING}) =>
          handler(command);
}

typedef ProcessResult MockCommandHandler(
    Command command);

/// Return one of these from a [MockCommandHandler].
class MockProcessResult implements ProcessResult {

  final int exitCode;
  final stdout;
  final stderr;
  int get pid {
    if(_pid == null) ++_currentPid;
    return _pid;
  }
  int _pid;

  static int _currentPid = io.pid;

  MockProcessResult(
      {this.exitCode: 0,
       this.stdout: '',
       this.stderr: '',
       int pid}) : this._pid = pid;
}

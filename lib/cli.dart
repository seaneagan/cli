// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Utilities for working with the command line.
library cli;

import 'dart:async';
import 'dart:convert';
import 'dart:mirrors';
import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart';
import 'package:cli/src/invocation_maker.dart';
import 'package:cli/src/string_codecs.dart';

part 'src/command.dart';
part 'src/runner.dart';
part 'src/runner_convenience.dart';
part 'src/script.dart';
part 'src/util.dart';
part 'src/args_codec.dart';

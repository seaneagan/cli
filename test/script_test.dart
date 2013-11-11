
import 'package:cli/cli.dart';
import 'package:unittest/unittest.dart';

List _lastSeenRest;

main() {

  group('Script', () {

    bool _happened;

    setUp(() {
      _happened = false;
      _lastSeenRest = null;
    });

    group('basic', () {

      test('no args', () {
        new Script(() {_happened = true;}).execute([]);
        expect(_happened, true);
      });

      test('flag from bool', () {
        var flagValue;
        new Script(({bool flag}) {
          flagValue = flag;
        }).execute(['--flag']);
        expect(flagValue, true);
      });

      test('option from String', () {
        var optionValue;
        new Script(({String option}) {
          optionValue = option;
        }).execute(['--option', 'value']);
        expect(optionValue, 'value');
      });

      test('flag from Flag', () {
        var flagValue;
        new Script(({@Flag() flag}) {
          flagValue = flag;
        }).execute(['--flag']);
        expect(flagValue, true);
      });

      test('option from Option', () {
        var optionValue;
        new Script(({@Option() option}) {
          optionValue = option;
        }).execute(['--option', 'value']);
        expect(optionValue, 'value');
      });

      test('positionals', () {
        var firstValue;
        var secondValue;
        new Script((String first, String second, {bool flag}) {
          firstValue = first;
          secondValue = second;
        }).execute(['--flag', 'first', 'second']);
        expect(firstValue, 'first');
        expect(secondValue, 'second');
      });

      test('rest from Rest', () {
        var firstValue;
        new Script((String first, @Rest() rest) {
          firstValue = first;
          _lastSeenRest = rest;
        }).execute(['first', 'second', 'third', 'fourth']);
        expect(firstValue, 'first');
        expect(_lastSeenRest, ['second', 'third', 'fourth']);
      });
    });

    group('withCommands', () {

      Script unit;

      setUp(() {
        unit = new Script.withCommands(CommandScript);
        CommandScript._commandHappened = false;
      });

      test('default values', () {
        unit.execute(['command']);
        expect(CommandScript._commandHappened, isTrue);
        expect(CommandScript._lastSeen.flag, false);
        expect(CommandScript._lastSeen.option, 'default');
      });

      test('args resolved', () {
        unit.execute(['--flag', '--option', 'value', 'command']);
        expect(CommandScript._commandHappened, isTrue);
        expect(CommandScript._lastSeen.flag, true);
        expect(CommandScript._lastSeen.option, 'value');
      });

      test('args resolved', () {
        unit.execute(['command', '1', '2']);
        expect(CommandScript._commandHappened, isTrue);
        expect(_lastSeenRest, ['1', '2']);
      });

      test('bad base args', () {
        unit.execute(['--bogusflag', '--bogusoption', 'value', 'command']);
        expect(CommandScript._commandHappened, isFalse);
      });

      test('no command', () {
        unit.execute([]);
        expect(CommandScript._commandHappened, isFalse);
      });

    });
  });
}

class CommandScript {
  final bool flag;
  final String option;

  static CommandScript _lastSeen;
  static bool _commandHappened;

  CommandScript({this.flag: false, this.option: 'default'});

  @ScriptCommand()
  command(@Rest() rest) {
    CommandScript._lastSeen = this;
    _lastSeenRest = rest;
    _commandHappened = true;
  }

}

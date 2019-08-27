import 'dart:io';
import 'dart:typed_data';

import 'package:kdbx/kdbx.dart';
import 'package:kdbx/src/crypto/protected_salt_generator.dart';
import 'package:kdbx/src/crypto/protected_value.dart';
import 'package:kdbx/src/internal/byte_utils.dart';
import 'package:kdbx/src/kdbx_format.dart';
import 'package:logging/logging.dart';
import 'package:logging_appenders/logging_appenders.dart';
import 'package:test/test.dart';

class FakeProtectedSaltGenerator implements ProtectedSaltGenerator {
  @override
  String decryptBase64(String protectedValue) => 'fake';

  @override
  String encryptToBase64(String plainValue) => 'fake';

}

void main() {
  Logger.root.level = Level.ALL;
  PrintAppender().attachToLogger(Logger.root);
  group('Reading', () {
    setUp(() {});

    test('First Test', () async {
      final data = await File('test/FooBar.kdbx').readAsBytes() as Uint8List;
      KdbxFormat.read(data, Credentials(ProtectedValue.fromString('FooBar')));
    });
  });

  group('Creating', () {
    test('Simple create', () {
      final kdbx = KdbxFormat.create(Credentials(ProtectedValue.fromString('FooBar')), 'CreateTest');
      expect(kdbx, isNotNull);
      expect(kdbx.body.rootGroup, isNotNull);
      expect(kdbx.body.rootGroup.name.get(), 'CreateTest');
      expect(kdbx.body.meta.databaseName.get(), 'CreateTest');
      print(kdbx.body.generateXml(FakeProtectedSaltGenerator()).toXmlString(pretty: true));
    });
    test('Create Entry', () {
      final kdbx = KdbxFormat.create(Credentials(ProtectedValue.fromString('FooBar')), 'CreateTest');
      final rootGroup = kdbx.body.rootGroup;
      final entry = KdbxEntry.create(rootGroup);
      rootGroup.addEntry(entry);
      entry.setString(KdbxKey('Password'), ProtectedValue.fromString('LoremIpsum'));
      print(kdbx.body.generateXml(FakeProtectedSaltGenerator()).toXmlString(pretty: true));
    });
  });

  group('Integration', () {
    test('Simple save and load', () {
      final credentials = Credentials(ProtectedValue.fromString('FooBar'));
      final Uint8List saved = (() {
        final kdbx = KdbxFormat.create(credentials, 'CreateTest');
        final rootGroup = kdbx.body.rootGroup;
        final entry = KdbxEntry.create(rootGroup);
        rootGroup.addEntry(entry);
        entry.setString(
            KdbxKey('Password'), ProtectedValue.fromString('LoremIpsum'));
        return kdbx.save();
      })();

//      print(ByteUtils.toHexList(saved));

      final kdbx = KdbxFormat.read(saved, credentials);
      expect(kdbx.body.rootGroup.entries.first.strings[KdbxKey('Password')].getText(), 'LoremIpsum');
      File('test.kdbx').writeAsBytesSync(saved);
    });
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/invite_code_storage.dart';
import 'invite_code_storage_stub.dart'
    if (dart.library.html) 'invite_code_storage_web.dart';

InviteCodeStorage createInviteCodeStorage() => InviteCodeStorageImpl();

final inviteCodeStorageProvider = Provider<InviteCodeStorage>((ref) {
  return createInviteCodeStorage();
});

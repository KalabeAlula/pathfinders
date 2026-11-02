import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'memories_providers.dart';

/// A signed URL for one stored photo, shared by every widget showing it.
final memoryPhotoUrlProvider = FutureProvider.autoDispose
    .family<String, String>(
      (ref, path) => ref.watch(memoryPhotoUrlsProvider).signedUrl(path),
    );

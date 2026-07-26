const developerGoogleEmail = 'ah.subhan@gmail.com';

bool isDeveloperGoogleAccount({
  required String? email,
  required Iterable<String> providerIds,
}) =>
    email?.trim().toLowerCase() == developerGoogleEmail &&
    providerIds.contains('google.com');

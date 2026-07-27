const developerGoogleEmail = 'ah.subhan@gmail.com';

bool isDeveloperGoogleAccount({
  required String? email,
  required Iterable<String> providerIds,
}) =>
    email?.trim().toLowerCase() == developerGoogleEmail &&
    providerIds.contains('google.com');

bool developerFullAccessEnabled({
  required String? email,
  required Iterable<String> providerIds,
}) => isDeveloperGoogleAccount(email: email, providerIds: providerIds);

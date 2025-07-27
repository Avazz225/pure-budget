import 'package:jne_household_app/i18n/i18n.dart';

final customPostAuthPage = '''
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <title>${I18n.translate("authSuccessful")}</title>
  </head>
  <body>
    <h2 style="text-align: center">${I18n.translate("authInfo", placeholders: {"appTitle": I18n.translate("appTitle")})}</h2>
    <p style="text-align: center">${I18n.translate("authClose")}</p>
  </body>
</html>''';
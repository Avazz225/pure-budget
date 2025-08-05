# Pure Budget

Almost complete source code for the Pure Budget app.
The file "keys.dart" imported in some packages is not included as it contains secrets and I am to lazy to pass all secrets as arguments during each build.

[changelog.md](/changelog.md) contains the changelog (as the name implies) and a small feature plan.

## Supported platforms

**Productive**:

- [Windows](https://apps.microsoft.com/store/detail/9N690C2LHXXJ?cid=DevShareMCLPCS)

**Production Access Pending**:

- Android (Testing phase)
- IOS
- MacOS

**Planned**:

- Debian
- Ubuntu

## Data Security

- the app itself is not collecting any user related data and sends it to 3rd party services, however ad providers may collect data as stated in their policies
- all data entered by the user is saved locally
- if the user uses the remote database feature to connect multiple instances data is replicated to the selected remote location. To ensure security the remote database is encrypted using a randomly generated key that can only be shared using an app generated QR-Code or manually typing the key. The key can only be accessed by Pure Budget
- the remote database file is always in full control of the user the file is not located nor will be replicated on any server of the developer

## Offline Usage

- the app itself is designed to be used without any internet connection
- the free version still requires internet access to deliver ads
- the pro version also requires access to deliver ads (on desktop) and to connect to the remote database if the user wants to connect multiple app instances

## Pro version

- the "Pro" version can currently only be purchased on Android and IOS, it will be synced to desktop when connecting to a common remote database
- it removes several limitations
  - unlimited bank accounts (instead of 2)
  - unlimited categories
  - unlimited recurring expenses
  - full access to remote functions (mobile)
  - no ads (mobile)
  - up to 24 months of historical data can be viewed (may be subject of change)

## Support

- the app is designed, developed, maintained and sold by only one person
- responses to requests may therefore take a while
- requests submitted only in English or German can be considered

## Used Packages

see [THIRD_PARTY_LICENSES.md](/THIRD_PARTY_LICENSES.md)

## Supported Languages

- Chinese
- English
- French
- German
- Hindi
- Italian
- Korean
- Japanese
- Polish
- Portuguese
- Portuguese (Brazilian)
- Russian
- Spanish
- Turkish

and additionally for my nerds ;):

- Klingon
- Syndarin (Elbian)

## Website

[https://jjsoftwaresolutions.de](https://jjsoftwaresolutions.de)

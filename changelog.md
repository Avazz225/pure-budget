# Pure Budget

## Roadmap

### 3.3.0

- report issue button to submit error reports from within the app

### 3.2.0

- scan function to extract info from receipt (including e-receipt, either per in-app scan or pdf selection) and automatically assign sum to predefined bucket
  - alternative: offer user quick select menu for buckts to assign to
- >INFO: Integration of mobile payment apps is impossible due to privacy reasons maybe push notificaations could be utilized

### 3.1.0

- added widgets for home screen [mobile]
  - [Pro-Only] create new expense
  - both versions: Display available or spent per current month (only if app is not locked)
- Systray icon with quick actions [windows]

### planned (depends on need)

- add connection to iCloud

## Changelog

### 3.0.0 bundle 25 (13.08.2025)

- Make "Pure Budget" "Ur Budget"
  - customization for whole app only for pro version (on Windows non-Trial)

### 2.5.0 bundle 24 (08.08.2025)

- allow custom names for registered devices
- minor ui changes
- support rate payments via recurring spendings

### 2.4.9 bundle 23 (31.07.2025)

- add all supported languages to msix
- improve logging function

### 2.4.8 (29.07.2025)

- [DESKTOP] fix file locations for MS Store release
- add msix config

### 2.4.7 bundle 22 (25.07.2025)

- skip db sync when changing ranges

### 2.4.6 bundle 21 (20.07.2025)

- fixed registered devices screen
- added minimal list of own device marked as blocked if it is blocked
- improved localization for datepicker
- improved ui flow for new expense
- fixed connection issue with oneDrive

### 2.4.5 bundle 20 (16.07.2025)

- fix inverted blocking logic preventing all devices from connecting

### 2.4.4 bundle 19 (16.07.2025)

- debug pro sync
- add loading animation for tasks taking a while
- debug device blocking

### 2.4.3 bundle 18 (13.07.2025)

- fix device blocking logic

### 2.4.2 bundle 17 (13.07.2025)

- fix pro version handling

### 2.4.1 bundle 16 (13.07.2025)

- delete saved keys when disconnecting from pbdb
- created registeredDevices table with metadata and register function
- sync pro status for desktop from mobile
  - registered devices table
  - with metadata
- rotate pbdb access key option
  - warning that all devices need to be reconnected
  - reconnect option for db settings (to not lose local changes)
- improve key input
- lock out devices using registered devices
- reduce unnecessary write operations

### (short development break)

- transistion to new google play account
- ...other personal reasons
- expeted slow down in development speed as the app is considered "MVP-complete"

### 2.4.0 bundle 15 (22.06.2025)

- optimize db sync flow
- add option to control sync frequency
- ad banner for desktop
- [mobile] option to lock app with biometrics
- alternative statistics as table
  - with analysis of expense shift to last month/first period or (last year [pro] or 6 months ago [free]) in absolute number and money => + 10,0 % (15€)
  - only available for total history and detail history

### 2.3.0 bundle 14 (13.06.2025)

- shared remote database (requires pro version for access)
  - without connection transactions will be cached locally and synced on connection
  - all transactions from the remote db will be cached locally
- prepare database for desktop
- add desktop specific UI and improve tablet UI
- fix move dialog

### 2.2.2 bundle 13 (19.05.2025)

- fix pro-version limitation for bank accounts
- add colored fade out to expense bottom sheet
- adjust layout format for tablet
- add behaviour on enter or OK to inputs
- move "Delete" button in bank account edit
- move edit for bank accounts

### 2.2.1 bundle 12 (14.05.2025)

- fixed bug on startup when first expense is in future

### 2.2.0 bundle 11 (14.05.2025)

- added option to create money flows between bank accounts
  - automatic is only available monthly, booked on spender side
  - automatic incoming money flows are added to the regular income
  - manual is booked on both sides (positive and negative)
- finalize balance for bank accounts
  - at every months end the not spent money is calculated and added to savings for each bank account
  - negative savings are substracted
  - saved money can be adjusted manually, but does not appear as booking
  - changes in past expenses affect balance immediately

### 2.1.2 bundle 10 (12.05.2025)

- bugfix: add default position to categories when added
- improve expense editor
- fix color selection in creation of new category
- fix visual errors with small screens
- translate datepicker hint and actions

### 2.1.1 bundle 9 (12.05.2025)

- Fixed a critical initialization bug.

### 2.1.0 bundle 8 (12.05.2025)

- add different category budgets per bank account
- preparation for re-enabling of anti-ad-block

### 2.0.0 bundle 7 (11.05.2025)

- reduce menu on top right
- introduce bottom menu on home screen to access
  - bank account(s)
  - statistics
  - home screen
  - category management
  - automatic expenses
- remove category management from settings
- add support for multiple bank accounts with separate (automatic) expenses
  - availability to filter by bank account or display all in whole app
  - separate timespan rules for each
    - if all are considered the rule of the first account is used
- added keeping track of balance for each bank account

### 1.3.0 bundle 6 (10.05.2025)

- added intro if all values are default to initially:
  - explain app overall by giving steps
  - set currency
  - set total budget per month
  - insert categories
  - insert automatic expenses
  - or import data

### 1.2.3 bundle 5 (09.05.2025)

- allow moving of expenses and auto-expenses between categories
  - for auto expenses only future instances will be moved, past instances will remain unchanged
- allow other time ranges than month for autoBookings:
  - daily: every day
  - weekly: specific day of every week (Monday, Tuesday, ...)
  - yearly: specific day of every year
- extend internal help page

### 1.2.2 bundle 4 (08.05.2025)

- fixed display bug when there is no data to display in statistics
- fixed initialization bug
- display not assigned budget even if no other category is defined

### 1.2.1 bundle 3 (07.05.2025)

- final combination of free and pro app
- add link to privacy notice in help
- fixed bug that occured when removing a category having bookings
- if a category is removed its auto-bookings will now be transferred to "Unassigned"

### 1.2.0-pre bundle 2 (07.05.2025)

- reorder languages in language selection
- combine free and pro version to one app with one in-app purchase (in testing)

### 1.1.5 (06.05.2025) > Initial release on Google Play (Bundle version: 1)

- enable edit of color for other expenses

### 1.1.4 (11.05.2025)

- add custom color picker along with default colors for budgets
  - picker is an extra popup
  - displays "Abc" in target text color to assist in color decision for user
  - necessarity to use a brightness function to determine color of overlaying text
- added spacing between lines in predefined colors

### 1.1.3 (03.05.2025)

- allow entering negative values as amounts for bookings
- allow switching bucket modes between used and available
- use of expansion tile in settings for better compatibility with small screens and easier overview

### 1.1.2 (27.04.2025)

- add language control
- add klingon as meme language, now 15 languages are supported

### 1.1.1 (26.04.2025)

- limit period selection to first period with bookings and after
- add zooming behavior to statisics

### 1.1.0 (20.04.2025)

- renew app Icon
- add statistics panes
  - 4 modes (whole one month, whole past periods, one monty by categories, categories over past periods)
- add internationalization (14 languages)
  - languages are detected automatically and cannot be changed in the app
  - default language is english if no language code is matching with the device language

### 1.0.2 (12.04.2025)

- add data import/export options

### 1.0.1 (06.04.2025)

- [FREE] disable app lock

### 1.0.0 (05.04.2025)

- first release Version

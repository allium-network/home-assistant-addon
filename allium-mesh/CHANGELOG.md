# Changelog

## 0.3.2
- Housekeeping in the add-on manifest. No functional changes.

## 0.3.1
- Ships THIRD-PARTY-NOTICES.txt: the licenses of the open-source components built
  into this add-on. No functional changes.

## 0.2.1
- Linking your account: the pairing code is now accepted in lower case too, and the
  hint gives its real lifetime (15 minutes).

## 0.2.0
- **This add-on is retired.** For remote access to Home Assistant, install
  **Allium Connect (Home Node)**: native apps, faster, and it can run the same
  Snowflake proxy (with a monthly data cap set in your dashboard). Allium Mesh keeps
  working for existing installs, but gets no new features.
- **Removed panel buttons that did not do what they said.** "Rotate Onion" only
  hid the address on screen (the same address came back on restart); "Change Mode"
  and "Factory Reset" only changed labels. To get a brand-new .onion address,
  uninstall and reinstall the add-on.
- **Linking your .onion to your account works again.** The Connect tab now has a
  field for the pairing code from your dashboard (Services → Add service → Get
  pairing code). The old "Generate Pair Code" button could never succeed.
- Settings are changed in the Configuration tab only. The panel's "change cap" and
  "reset counters" controls are off: the next restart undid them.
- The "Open add-on settings" link now opens this add-on (it pointed at a name that
  doesn't exist for repository installs), in the same window.
- The panel follows your light or dark system theme.

## 0.1.13
- **Fix: "Contribute Relay Capacity" off now really means off.** In 0.1.10 the switch
  was only passed to the agent when it was on; left unset, the agent defaulted to
  forwarding relay traffic for other peers. Off is now sent explicitly.
- **Fix: pairing with your allium.network account works.** The default
  `allium_api_url` pointed at a hostname that never existed. The default is now
  `https://allium.network`, and installs that saved the old value are corrected
  automatically at start-up.
- Built on the current Allium engine, including its latest security updates.

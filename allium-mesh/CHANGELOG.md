# Changelog

## 0.1.13
- **Fix: "Contribute Relay Capacity" off now really means off.** In 0.1.10 the switch
  was only passed to the agent when it was on; left unset, the agent defaulted to
  forwarding relay traffic for other peers. Off is now sent explicitly.
- **Fix: pairing with your allium.network account works.** The default
  `allium_api_url` pointed at a hostname that never existed. The default is now
  `https://allium.network`, and installs that saved the old value are corrected
  automatically at start-up.
- Built on the current Allium engine, including its latest security updates.

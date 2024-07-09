Yes, you can achieve similar functionality in JavaScript using the `node-hue-api` library. Here is an equivalent JavaScript code snippet that turns off a light with the given ID:

1. **Install the `node-hue-api` library:**

```sh
npm install node-hue-api
```

2. **JavaScript code:**

```javascript
const v3 = require('node-hue-api').v3;
const LightState = v3.lightStates.LightState;

// Replace with the IP address of your Philips Hue Bridge
const bridgeIpAddress = 'IP_Of_Bridge_Here';
// Replace with your username for the Hue Bridge
const username = 'your-username-here';

async function main() {
  const api = await v3.api.createLocal(bridgeIpAddress).connect(username);

  // Retrieve and print the full state of the bridge (optional)
  const bridgeConfig = await api.configuration.getConfiguration();
  console.log(bridgeConfig);

  // Turn off light with ID 2
  const lightState = new LightState().off();
  await api.lights.setLightState(2, lightState);
}

main().catch(err => {
  console.error(err);
});
```

### Steps to Get Started:

1. **Create a new user (if you don't have one):**

If you haven't created a username for your Hue Bridge, you can do so with the following code snippet. Make sure to press the link button on your Hue Bridge before running this code:

```javascript
const v3 = require('node-hue-api').v3;

const discoverBridge = async () => {
  const discoveryResults = await v3.discovery.nupnpSearch();

  if (discoveryResults.length === 0) {
    throw new Error('No Hue Bridges found.');
  }

  const bridge = discoveryResults[0];
  console.log(`Hue Bridge found at IP address ${bridge.ipaddress}`);

  const unauthenticatedApi = await v3.api.createLocal(bridge.ipaddress).connect();
  const createdUser = await unauthenticatedApi.users.createUser('my-hue-app', 'my-hue-device');

  console.log(`New username created: ${createdUser.username}`);
  console.log(`Please save this username for subsequent API calls.`);
};

discoverBridge().catch(err => {
  console.error(`Error creating username: ${err.message}`);
});
```

Run this code once to create a new user and get the username, then use this username in the main code snippet provided above.

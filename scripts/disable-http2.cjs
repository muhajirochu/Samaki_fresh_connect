// Force the Node HTTP/HTTPS agents to speak HTTP/1.1 only.
//
// Background: firebase-tools 15.x bundles node-fetch 2.7.0, which
// has an HTTP/2 stream-handling regression against
// firestore.googleapis.com on Linux. The symptom is exactly what
// `firebase deploy --only firestore:indexes` shows:
//
//   FetchError: request to
//   https://firestore.googleapis.com/v1/projects/.../indexes failed,
//   reason:  (no HTTP status returned)
//
// The same host answers fine over HTTP/1.1 (verified with `curl
// --http1.1` returning a clean 401). Forcing HTTP/1.1 in Node's
// global http/https agents removes the broken HTTP/2 path entirely
// without touching firebase-tools internals.
//
// Usage:
//   NODE_OPTIONS="--require ./scripts/disable-http2.cjs" \
//     firebase deploy --only firestore:indexes
'use strict';

const http = require('http');
const https = require('https');
const { Agent } = require('http');
const { Agent: HttpsAgent } = require('https');

// Default Node agents — created lazily by http.request / https.request
// when no `agent` option is provided. We replace them with HTTP/1.1
// equivalents so every outbound request avoids HTTP/2.
function keepHttp1(agent) {
  // Hard-disable HTTP/2 by zeroing the protocol negotiation priority.
  // This keeps the agent API intact (so callers like node-fetch that
  // pass options still work) while ensuring ALPN selects "http/1.1".
  agent.options.alpnProtocols = ['http/1.1'];
  // ALPN may be ignored if the agent was already constructed; the
  // safest belt is to also disable HTTP/2 socket reuse entirely.
  if (typeof agent.keepSocketAlive === 'function') {
    const origKeep = agent.keepSocketAlive.bind(agent);
    agent.keepSocketAlive = (socket) => {
      // Refuse to keep-alive an HTTP/2 socket — force a fresh
      // HTTP/1.1 connection on the next request.
      return socket && socket.alpnProtocol === 'http1.1' && origKeep(socket);
    };
  }
  return agent;
}

http.globalAgent = keepHttp1(new Agent({ keepAlive: true }));
https.globalAgent = keepHttp1(new HttpsAgent({ keepAlive: true }));

// node-fetch (and a few older libs) call https.request directly with
// no agent option, in which case they pick up `https.globalAgent`. By
// replacing the globals above before any user code runs we catch
// both code paths.
//
// One last belt: some code paths construct their own Agent. Force
// ALPN to http/1.1 there too by intercepting the Agent constructor.
const OrigAgent = Agent;
const OrigHttpsAgent = HttpsAgent;
function PatchedAgent(opts) {
  const a = new OrigAgent({ alpnProtocols: ['http/1.1'], ...opts });
  return keepHttp1(a);
}
function PatchedHttpsAgent(opts) {
  const a = new OrigHttpsAgent({ alpnProtocols: ['http/1.1'], ...opts });
  return keepHttp1(a);
}
PatchedAgent.prototype = OrigAgent.prototype;
PatchedHttpsAgent.prototype = OrigHttpsAgent.prototype;
http.Agent = PatchedAgent;
https.Agent = PatchedHttpsAgent;
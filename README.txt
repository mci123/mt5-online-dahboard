MT5 ONLINE TWO-BOT DASHBOARD — SOURCE PACKAGE

WHAT THIS IS
A browser dashboard plus a small Node.js service and an MT5 Expert Advisor bridge. Once deployed, open the hosted HTTPS URL in Chrome on Android. Your Windows MT5 terminal polls the service and receives the SMC/Scalper enable switches and risk percentage.

IMPORTANT LIMITATIONS
- This package is source code, not a deployed public URL and not a compiled MT5 EA.
- I cannot publish it to a hosting account without your account/deployment access.
- The included EA logic is an early demo prototype. It has not been compiled or strategy-tested here. Use a demo account only; do not use on a live account.
- The current strategy logic is simplified EMA/RSI plus a strict but basic sweep/BOS/FVG/OB approximation. It is not a validated institutional SMC implementation.
- The dashboard key is a shared secret. Use a long random value, keep it private, and do not paste broker login/passwords into the website.

DEPLOYMENT OVERVIEW
1. Deploy this folder as a Node web service on a host that supports Node.js 18+ and HTTPS (for example Render, Railway, or another Node host).
2. Set the start command to: npm start
3. Add an environment variable named DASHBOARD_KEY with a private random value of at least 24 characters. Use a long random string and keep it secret.
4. After deployment, copy the HTTPS service URL.
5. In mt5/MT5_Online_Bridge_Two_Bots.mq5, set BridgeBaseURL to that HTTPS URL and BridgeSecret to the exact DASHBOARD_KEY value. Compile in MetaEditor.
6. In MT5 desktop, open Tools > Options > Expert Advisors and add the service origin (for example https://your-service.example) to the allowed WebRequest URLs.
7. Attach the EA to a chart on your Exness demo account. Enable Algo Trading. Keep MT5 and the Windows computer online.
8. Open the hosted URL in Chrome on your phone, enter the same dashboard key, connect, and use Save controls.

SECURITY
- Never expose MT5 terminal ports directly to the internet.
- Never share the DASHBOARD_KEY publicly.
- Use HTTPS hosting only. Rotate the key if it is exposed.
- This prototype uses a shared key in query parameters for simplicity. For production use, upgrade to a proper authenticated API with rate limiting, audit logs, and encrypted secret management.

API
GET  /api/state?key=YOUR_KEY
POST /api/control?key=YOUR_KEY   body: SMC=1\nSCALP=1\nRISK=1.0
POST /api/status?key=YOUR_KEY    EA heartbeat/status
GET  /api/status-view?key=YOUR_KEY
GET  /health

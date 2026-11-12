const http = require('http');
const fs = require('fs');
const path = require('path');
const PORT = process.env.PORT || 3000;
const KEY = process.env.DASHBOARD_KEY;
if (!KEY || KEY.length < 24) { console.error('Set DASHBOARD_KEY to a private random value of at least 24 characters.'); process.exit(1); }
let state = { smc: true, scalp: true, risk: 1.0, balance: '--', equity: '--', positions: '--', smcStatus: 'Waiting for MT5', scalpStatus: 'Waiting for MT5', updated: null };
const server = http.createServer((req,res) => {
  const u = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
  if (u.pathname === '/health') { res.writeHead(200, {'Content-Type':'text/plain'}); return res.end('ok'); }
  if (u.pathname.startsWith('/api/')) {
    if (u.searchParams.get('key') !== KEY) { res.writeHead(401, {'Content-Type':'text/plain'}); return res.end('Unauthorized'); }
    if (u.pathname === '/api/state' && req.method === 'GET') {
      res.writeHead(200, {'Content-Type':'text/plain; charset=utf-8','Cache-Control':'no-store'});
      return res.end(`SMC=${state.smc?1:0}\nSCALP=${state.scalp?1:0}\nRISK=${state.risk}\n`);
    }
    if (u.pathname === '/api/control' && req.method === 'POST') {
      let body=''; req.on('data', c => { body += c; if(body.length > 2048) req.destroy(); });
      req.on('end', () => {
        for (const line of body.split(/\r?\n/)) { const [k,v] = line.split('=');
          if (k==='SMC') state.smc = v==='1';
          if (k==='SCALP') state.scalp = v==='1';
          if (k==='RISK') { const n=Number(v); if(Number.isFinite(n) && n>=0.1 && n<=2) state.risk=n; }
        }
        res.writeHead(200, {'Content-Type':'application/json'}); res.end(JSON.stringify({ok:true}));
      }); return;
    }
    if (u.pathname === '/api/status-view' && req.method === 'GET') {
      res.writeHead(200, {'Content-Type':'application/json','Cache-Control':'no-store'});
      return res.end(JSON.stringify(state));
    }
    if (u.pathname === '/api/status' && req.method === 'POST') {
      let body=''; req.on('data', c => body += c); req.on('end', () => {
        const p = new URLSearchParams(body);
        state.balance=p.get('balance') || state.balance; state.equity=p.get('equity') || state.equity;
        state.positions=p.get('positions') || state.positions;
        state.smcStatus=p.get('smc') || state.smcStatus; state.scalpStatus=p.get('scalp') || state.scalpStatus;
        state.updated=Date.now(); res.writeHead(200, {'Content-Type':'text/plain'}); res.end('ok');
      }); return;
    }
    res.writeHead(404); return res.end('Not found');
  }
  const file = u.pathname === '/' ? 'index.html' : path.basename(u.pathname);
  const target = path.join(__dirname,'public',file);
  if (!target.startsWith(path.join(__dirname,'public'))) { res.writeHead(403); return res.end(); }
  fs.readFile(target,(err,data)=>{ if(err){res.writeHead(404);return res.end('Not found');}
    const type=file.endsWith('.css')?'text/css':file.endsWith('.js')?'text/javascript':'text/html';
    res.writeHead(200,{'Content-Type':type,'Cache-Control':'no-store'});res.end(data);
  });
});
server.listen(PORT,'0.0.0.0',()=>console.log(`Dashboard listening on ${PORT}`));

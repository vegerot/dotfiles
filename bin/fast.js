#!/usr/bin/env node
const FastSpeedtest = require("fast-speedtest-api");

let speedest = new FastSpeedtest({
  token : 'YXNkZmFzZGxmbnNkYWZoYXNkZmhrYWxm',
  verbose : true,
  timeout : 5000,
  https : true,
  urlCount : 5,
  buffersize : 8,
  unit : FastSpeedtest.UNITS.Mbps,
});

speedest.getSpeed()
    .then(s => { console.log(`Speed: ${s} Mpbs`); })
    .catch(e => { console.error(e.message); });

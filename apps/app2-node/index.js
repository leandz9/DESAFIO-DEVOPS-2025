const express = require('express');
const moment = require('moment');
const redis = require('redis');
const promClient = require('prom-client');

const app = express();
const port = 3000;

const REDIS_HOST = process.env.REDIS_HOST || 'redis';
const REDIS_PORT = 6379;
const CACHE_TTL = 60;

const register = new promClient.Registry();
promClient.collectDefaultMetrics({ register });

const requestCount = new promClient.Counter({
  name: 'app_request_count',
  help: 'Total request count',
  labelNames: ['endpoint'],
  registers: [register]
});

const cacheHit = new promClient.Counter({
  name: 'app_cache_hit_count',
  help: 'Total cache hits',
  labelNames: ['endpoint'],
  registers: [register]
});

const cacheMiss = new promClient.Counter({
  name: 'app_cache_miss_count',
  help: 'Total cache misses',
  labelNames: ['endpoint'],
  registers: [register]
});

const requestLatency = new promClient.Histogram({
  name: 'app_request_latency_seconds',
  help: 'Request latency in seconds',
  labelNames: ['endpoint'],
  registers: [register]
});

async function getRedisClient() {
  const client = redis.createClient({ url: `redis://${REDIS_HOST}:${REDIS_PORT}` });
  client.on('error', err => console.log('Redis error:', err));
  await client.connect();
  return client;
}

app.get('/', (req, res) => {
  res.send(`
    <html>
      <head><title>App2 - Node.js</title></head>
      <body style="text-align:center; font-family:sans-serif; background-color:#f9f9f9; padding-top: 30px;">
        <h1>App2 - Node.js</h1>
        <p>Bem-vindo! Explore os endpoints:</p>
        <ul style="list-style: none;">
          <li><a href="/text">/text</a></li>
          <li><a href="/time">/time</a></li>
          <li><a href="/metrics">/metrics</a></li>
        </ul>
        <img src="https://media.giphy.com/media/13HgwGsXF0aiGY/giphy.gif" width="300"/>
      </body>
    </html>
  `);
});


app.get('/text', async (req, res) => {
  const timer = requestLatency.startTimer({ endpoint: '/text' });
  requestCount.inc({ endpoint: '/text' });

  const message = "Texto fixo da aplicação Node.js";
  try {
    const client = await getRedisClient();
    const key = 'app2:text';
    const cached = await client.get(key);
    if (cached) {
      cacheHit.inc({ endpoint: '/text' });
      await client.quit();
      timer();
      return res.json({ message: cached, source: 'cache' });
    }
    cacheMiss.inc({ endpoint: '/text' });
    await client.setEx(key, CACHE_TTL, message);
    await client.quit();
  } catch (error) {
    console.error(error);
  }
  timer();
  return res.json({ message, source: 'app' });
});

app.get('/time', async (req, res) => {
  const timer = requestLatency.startTimer({ endpoint: '/time' });
  requestCount.inc({ endpoint: '/time' });

  const now = moment().format('YYYY-MM-DD HH:mm:ss');
  try {
    const client = await getRedisClient();
    const key = 'app2:time';
    const cached = await client.get(key);
    if (cached) {
      cacheHit.inc({ endpoint: '/time' });
      await client.quit();
      timer();
      return res.json({ current_time: cached, source: 'cache' });
    }
    cacheMiss.inc({ endpoint: '/time' });
    await client.setEx(key, CACHE_TTL, now);
    await client.quit();
  } catch (error) {
    console.error(error);
  }
  timer();
  return res.json({ current_time: now, source: 'app' });
});

app.get('/health', (req, res) => res.json({ status: 'healthy' }));

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

app.listen(port, () => console.log(`Node.js app rodando na porta ${port}`));

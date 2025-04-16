from flask import Flask, jsonify, Response
import datetime, redis, os, time
from prometheus_client import Counter, Histogram, CollectorRegistry, generate_latest

app = Flask(__name__)

redis_host = os.environ.get('REDIS_HOST', 'redis')
redis_port = 6379
CACHE_TTL = 10

REGISTRY = CollectorRegistry(auto_describe=True)

REQUEST_COUNT = Counter('app_request_count', 'Total app http request count', ['endpoint'], registry=REGISTRY)
CACHE_HIT = Counter('app_cache_hit_count', 'Cache hit count', ['endpoint'], registry=REGISTRY)
CACHE_MISS = Counter('app_cache_miss_count', 'Cache miss count', ['endpoint'], registry=REGISTRY)
REQUEST_LATENCY = Histogram('app_request_latency_seconds', 'Request latency', ['endpoint'], registry=REGISTRY)

def get_redis_client():
    for _ in range(5):
        try:
            client = redis.Redis(host=redis_host, port=redis_port, socket_connect_timeout=2)
            client.ping()
            return client
        except:
            time.sleep(2)
    return None

@app.route('/text')
def text():
    start = time.time()
    REQUEST_COUNT.labels(endpoint='/text').inc()
    message = "Texto fixo da aplicação Python"

    client = get_redis_client()
    if client:
        cached = client.get("app1:text")
        if cached:
            CACHE_HIT.labels(endpoint='/text').inc()
            REQUEST_LATENCY.labels(endpoint='/text').observe(time.time() - start)
            return jsonify({"message": cached.decode(), "source": "cache"})
        else:
            CACHE_MISS.labels(endpoint='/text').inc()
            client.setex("app1:text", CACHE_TTL, message)

    REQUEST_LATENCY.labels(endpoint='/text').observe(time.time() - start)
    return jsonify({"message": message, "source": "app"})

@app.route('/time')
def get_time():
    start = time.time()
    REQUEST_COUNT.labels(endpoint='/time').inc()
    now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    client = get_redis_client()
    if client:
        cached = client.get("app1:time")
        if cached:
            CACHE_HIT.labels(endpoint='/time').inc()
            REQUEST_LATENCY.labels(endpoint='/time').observe(time.time() - start)
            return jsonify({"current_time": cached.decode(), "source": "cache"})
        else:
            CACHE_MISS.labels(endpoint='/time').inc()
            client.setex("app1:time", CACHE_TTL, now)

    REQUEST_LATENCY.labels(endpoint='/time').observe(time.time() - start)
    return jsonify({"current_time": now, "source": "app"})

@app.route('/health')
def health():
    return jsonify({"status": "healthy"})

@app.route('/metrics')
def metrics():
    return Response(generate_latest(REGISTRY), mimetype="text/plain")

@app.route('/')
def home():
    return '''
        <html>
            <head><title>App1 - Python</title></head>
            <body style="text-align:center; font-family:sans-serif;">
                <h1>App1 - Python</h1>
                <p>Bem-vindo! Explore os endpoints:</p>
                <ul>
                    <li><a href="/text">/text</a></li>
                    <li><a href="/time">/time</a></li>
                    <li><a href="/metrics">/metrics</a></li>
                </ul>
                <img src="https://media.giphy.com/media/13HgwGsXF0aiGY/giphy.gif" width="300"/>
            </body>
        </html>
    '''

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

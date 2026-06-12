import http.server, socketserver, time

PORT = 8123

class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        time.sleep(30)

print(f"OK, ready to test endpoint at http://127.0.0.1:{PORT}/schedule.json")
print("Press CTRL-C to exit")
try:
    socketserver.TCPServer(("127.0.0.1", PORT), H).serve_forever()
except KeyboardInterrupt:
    print("\nStopped.")

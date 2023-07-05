#!/bin/bash

# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

curl -x https://10.0.0.10:443 -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh --proxy-insecure
# curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh

sudo bash add-google-cloud-ops-agent-repo.sh --also-install
sleep 60

tee -a /etc/google-cloud-ops-agent/config.yaml <<'EOF'
logging:
  receivers:
    syslog:
      type: files
      include_paths:
      - /tmp/request_logs.log
  service:
    pipelines:
      default_pipeline:
        receivers: [syslog]
metrics:
  receivers:
    hostmetrics:
      type: hostmetrics
      collection_interval: 60s
  processors:
    metrics_filter:
      type: exclude_metrics
      metrics_pattern: []
  service:
    pipelines:
      default_pipeline:
        receivers: [hostmetrics]
        processors: [metrics_filter]
EOF

tee -a /tmp/index.html <<'EOF'
----------- hello world --------------
EOF

tee -a /tmp/webserver.py <<'EOF'
import http.server
import socketserver
import datetime
import os

PORT = 8000
LOG_FILE = "/tmp/request_logs.log"
DIRECTORY = "/tmp"

# Change the current working directory to the desired directory
os.chdir(DIRECTORY)

class RequestHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        # Log the request
        log_entry = f"{datetime.datetime.now()} - Received request: {self.requestline}\n"
        with open(LOG_FILE, "a") as log_file:
            log_file.write(log_entry)

        # Call the parent class's do_GET method to handle the request
        super().do_GET()

# Create the server with the custom request handler
with socketserver.TCPServer(("", PORT), RequestHandler) as httpd:
    print(f"Serving at port {PORT} from directory {DIRECTORY}")
    httpd.serve_forever()
EOF

chmod +x /tmp/webserver.py
python3 /tmp/webserver.py

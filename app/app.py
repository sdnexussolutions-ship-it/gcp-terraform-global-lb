import os
from flask import Flask

app = Flask(__name__)


@app.route("/")
def home():
    return """
    <html>
        <head>
            <title>GCP Global Load Balancer Lab</title>
        </head>
        <body>
            <h1>GCP Global Load Balancer Lab</h1>
            <p>Application successfully running on Google Cloud Run.</p>
            <p>Deployed with Terraform and GitHub Actions.</p>
        </body>
    </html>
    """


@app.route("/health")
def health():
    return {"status": "healthy"}, 200


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))
    app.run(host="0.0.0.0", port=port)
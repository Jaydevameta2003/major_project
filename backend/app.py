import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from flask import Flask
from flask_cors import CORS

from cohere_content import register_test_routes
from cohere_link import register_link_routes
from cohere_twitter import register_twitter_routes

app = Flask(__name__)
CORS(app)

register_test_routes(app)
register_link_routes(app)
register_twitter_routes(app)

if __name__ == '__main__':
    app.run(debug=True)

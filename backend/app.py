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

@app.route('/')
def home():
    return "Cohere AI & Twitter Analysis Backend Running!"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)

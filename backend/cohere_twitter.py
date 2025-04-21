from flask import Flask, request, jsonify
from flask_cors import CORS
import tweepy
from textblob import TextBlob
import spacy
from langdetect import detect
from nrclex import NRCLex
import textstat
import time

app = Flask(__name__)
CORS(app)

nlp = spacy.load("en_core_web_sm")
bearer_token = 'AAAAAAAAAAAAAAAAAAAAAGWi0gEAAAAA%2BhwNVYW8RoSj%2FhX%2FVQZhZ%2Bg38RM%3DWhnist9ff9XPELHC1l3C7ftRO2F6k62pjyqPF8Pk4Kvn00Xaj2'
client = tweepy.Client(bearer_token=bearer_token)
cache = {}

@app.route('/')
def index():
    return 'Cohere Twitter API Running ✅'

@app.route('/user_tweets', methods=['POST', 'GET'])
def get_user_tweets():
    username = request.get_json().get('username') if request.method == 'POST' else request.args.get('username')

    if not username:
        return jsonify({'error': 'Username is required'}), 400

    current_time = time.time()
    cached_data = cache.get(username)

    if cached_data and current_time - cached_data[0] < 900:
        return jsonify({'username': username, 'tweets': cached_data[1]})

    try:
        user = client.get_user(username=username)
        user_id = user.data.id
        response = client.get_users_tweets(id=user_id, max_results=10)

        tweets_data = []
        if response.data:
            for tweet in response.data:
                tweets_data.append(analyze_tweet(tweet.text))

        cache[username] = (current_time, tweets_data)
        return jsonify({'username': username, 'tweets': tweets_data})

    except tweepy.errors.TooManyRequests:
        return jsonify({'error': 'Rate limit exceeded. Try again later.'}), 429
    except Exception as e:
        return jsonify({'error': str(e)}), 500

def analyze_tweet(text):
    blob = TextBlob(text)
    polarity = blob.sentiment.polarity
    subjectivity = blob.sentiment.subjectivity
    keywords = list(set(blob.noun_phrases))
    doc = nlp(text)
    entities = list(set(ent.text for ent in doc.ents))
    emotion_obj = NRCLex(text)
    emotions = emotion_obj.raw_emotion_scores
    dominant_emotion = max(emotions, key=emotions.get) if emotions else "neutral"

    try:
        language = detect(text)
    except:
        language = "unknown"

    word_count = len(text.split())
    readability_score = textstat.flesch_reading_ease(text)
    toxicity_score = max(0.0, -1 * polarity)
    summary = ' '.join(text.split()[:20]) + ('...' if word_count > 20 else '')

    return {
        'summary': summary,
        'text': text,
        'polarity': polarity,
        'subjectivity': subjectivity,
        'keywords': keywords,
        'entities': entities,
        'emotion': dominant_emotion,
        'language': language,
        'word_count': word_count,
        'readability_score': readability_score,
        'toxicity_score': round(toxicity_score, 2)
    }

if __name__ == '__main__':
    import os
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port)

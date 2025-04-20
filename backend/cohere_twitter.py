from flask import Flask, request, jsonify
import tweepy
from textblob import TextBlob
import spacy
from langdetect import detect
from nrclex import NRCLex
import textstat
import time
import re

app = Flask(__name__)
nlp = spacy.load("en_core_web_sm")

# Replace with your actual Twitter API bearer token
bearer_token = 'AAAAAAAAAAAAAAAAAAAAAGWi0gEAAAAA%2BhwNVYW8RoSj%2FhX%2FVQZhZ%2Bg38RM%3DWhnist9ff9XPELHC1l3C7ftRO2F6k62pjyqPF8Pk4Kvn00Xaj2'
client = tweepy.Client(bearer_token=bearer_token)

cache = {}

def analyze_tweet(text):
    # Sentiment
    blob = TextBlob(text)
    polarity = blob.sentiment.polarity
    subjectivity = blob.sentiment.subjectivity

    # Keywords (noun phrases)
    keywords = list(set(blob.noun_phrases))

    # Entities
    doc = nlp(text)
    entities = list(set(ent.text for ent in doc.ents))

    # Emotion
    emotion = NRCLex(text)
    emotions = emotion.raw_emotion_scores
    dominant_emotion = max(emotions, key=emotions.get) if emotions else "neutral"

    # Language
    try:
        language = detect(text)
    except:
        language = "unknown"

    # Word count and readability
    word_count = len(text.split())
    readability_score = textstat.flesch_reading_ease(text)

    # Naive toxicity (using simple bad word list)
    bad_words = ['hate', 'stupid', 'idiot', 'dumb', 'kill', 'die', 'trash', 'nonsense', 'annoying']
    toxicity_score = sum(text.lower().count(word) for word in bad_words) / (word_count + 1)

    # Summary: just trim to 20 words if too long
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

@app.route('/user_tweets', methods=['POST', 'GET'])
def get_user_tweets():
    if request.method == 'POST':
        data = request.get_json()
        username = data.get('username')
    else:
        username = request.args.get('username')

    if not username:
        return jsonify({'error': 'Username is required'}), 400

    current_time = time.time()
    cached_data = cache.get(username)

    if cached_data and current_time - cached_data[0] < 900:
        return jsonify({
            'username': username,
            'tweets': cached_data[1]
        })

    try:
        user = client.get_user(username=username)
        user_id = user.data.id
        response = client.get_users_tweets(id=user_id, max_results=10)

        tweets_data = []
        if response.data:
            for tweet in response.data:
                analysis = analyze_tweet(tweet.text)
                tweets_data.append(analysis)

        cache[username] = (current_time, tweets_data)

        return jsonify({
            'username': username,
            'tweets': tweets_data
        })

    except tweepy.errors.TooManyRequests:
        return jsonify({'error': 'Rate limit exceeded. Try again later.'}), 429
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)

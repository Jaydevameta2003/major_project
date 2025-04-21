from flask import Flask, request, jsonify
from flask_cors import CORS
import nltk
from textblob import TextBlob
from langdetect import detect
import spacy
from textstat import flesch_reading_ease
from nrclex import NRCLex
import cohere
import os

# ✅ Download required corpora (safe to call repeatedly)
nltk.download('punkt')
nltk.download('averaged_perceptron_tagger')
nltk.download('brown')
nltk.download('wordnet')
nltk.download('movie_reviews')
nltk.download('stopwords')

app = Flask(__name__)
CORS(app)

nlp = spacy.load("en_core_web_sm")
co = cohere.Client('RpA11TuVr7Glm5CzBTMZeXv6Zn6wzK0R5QhzxxQc')

@app.route('/')
def index():
    return 'Cohere Content API Running ✅'

@app.route('/analyze', methods=['POST'])
def analyze():
    data = request.get_json()
    user_text = data.get('text', '')

    if not user_text:
        return jsonify({'error': 'No text provided'}), 400

    try:
        prompt = f"Summarize the following text: {user_text}"
        summary_response = co.generate(model='command', prompt=prompt, max_tokens=200)
        summary = summary_response.generations[0].text.strip()
    except Exception as e:
        return jsonify({'error': f'Summary failed: {str(e)}'}), 500

    blob = TextBlob(summary)
    polarity = blob.sentiment.polarity
    subjectivity = blob.sentiment.subjectivity
    keywords = list(set(blob.noun_phrases))

    doc = nlp(user_text)
    entities = list(set((ent.text, ent.label_) for ent in doc.ents))

    emotion_obj = NRCLex(user_text)
    emotions = emotion_obj.raw_emotion_scores
    dominant_emotion = max(emotions, key=emotions.get) if emotions else "neutral"

    try:
        language = detect(user_text)
    except:
        language = "unknown"

    word_count = len(user_text.split())
    readability_score = flesch_reading_ease(user_text)
    toxicity_score = max(0.0, -1 * polarity)

    return jsonify({
        'summary': summary,
        'polarity': polarity,
        'subjectivity': subjectivity,
        'keywords': keywords,
        'entities': entities,
        'emotion': dominant_emotion,
        'language': language,
        'word_count': word_count,
        'readability_score': readability_score,
        'toxicity_score': round(toxicity_score, 2)
    })

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port)

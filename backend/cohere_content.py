from flask import request, jsonify
from textblob import TextBlob
from langdetect import detect, LangDetectException
import spacy
import subprocess
from textstat import flesch_reading_ease
from nrclex import NRCLex
import cohere

co = cohere.Client('RpA11TuVr7Glm5CzBTMZeXv6Zn6wzK0R5QhzxxQc')

try:
    nlp = spacy.load("en_core_web_sm")
except OSError:
    subprocess.run(["python", "-m", "spacy", "download", "en_core_web_sm"])
    nlp = spacy.load("en_core_web_sm")

def register_test_routes(app):
    @app.route('/analyze', methods=['POST'])
    def analyze():
        data = request.get_json()
        user_text = data.get('text', '').strip()

        if not user_text:
            return jsonify({'error': 'No text provided'}), 400

        try:
            prompt = f"Summarize the following text: {user_text}"
            summary_response = co.generate(model='command', prompt=prompt, max_tokens=200)
            summary = summary_response.generations[0].text.strip()
        except Exception as e:
            return jsonify({'error': f'Summary error: {str(e)}'}), 500

        try:
            blob = TextBlob(summary)
            polarity = blob.sentiment.polarity
            subjectivity = blob.sentiment.subjectivity
            keywords = list(set(blob.noun_phrases))
        except:
            polarity, subjectivity, keywords = 0.0, 0.0, []

        try:
            doc = nlp(user_text)
            entities = list(set((ent.text, ent.label_) for ent in doc.ents))
        except:
            entities = []

        try:
            emotion_obj = NRCLex(user_text)
            emotions = emotion_obj.raw_emotion_scores
            dominant_emotion = max(emotions, key=emotions.get) if emotions else "neutral"
        except:
            dominant_emotion = "neutral"

        try:
            language = detect(user_text)
        except LangDetectException:
            language = "unknown"

        word_count = len(user_text.split())

        try:
            readability_score = flesch_reading_ease(user_text)
        except:
            readability_score = 0.0

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

from flask import Flask, request, jsonify
from flask_cors import CORS
import cohere
from textblob import TextBlob
from langdetect import detect, LangDetectException
import spacy
import subprocess
from textstat import flesch_reading_ease
from nrclex import NRCLex

app = Flask(__name__)
CORS(app)

# Cohere API key (replace with your own)
co = cohere.Client('RpA11TuVr7Glm5CzBTMZeXv6Zn6wzK0R5QhzxxQc')

# Load or download spaCy model
try:
    nlp = spacy.load("en_core_web_sm")
except OSError:
    subprocess.run(["python", "-m", "spacy", "download", "en_core_web_sm"])
    nlp = spacy.load("en_core_web_sm")

@app.route('/analyze', methods=['POST'])
def analyze():
    data = request.get_json()
    user_text = data.get('text', '').strip()

    if not user_text:
        return jsonify({'error': 'No text provided'}), 400

    try:
        # 1. Summary using Cohere
        prompt = f"Summarize the following text: {user_text}"
        summary_response = co.generate(model='command', prompt=prompt, max_tokens=200)
        summary = summary_response.generations[0].text.strip()
    except Exception as e:
        return jsonify({'error': f'Error generating summary: {str(e)}'}), 500

    try:
        # 2. Sentiment Analysis
        blob = TextBlob(summary)
        polarity = blob.sentiment.polarity
        subjectivity = blob.sentiment.subjectivity

        # 3. Keyword Extraction
        keywords = list(set(blob.noun_phrases))
    except Exception:
        polarity, subjectivity, keywords = 0.0, 0.0, []

    try:
        # 4. Named Entity Recognition
        doc = nlp(user_text)
        entities = list(set((ent.text, ent.label_) for ent in doc.ents))
    except Exception:
        entities = []

    try:
        # 5. Emotion Detection
        emotion_obj = NRCLex(user_text)
        emotions = emotion_obj.raw_emotion_scores
        dominant_emotion = max(emotions, key=emotions.get) if emotions else "neutral"
    except Exception:
        dominant_emotion = "neutral"

    try:
        # 6. Language Detection
        language = detect(user_text)
    except LangDetectException:
        language = "unknown"

    # 7. Word Count
    word_count = len(user_text.split())

    # 8. Readability Score
    try:
        readability_score = flesch_reading_ease(user_text)
    except Exception:
        readability_score = 0.0

    # 9. Toxicity Score (basic polarity inverse)
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
    app.run(host='0.0.0.0', port=5000, debug=True)

from flask import Flask, request, jsonify
from flask_cors import CORS
import cohere
from textblob import TextBlob
from langdetect import detect
import spacy
from textstat import flesch_reading_ease
from nrclex import NRCLex

app = Flask(__name__)
CORS(app)

# Cohere API key (replace with your own)
co = cohere.Client('RpA11TuVr7Glm5CzBTMZeXv6Zn6wzK0R5QhzxxQc')
nlp = spacy.load("en_core_web_sm")  # Load spaCy model for NER

@app.route('/analyze', methods=['POST'])
def analyze():
    data = request.get_json()
    user_text = data.get('text', '')

    if not user_text:
        return jsonify({'error': 'No text provided'}), 400

    # 1. Summary using Cohere
    prompt = f"Summarize the following text: {user_text}"
    summary_response = co.generate(model='command', prompt=prompt, max_tokens=200)
    summary = summary_response.generations[0].text.strip()

    # 2. Sentiment Analysis (using TextBlob)
    blob = TextBlob(summary)
    polarity = blob.sentiment.polarity
    subjectivity = blob.sentiment.subjectivity

    # 3. Keyword Extraction (naive method using noun phrases from TextBlob)
    keywords = list(set(blob.noun_phrases))

    # 4. Named Entity Recognition (NER using spaCy)
    doc = nlp(user_text)
    entities = list(set((ent.text, ent.label_) for ent in doc.ents))

    # 5. Emotion Detection using NRC Lex
    emotion_obj = NRCLex(user_text)
    emotions = emotion_obj.raw_emotion_scores
    dominant_emotion = max(emotions, key=emotions.get) if emotions else "neutral"

    # 6. Language Detection (using langdetect library)
    try:
        language = detect(user_text)
    except:
        language = "unknown"

    # 7. Word Count
    word_count = len(user_text.split())

    # 8. Readability Score (using Flesch Reading Ease)
    readability_score = flesch_reading_ease(user_text)

    # 9. Toxicity Detection (basic check using sentiment polarity)
    # This could be replaced with more advanced methods like Detoxify or Perspective API
    toxicity_score = max(0.0, -1 * polarity)  # if sentiment is negative, assume slightly toxic

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

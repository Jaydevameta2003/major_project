from flask import Flask, request, jsonify
from flask_cors import CORS
import cohere
from textblob import TextBlob
from langdetect import detect
import spacy
from textstat import flesch_reading_ease
from nrclex import NRCLex
from newspaper import Article

app = Flask(__name__)
CORS(app)

# Initialize services
co = cohere.Client('RpA11TuVr7Glm5CzBTMZeXv6Zn6wzK0R5QhzxxQc')
nlp = spacy.load("en_core_web_sm")

@app.route('/analyze_url', methods=['POST'])
def analyze_url():
    data = request.get_json()
    url = data.get('url', '')

    if not url:
        return jsonify({'error': 'No URL provided'}), 400

    try:
        # Extract article using newspaper3k
        article = Article(url)
        article.download()
        article.parse()
        user_text = article.text

        if not user_text.strip():
            return jsonify({'error': 'Failed to extract content from URL'}), 500

        # Summarization using Cohere
        prompt = f"Summarize the following news article: {user_text}"
        summary_response = co.generate(model='command', prompt=prompt, max_tokens=200)
        summary = summary_response.generations[0].text.strip()

        # Sentiment Analysis
        blob = TextBlob(summary)
        polarity = blob.sentiment.polarity
        subjectivity = blob.sentiment.subjectivity

        # Keyword extraction
        keywords = list(set(blob.noun_phrases))

        # Named Entity Recognition
        doc = nlp(user_text)
        entities = list(set((ent.text, ent.label_) for ent in doc.ents))

        # Emotion detection
        emotion_obj = NRCLex(user_text)
        emotions = emotion_obj.raw_emotion_scores
        dominant_emotion = max(emotions, key=emotions.get) if emotions else "neutral"

        # Language detection
        try:
            language = detect(user_text)
        except:
            language = "unknown"

        # Word count
        word_count = len(user_text.split())

        # Readability
        readability_score = flesch_reading_ease(user_text)

        # Toxicity estimation
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
            'toxicity_score': round(toxicity_score, 2),
            'title': article.title,
            'source': article.source_url
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)

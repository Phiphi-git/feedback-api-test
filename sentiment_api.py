"""
API REST pour l'analyse de sentiments
Intègre le modèle ML dans l'API Node.js via un service Python
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import sys
from pathlib import Path

# Importer l'analyseur de sentiments
from sentiment_analyzer import SentimentAnalyzer

app = Flask(__name__)
CORS(app)

# Initialiser l'analyseur
analyzer = SentimentAnalyzer()

# Charger le modèle entraîné
try:
    analyzer.load_model('sentiment_model.pkl')
    print("✓ Modèle chargé avec succès!")
except Exception as e:
    print(f"⚠️ Avertissement: Modèle non trouvé ({e})")
    print("   Les prédictions ne seront pas disponibles")


@app.route('/health', methods=['GET'])
def health():
    """Health check"""
    return jsonify({
        'status': 'healthy',
        'service': 'sentiment-analysis',
        'model_loaded': analyzer.is_trained
    })


@app.route('/analyze', methods=['POST'])
def analyze_sentiment():
    """
    Analyse le sentiment d'un texte
    
    Body:
    {
        "text": "Texte à analyser"
    }
    
    Response:
    {
        "sentiment": "positif",
        "confidence": 0.85,
        "probabilities": {...}
    }
    """
    if not analyzer.is_trained:
        return jsonify({
            'error': 'Model not loaded',
            'message': 'Le modèle n\'est pas disponible'
        }), 503
    
    data = request.get_json()
    
    if not data or 'text' not in data:
        return jsonify({
            'error': 'Missing text',
            'message': 'Le champ "text" est requis'
        }), 400
    
    text = data['text']
    
    try:
        result = analyzer.predict(text)
        return jsonify(result)
    except Exception as e:
        return jsonify({
            'error': 'Prediction error',
            'message': str(e)
        }), 500


@app.route('/analyze-batch', methods=['POST'])
def analyze_batch():
    """
    Analyse les sentiments de plusieurs textes
    
    Body:
    {
        "texts": ["texte1", "texte2", ...]
    }
    
    Response:
    [
        {"sentiment": "positif", "confidence": 0.85, ...},
        {"sentiment": "négatif", "confidence": 0.92, ...}
    ]
    """
    if not analyzer.is_trained:
        return jsonify({
            'error': 'Model not loaded'
        }), 503
    
    data = request.get_json()
    
    if not data or 'texts' not in data:
        return jsonify({
            'error': 'Missing texts',
            'message': 'Le champ "texts" est requis'
        }), 400
    
    texts = data['texts']
    
    if not isinstance(texts, list):
        return jsonify({
            'error': 'Invalid format',
            'message': '"texts" doit être un tableau'
        }), 400
    
    try:
        results = analyzer.analyze_batch(texts)
        return jsonify({
            'count': len(results),
            'results': results
        })
    except Exception as e:
        return jsonify({
            'error': 'Batch analysis error',
            'message': str(e)
        }), 500


@app.route('/stats', methods=['GET'])
def stats():
    """
    Retourne les statistiques du modèle
    """
    return jsonify({
        'model_trained': analyzer.is_trained,
        'model_type': 'Random Forest + TF-IDF',
        'languages': ['French', 'English'],
        'sentiments': ['positif', 'neutre', 'négatif'],
        'capabilities': [
            'Single text analysis',
            'Batch analysis',
            'Confidence scores',
            'Probability distribution'
        ]
    })


@app.errorhandler(404)
def not_found(error):
    return jsonify({
        'error': 'Not found',
        'available_endpoints': [
            'POST /analyze',
            'POST /analyze-batch',
            'GET /health',
            'GET /stats'
        ]
    }), 404


if __name__ == '__main__':
    import os
    port = int(os.environ.get('PORT', 8080))
    print(f"\n🚀 Serveur API Sentiment Analysis démarré sur le port {port}")
    print("📚 Endpoints disponibles:")
    print("   POST   /analyze")
    print("   POST   /analyze-batch")
    print("   GET    /health")
    print("   GET    /stats\n")
    
    app.run(host='0.0.0.0', port=port, debug=False)

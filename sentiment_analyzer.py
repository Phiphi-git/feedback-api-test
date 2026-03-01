import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.ensemble import RandomForestClassifier
from sklearn.pipeline import Pipeline
from sklearn.metrics import classification_report, confusion_matrix, accuracy_score
import pickle
import json
from pathlib import Path

class SentimentAnalyzer:
    """
    Analyseur de sentiments pour les feedbacks clients
    Utilise Machine Learning pour classifier: Positif, Neutre, Négatif
    """
    
    def __init__(self):
        self.model = None
        self.vectorizer = None
        self.is_trained = False
        
    def prepare_training_data(self, feedbacks_file='feedback_data.csv'):
        """
        Prépare les données d'entraînement à partir du fichier CSV
        
        Args:
            feedbacks_file: Chemin vers le fichier CSV des feedbacks
            
        Returns:
            pd.DataFrame: Données avec sentiments label
        """
        try:
            df = pd.read_csv(feedbacks_file)
            
            # Créer les labels de sentiment basés sur le texte
            df['sentiment'] = df['comment'].apply(self._classify_sentiment)
            
            print(f"✓ Données préparées: {len(df)} feedbacks")
            print(f"  - Positifs: {(df['sentiment'] == 'positif').sum()}")
            print(f"  - Neutres: {(df['sentiment'] == 'neutre').sum()}")
            print(f"  - Négatifs: {(df['sentiment'] == 'négatif').sum()}")
            
            return df
            
        except FileNotFoundError:
            print(f"❌ Fichier {feedbacks_file} non trouvé")
            return None
    
    def _classify_sentiment(self, text):
        """
        Classification basée sur des mots-clés
        À améliorer avec un modèle plus avancé
        """
        if not isinstance(text, str):
            return 'neutre'
        
        text_lower = text.lower()
        
        # Mots positifs
        positive_words = ['excellent', 'good', 'great', 'amazing', 'love', 'perfect', 
                         'wonderful', 'fantastic', 'awesome', 'best', 'happy', 'satisfied']
        
        # Mots négatifs
        negative_words = ['bad', 'terrible', 'awful', 'hate', 'worst', 'poor', 
                         'disappointing', 'useless', 'frustrated', 'angry', 'sad']
        
        positive_count = sum(1 for word in positive_words if word in text_lower)
        negative_count = sum(1 for word in negative_words if word in text_lower)
        
        if positive_count > negative_count:
            return 'positif'
        elif negative_count > positive_count:
            return 'négatif'
        else:
            return 'neutre'
    
    def train(self, X_train, y_train):
        """
        Entraîne le modèle ML
        
        Args:
            X_train: Textes d'entraînement
            y_train: Labels de sentiments
        """
        print("\n🤖 Entraînement du modèle...")
        
        # Pipeline: Vectorization + Classification
        self.model = Pipeline([
            ('tfidf', TfidfVectorizer(
                max_features=5000,
                min_df=2,
                max_df=0.8,
                ngram_range=(1, 2),
                lowercase=True
            )),
            ('clf', RandomForestClassifier(
                n_estimators=100,
                max_depth=20,
                random_state=42,
                n_jobs=-1
            ))
        ])
        
        self.model.fit(X_train, y_train)
        self.is_trained = True
        print("✓ Modèle entraîné avec succès!")
    
    def evaluate(self, X_test, y_test):
        """
        Évalue le modèle sur les données de test
        
        Args:
            X_test: Textes de test
            y_test: Labels de test
        """
        if not self.is_trained:
            print("❌ Le modèle n'a pas été entraîné")
            return
        
        print("\n📊 Évaluation du modèle:")
        
        y_pred = self.model.predict(X_test)
        accuracy = accuracy_score(y_test, y_pred)
        
        print(f"\n✓ Précision globale: {accuracy:.2%}")
        print("\nRapport de classification:")
        print(classification_report(y_test, y_pred))
        
        print("\nMatrice de confusion:")
        print(confusion_matrix(y_test, y_pred))
        
        return accuracy
    
    def predict(self, text):
        """
        Prédit le sentiment d'un texte
        
        Args:
            text: Texte à analyser
            
        Returns:
            dict: Sentiment et confiance
        """
        if not self.is_trained:
            print("❌ Le modèle n'a pas été entraîné")
            return None
        
        # Prédiction
        sentiment = self.model.predict([text])[0]
        
        # Confiance (probabilité)
        probabilities = self.model.predict_proba([text])[0]
        confidence = max(probabilities)
        
        return {
            'sentiment': sentiment,
            'confidence': float(confidence),
            'probabilities': {
                label: float(prob) 
                for label, prob in zip(self.model.classes_, probabilities)
            }
        }
    
    def analyze_batch(self, texts):
        """
        Analyse plusieurs textes à la fois
        
        Args:
            texts: Liste de textes
            
        Returns:
            list: Résultats pour chaque texte
        """
        results = []
        for text in texts:
            results.append(self.predict(text))
        return results
    
    def save_model(self, model_path='sentiment_model.pkl'):
        """
        Sauvegarde le modèle entraîné
        
        Args:
            model_path: Chemin pour sauvegarder le modèle
        """
        if not self.is_trained:
            print("❌ Le modèle n'a pas été entraîné")
            return
        
        with open(model_path, 'wb') as f:
            pickle.dump(self.model, f)
        
        print(f"✓ Modèle sauvegardé: {model_path}")
    
    def load_model(self, model_path='sentiment_model.pkl'):
        """
        Charge un modèle sauvegardé
        
        Args:
            model_path: Chemin du modèle
        """
        try:
            with open(model_path, 'rb') as f:
                self.model = pickle.load(f)
            self.is_trained = True
            print(f"✓ Modèle chargé: {model_path}")
        except FileNotFoundError:
            print(f"❌ Fichier {model_path} non trouvé")


def main():
    """
    Exemple d'utilisation
    """
    print("=" * 60)
    print("🎯 ANALYSEUR DE SENTIMENTS - FEEDBACKS CLIENTS")
    print("=" * 60)
    
    # 1. Initialiser l'analyseur
    analyzer = SentimentAnalyzer()
    
    # 2. Préparer les données
    print("\n1️⃣ Préparation des données...")
    df = analyzer.prepare_training_data('feedback_data.csv')
    
    if df is None:
        print("Veuillez fournir le fichier feedback_data.csv")
        return
    
    # 3. Diviser en train/test
    print("\n2️⃣ Division train/test (80/20)...")
    X_train, X_test, y_train, y_test = train_test_split(
        df['comment'], 
        df['sentiment'], 
        test_size=0.2, 
        random_state=42,
        stratify=df['sentiment']
    )
    
    print(f"  - Entraînement: {len(X_train)} exemples")
    print(f"  - Test: {len(X_test)} exemples")
    
    # 4. Entraîner le modèle
    analyzer.train(X_train, y_train)
    
    # 5. Évaluer
    analyzer.evaluate(X_test, y_test)
    
    # 6. Sauvegarder
    analyzer.save_model('sentiment_model.pkl')
    
    # 7. Tests sur de nouveaux textes
    print("\n3️⃣ Tests sur de nouveaux feedbacks:")
    test_texts = [
        "Ce produit est excellent! J'en suis très satisfait.",
        "Déçu par la qualité, ce n'est pas ce que j'attendais.",
        "Le produit est correctement arrivé.",
        "C'est vraiment nul, le pire achat jamais fait!",
        "Amazing product, highly recommend!"
    ]
    
    for text in test_texts:
        result = analyzer.predict(text)
        print(f"\n📝 {text}")
        print(f"   → Sentiment: {result['sentiment'].upper()}")
        print(f"   → Confiance: {result['confidence']:.2%}")


if __name__ == '__main__':
    main()

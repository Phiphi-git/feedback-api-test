FROM python:3.9-slim

WORKDIR /app

# Copier les requirements
COPY requirements_ml.txt .
RUN pip install --no-cache-dir -r requirements_ml.txt

# Copier le code ML
COPY sentiment_analyzer.py .
COPY sentiment_api.py .

# Copier les données d'entraînement (optionnel)
COPY feedback_data.csv .

# Copier le modèle pré-entraîné (s'il existe)
COPY sentiment_model.pkl . 2>/dev/null || true

# Cloud Run utilise le port 8080
ENV FLASK_PORT=8080
ENV PORT=8080

EXPOSE 8080

# Lancer l'API Flask
CMD ["python", "sentiment_api.py"]

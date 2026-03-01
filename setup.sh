#!/bin/bash
# Configuration rapide du projet pour le professeur

echo "==================================="
echo "🚀 Feedback API - Configuration"
echo "==================================="
echo ""

# Étape 1: Installer les dépendances
echo "📦 Installation des dépendances..."
npm install
if [ $? -ne 0 ]; then
    echo "❌ Erreur lors de l'installation"
    exit 1
fi
echo "✅ Dépendances installées"
echo ""

# Étape 2: Vérifier la structure
echo "📋 Vérification des fichiers..."
if [ ! -f "feedback_data.csv" ]; then
    echo "⚠️  feedback_data.csv manquant"
    echo "   Les données doivent être fournies (CSV ou API)"
fi

if [ ! -f ".env" ]; then
    echo "📝 Création du fichier .env..."
    cp .env.example .env
    echo "✅ .env créé (modifiez-le selon vos besoins)"
fi
echo ""

# Étape 3: Tester le démarrage
echo "🧪 Test de démarrage..."
echo "Lancement de l'API en arrière-plan (5 secondes)..."
timeout 5 node index.js &
sleep 2

# Vérifier si le port 3000 répond
if curl -s http://localhost:3000/api/health > /dev/null; then
    echo "✅ API fonctionne!"
    kill %1 2>/dev/null
else
    echo "⚠️  Impossible de tester l'API"
    echo "   Vérifiez que le port 3000 est disponible"
fi
echo ""

echo "==================================="
echo "✨ Configuration terminée!"
echo "==================================="
echo ""
echo "📖 Prochaines étapes:"
echo "1. Lire GUIDE_PROFESSEUR.md"
echo "2. Adapter feedback_data.csv ou configurer FEEDBACK_API_URL"
echo "3. Lancer: node index.js"
echo "4. Accéder à: http://localhost:3000/api/health"

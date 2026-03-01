#!/bin/bash
# Script de déploiement ML sur Google Cloud Run
# Usage: bash deploy-ml-cloud.sh -p YOUR_PROJECT_ID -r europe-west1

set -e

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Paramètres
PROJECT_ID=""
REGION="europe-west1"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--project)
            PROJECT_ID="$2"
            shift 2
            ;;
        -r|--region)
            REGION="$2"
            shift 2
            ;;
        *)
            echo "Usage: $0 -p PROJECT_ID [-r REGION]"
            exit 1
            ;;
    esac
done

if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}❌ Project ID requis!${NC}"
    echo "Usage: bash deploy-ml-cloud.sh -p YOUR_PROJECT_ID"
    exit 1
fi

echo -e "${BLUE}🚀 DÉPLOIEMENT ML SUR GOOGLE CLOUD${NC}"
echo ""

# 1. Vérifications préalables
echo -e "${BLUE}1️⃣  VÉRIFICATIONS PRÉALABLES${NC}"
echo ""

if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}❌ gcloud CLI non installé${NC}"
    exit 1
fi
echo -e "${GREEN}✅ gcloud CLI détecté${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker non installé${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Docker détecté${NC}"

if [ ! -f "sentiment_model.pkl" ]; then
    echo -e "${YELLOW}⚠️  sentiment_model.pkl manquant${NC}"
    echo "Le modèle sera entraîné lors du déploiement"
fi

echo ""

# 2. Configuration Google Cloud
echo -e "${BLUE}2️⃣  CONFIGURATION GOOGLE CLOUD${NC}"
echo ""

gcloud config set project $PROJECT_ID
echo -e "${GREEN}✅ Projet configuré: $PROJECT_ID${NC}"

# Activer les APIs requises
echo "Activation des APIs Google Cloud..."
gcloud services enable cloudbuild.googleapis.com run.googleapis.com containerregistry.googleapis.com

echo ""

# 3. Configuration Docker pour GCR
echo -e "${BLUE}3️⃣  CONFIGURATION DOCKER${NC}"
echo ""

gcloud auth configure-docker --quiet
echo -e "${GREEN}✅ Docker configuré pour GCR${NC}"

echo ""

# 4. Construire et pousser l'image ML
echo -e "${BLUE}4️⃣  BUILD ET PUSH IMAGE ML${NC}"
echo ""

ML_IMAGE_NAME="gcr.io/$PROJECT_ID/sentiment-ml:latest"

echo "Construction de l'image ML..."
docker build -f Dockerfile.ml -t $ML_IMAGE_NAME .

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Erreur lors de la construction${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Image construite${NC}"

echo ""
echo "Push de l'image vers Google Container Registry..."
docker push $ML_IMAGE_NAME

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Erreur lors du push${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Image pushée${NC}"

echo ""

# 5. Déployer sur Cloud Run
echo -e "${BLUE}5️⃣  DÉPLOIEMENT SUR CLOUD RUN${NC}"
echo ""

echo "Déploiement du service ML..."
gcloud run deploy sentiment-ml \
    --image $ML_IMAGE_NAME \
    --region $REGION \
    --allow-unauthenticated \
    --memory 512Mi \
    --timeout 60s \
    --max-instances 10 \
    --platform managed \
    --quiet

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Erreur lors du déploiement${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Service ML déployé${NC}"

echo ""

# 6. Récupérer l'URL du service
echo -e "${BLUE}6️⃣  RÉCUPÉRATION DES INFORMATIONS${NC}"
echo ""

ML_SERVICE_URL=$(gcloud run services describe sentiment-ml \
    --region $REGION \
    --format 'value(status.url)')

echo -e "${GREEN}✅ URL du service ML:${NC}"
echo -e "${BLUE}$ML_SERVICE_URL${NC}"

echo ""

# 7. Tests en production
echo -e "${BLUE}7️⃣  TESTS EN PRODUCTION${NC}"
echo ""

echo "Test du health check..."
HEALTH_RESPONSE=$(curl -s "$ML_SERVICE_URL/health")
echo "Réponse: $HEALTH_RESPONSE"

if echo "$HEALTH_RESPONSE" | grep -q "healthy"; then
    echo -e "${GREEN}✅ Service ML actif et fonctionnel${NC}"
else
    echo -e "${YELLOW}⚠️  Service en cours de démarrage, réessayez dans 30 secondes${NC}"
fi

echo ""

# 8. Résumé
echo -e "${BLUE}════════════════════════════════════════════${NC}"
echo -e "${GREEN}✨ DÉPLOIEMENT ML RÉUSSI!${NC}"
echo -e "${BLUE}════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}Service ML déployé sur:${NC}"
echo -e "${YELLOW}$ML_SERVICE_URL${NC}"
echo ""
echo -e "${GREEN}Endpoints disponibles:${NC}"
echo "  POST   $ML_SERVICE_URL/analyze"
echo "  GET    $ML_SERVICE_URL/health"
echo "  GET    $ML_SERVICE_URL/stats"
echo ""
echo -e "${GREEN}À utiliser dans index.js:${NC}"
echo "  SENTIMENT_API_URL=$ML_SERVICE_URL"
echo ""
echo -e "${GREEN}Commandes utiles:${NC}"
echo "  Voir les logs:      gcloud run logs read sentiment-ml --region $REGION"
echo "  Redéployer:         gcloud run deploy sentiment-ml --image $ML_IMAGE_NAME --region $REGION"
echo "  Supprimer:          gcloud run services delete sentiment-ml --region $REGION"
echo ""

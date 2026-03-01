# 🔍 CHECKLIST - Avant de déployer

## ✅ Configuration locale

- [ ] Fichier `.env` créé et rempli avec les bonnes valeurs
- [ ] `npm install` exécuté avec succès
- [ ] API démarre: `node index.js`
- [ ] `/api/health` retourne `{"success": true}`

## ✅ Google Cloud SQL

- [ ] Instance Cloud SQL créée
- [ ] Base de données `feedback_db` créée
- [ ] Table `feedbacks` créée avec les bonnes colonnes
- [ ] CSV `feedback_data.csv` importé (100+ lignes)
- [ ] Connexion testée avec l'IP et le mot de passe

## ✅ Avant le déploiement

- [ ] Fichier `index-cloud-sql-template.js` renommé en `index.js` (OU déjà remplacé)
- [ ] `Dockerfile` créé
- [ ] `.env` ne contient PAS le mot de passe en clair (utiliser Google Secret Manager)
- [ ] `.gitignore` existe et inclut `.env`

## ✅ Google Cloud Run

- [ ] Projet Google Cloud sélectionné
- [ ] gcloud CLI installé et configuré
- [ ] Déploiement exécuté sans erreurs
- [ ] URL Cloud Run donnée et accessible

## ✅ Tests finaux

- [ ] `/api/health` fonctionne
- [ ] `/api/stats` retourne des données
- [ ] `/api/feedbacks` paginé correctement
- [ ] Filtres fonctionnent (`/api/feedbacks-by-user/...`)

---

**Une fois tout ✅, votre API est prête pour la production!** 🚀

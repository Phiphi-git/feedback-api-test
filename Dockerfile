# Utiliser l'image Node.js officielle
FROM node:18-slim

# Définir le répertoire de travail
WORKDIR /app

# Copier les fichiers de dépendances
COPY package*.json ./

# Installer les dépendances de production
RUN npm ci --only=production

# Copier le code de l'application
COPY index.js .

# Cloud Run utilise le port 8080 par défaut
ENV PORT=8080

# Exposer le port
EXPOSE 8080

# Démarrer l'application
CMD ["node", "index.js"]

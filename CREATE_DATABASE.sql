-- Utiliser la base de données test (déjà existante)
USE test;

-- Créer la table raw_feedback si elle n'existe pas
CREATE TABLE IF NOT EXISTS raw_feedback (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(255) NOT NULL,
    feedback_date DATE,
    campaign_id VARCHAR(50),
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_username (username),
    INDEX idx_campaign (campaign_id),
    INDEX idx_date (feedback_date)
);

-- Migration pour créer la table crash_reports
-- Date: 2025-08-30
-- Description: Table pour stocker les rapports de crash de l'application

-- Créer la table crash_reports
CREATE TABLE IF NOT EXISTS crash_reports (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    crash_type TEXT NOT NULL,
    error_message TEXT NOT NULL,
    stack_trace TEXT,
    context_info TEXT,
    library TEXT,
    platform TEXT,
    app_version TEXT,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status TEXT NOT NULL DEFAULT 'new' CHECK (status IN ('new', 'investigating', 'resolved', 'ignored')),
    severity TEXT NOT NULL DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    resolved_at TIMESTAMPTZ,
    resolution TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Créer les index pour optimiser les requêtes
CREATE INDEX IF NOT EXISTS idx_crash_reports_user_id ON crash_reports(user_id);
CREATE INDEX IF NOT EXISTS idx_crash_reports_crash_type ON crash_reports(crash_type);
CREATE INDEX IF NOT EXISTS idx_crash_reports_status ON crash_reports(status);
CREATE INDEX IF NOT EXISTS idx_crash_reports_severity ON crash_reports(severity);
CREATE INDEX IF NOT EXISTS idx_crash_reports_timestamp ON crash_reports(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_crash_reports_created_at ON crash_reports(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_crash_reports_platform ON crash_reports(platform);

-- Index composé pour les requêtes fréquentes
CREATE INDEX IF NOT EXISTS idx_crash_reports_status_severity ON crash_reports(status, severity);
CREATE INDEX IF NOT EXISTS idx_crash_reports_type_timestamp ON crash_reports(crash_type, timestamp DESC);

-- Trigger pour mettre à jour updated_at automatiquement
CREATE OR REPLACE FUNCTION update_crash_reports_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_crash_reports_updated_at
    BEFORE UPDATE ON crash_reports
    FOR EACH ROW
    EXECUTE FUNCTION update_crash_reports_updated_at();

-- Activer RLS (Row Level Security)
ALTER TABLE crash_reports ENABLE ROW LEVEL SECURITY;

-- Politique pour permettre aux utilisateurs de voir leurs propres crashes
CREATE POLICY "Users can view own crash reports" ON crash_reports
    FOR SELECT USING (auth.uid() = user_id);

-- Politique pour permettre aux utilisateurs d'insérer leurs propres crashes
CREATE POLICY "Users can insert own crash reports" ON crash_reports
    FOR INSERT WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

-- Politique pour les admins (supposant un rôle admin ou une table admin_users)
-- Les admins peuvent tout voir et modifier
CREATE POLICY "Admins can manage all crash reports" ON crash_reports
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );

-- Politique pour permettre l'insertion de crashes système (sans user_id)
CREATE POLICY "Allow system crash reports" ON crash_reports
    FOR INSERT WITH CHECK (user_id IS NULL);

-- Commentaires pour documenter la table
COMMENT ON TABLE crash_reports IS 'Table pour stocker les rapports de crash de l''application';
COMMENT ON COLUMN crash_reports.id IS 'Identifiant unique du rapport de crash';
COMMENT ON COLUMN crash_reports.user_id IS 'ID de l''utilisateur concerné (peut être null pour les crashes système)';
COMMENT ON COLUMN crash_reports.crash_type IS 'Type de crash (flutter_error, dart_error, etc.)';
COMMENT ON COLUMN crash_reports.error_message IS 'Message d''erreur principal';
COMMENT ON COLUMN crash_reports.stack_trace IS 'Stack trace complète de l''erreur';
COMMENT ON COLUMN crash_reports.context_info IS 'Informations contextuelles supplémentaires';
COMMENT ON COLUMN crash_reports.library IS 'Librairie ou composant concerné';
COMMENT ON COLUMN crash_reports.platform IS 'Plateforme (android, ios, web, etc.)';
COMMENT ON COLUMN crash_reports.app_version IS 'Version de l''application';
COMMENT ON COLUMN crash_reports.timestamp IS 'Horodatage du crash';
COMMENT ON COLUMN crash_reports.status IS 'Statut du rapport (new, investigating, resolved, ignored)';
COMMENT ON COLUMN crash_reports.severity IS 'Sévérité du crash (low, medium, high, critical)';
COMMENT ON COLUMN crash_reports.resolved_at IS 'Date de résolution du crash';
COMMENT ON COLUMN crash_reports.resolution IS 'Description de la résolution';
COMMENT ON COLUMN crash_reports.metadata IS 'Métadonnées supplémentaires en JSON';

-- Fonction pour nettoyer automatiquement les anciens rapports de crash
CREATE OR REPLACE FUNCTION cleanup_old_crash_reports(days_to_keep INTEGER DEFAULT 90)
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM crash_reports 
    WHERE created_at < NOW() - INTERVAL '1 day' * days_to_keep;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    -- Log l'action de nettoyage
    INSERT INTO audit_logs (action, table_name, details, created_at)
    VALUES (
        'cleanup_old_crash_reports',
        'crash_reports',
        jsonb_build_object(
            'deleted_count', deleted_count,
            'days_kept', days_to_keep,
            'cutoff_date', NOW() - INTERVAL '1 day' * days_to_keep
        ),
        NOW()
    );
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour obtenir les statistiques de crash
CREATE OR REPLACE FUNCTION get_crash_statistics(
    start_date TIMESTAMPTZ DEFAULT NOW() - INTERVAL '30 days',
    end_date TIMESTAMPTZ DEFAULT NOW()
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_crashes', COUNT(*),
        'crashes_by_type', jsonb_object_agg(crash_type, type_count),
        'crashes_by_severity', jsonb_object_agg(severity, severity_count),
        'crashes_by_status', jsonb_object_agg(status, status_count),
        'period_start', start_date,
        'period_end', end_date
    ) INTO result
    FROM (
        SELECT 
            crash_type,
            severity,
            status,
            COUNT(*) OVER (PARTITION BY crash_type) as type_count,
            COUNT(*) OVER (PARTITION BY severity) as severity_count,
            COUNT(*) OVER (PARTITION BY status) as status_count
        FROM crash_reports
        WHERE timestamp BETWEEN start_date AND end_date
    ) stats;
    
    RETURN COALESCE(result, '{}'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Vue pour les statistiques de crash en temps réel
CREATE OR REPLACE VIEW crash_reports_stats AS
SELECT 
    DATE_TRUNC('day', timestamp) as crash_date,
    crash_type,
    severity,
    status,
    platform,
    COUNT(*) as crash_count,
    COUNT(DISTINCT user_id) as affected_users
FROM crash_reports
WHERE timestamp >= NOW() - INTERVAL '30 days'
GROUP BY DATE_TRUNC('day', timestamp), crash_type, severity, status, platform
ORDER BY crash_date DESC, crash_count DESC;

-- Accorder les permissions appropriées
GRANT SELECT ON crash_reports_stats TO authenticated;
GRANT EXECUTE ON FUNCTION get_crash_statistics TO authenticated;
GRANT EXECUTE ON FUNCTION cleanup_old_crash_reports TO authenticated;

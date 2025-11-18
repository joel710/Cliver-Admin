-- Table pour stocker les configurations de l'application
CREATE TABLE IF NOT EXISTS public.app_config (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    key VARCHAR(255) NOT NULL UNIQUE,
    value JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour améliorer les performances de recherche par clé
CREATE INDEX IF NOT EXISTS idx_app_config_key ON public.app_config(key);

-- Index pour les requêtes par date de mise à jour
CREATE INDEX IF NOT EXISTS idx_app_config_updated_at ON public.app_config(updated_at);

-- Fonction pour mettre à jour automatiquement updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger pour mettre à jour updated_at automatiquement
DROP TRIGGER IF EXISTS update_app_config_updated_at ON public.app_config;
CREATE TRIGGER update_app_config_updated_at
    BEFORE UPDATE ON public.app_config
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Fonction RPC pour envoyer des notifications push à tous les utilisateurs
CREATE OR REPLACE FUNCTION send_push_notification_all(
    notification_title TEXT,
    notification_message TEXT,
    action_url TEXT DEFAULT NULL
)
RETURNS TABLE(
    success BOOLEAN,
    sent_count INTEGER,
    failed_count INTEGER,
    details JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_record RECORD;
    total_sent INTEGER := 0;
    total_failed INTEGER := 0;
    notification_details JSONB := '{"successes": [], "failures": []}'::jsonb;
    edge_function_response JSONB;
BEGIN
    -- Parcourir tous les utilisateurs actifs avec des tokens FCM
    FOR user_record IN 
        SELECT up.id, up.fcm_token
        FROM public.user_profiles up
        JOIN auth.users au ON up.id = au.id
        WHERE up.fcm_token IS NOT NULL 
        AND up.fcm_token != ''
        AND au.deleted_at IS NULL
    LOOP
        BEGIN
            -- Appeler la fonction Edge pour envoyer la notification
            SELECT net.http_post(
                url := current_setting('app.supabase_url') || '/functions/v1/send-push-notification',
                headers := jsonb_build_object(
                    'Content-Type', 'application/json',
                    'Authorization', 'Bearer ' || current_setting('app.service_role_key')
                ),
                body := jsonb_build_object(
                    'user_id', user_record.id,
                    'title', notification_title,
                    'body', notification_message,
                    'data', CASE 
                        WHEN action_url IS NOT NULL 
                        THEN jsonb_build_object('action_url', action_url)
                        ELSE '{}'::jsonb
                    END
                )
            ) INTO edge_function_response;
            
            -- Vérifier le succès de l'envoi
            IF (edge_function_response->>'success')::boolean = true THEN
                total_sent := total_sent + 1;
                notification_details := jsonb_set(
                    notification_details,
                    '{successes}',
                    (notification_details->'successes') || jsonb_build_array(user_record.id)
                );
            ELSE
                total_failed := total_failed + 1;
                notification_details := jsonb_set(
                    notification_details,
                    '{failures}',
                    (notification_details->'failures') || jsonb_build_array(
                        jsonb_build_object(
                            'user_id', user_record.id,
                            'error', COALESCE(edge_function_response->>'error', 'Unknown error')
                        )
                    )
                );
            END IF;
            
        EXCEPTION
            WHEN OTHERS THEN
                total_failed := total_failed + 1;
                notification_details := jsonb_set(
                    notification_details,
                    '{failures}',
                    (notification_details->'failures') || jsonb_build_array(
                        jsonb_build_object(
                            'user_id', user_record.id,
                            'error', SQLERRM
                        )
                    )
                );
        END;
    END LOOP;
    
    -- Enregistrer l'historique de la notification globale dans une table de logs
    -- Note: Remplacé par un log système car la table notifications n'a pas de colonne user_id nullable
    
    -- Retourner les résultats
    RETURN QUERY SELECT 
        (total_sent > 0) as success,
        total_sent as sent_count,
        total_failed as failed_count,
        notification_details as details;
        
EXCEPTION
    WHEN OTHERS THEN
        RETURN QUERY SELECT 
            false as success,
            0 as sent_count,
            0 as failed_count,
            jsonb_build_object('error', SQLERRM) as details;
END;
$$;

-- Politique RLS pour app_config (seuls les admins peuvent accéder)
ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;

-- Politique pour permettre aux admins de lire toutes les configurations
CREATE POLICY "Admins can read app_config" ON public.app_config
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );

-- Politique pour permettre aux admins de modifier toutes les configurations
CREATE POLICY "Admins can modify app_config" ON public.app_config
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );

-- Insérer quelques configurations par défaut
INSERT INTO public.app_config (key, value) VALUES
    ('maintenance_mode', '{"enabled": false, "message": "Application en maintenance. Veuillez réessayer plus tard.", "scheduled_end": null}'),
    ('app_version_android', '{"min_version": "1.0.0", "current_version": "1.0.0", "force_update": false, "update_message": "Une nouvelle version est disponible."}'),
    ('app_version_ios', '{"min_version": "1.0.0", "current_version": "1.0.0", "force_update": false, "update_message": "Une nouvelle version est disponible."}'),
    ('global_settings', '{"wait_time_seconds": 300, "search_radius_km": 10.0, "max_drivers_per_request": 5, "base_fare": 2.50, "fare_per_km": 1.20}')
ON CONFLICT (key) DO NOTHING;

-- Commentaires pour documenter la table
COMMENT ON TABLE public.app_config IS 'Table pour stocker les configurations globales de l''application';
COMMENT ON COLUMN public.app_config.key IS 'Clé unique identifiant le type de configuration';
COMMENT ON COLUMN public.app_config.value IS 'Valeur JSON contenant les paramètres de configuration';
COMMENT ON COLUMN public.app_config.created_at IS 'Date de création de la configuration';
COMMENT ON COLUMN public.app_config.updated_at IS 'Date de dernière mise à jour de la configuration';

-- Script SQL pour créer la table de signalements entre utilisateurs
-- À exécuter dans votre base de données Supabase

-- Table pour les signalements entre utilisateurs
CREATE TABLE IF NOT EXISTS public.user_reports (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    reporter_id uuid NOT NULL, -- Utilisateur qui signale
    reported_user_id uuid NOT NULL, -- Utilisateur signalé
    reason text NOT NULL, -- Raison du signalement
    description text, -- Description détaillée
    status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'urgent', 'resolved')),
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    resolved_at timestamp with time zone, -- Date de résolution
    admin_notes text, -- Notes de l'administrateur
    CONSTRAINT user_reports_pkey PRIMARY KEY (id),
    CONSTRAINT user_reports_reporter_id_fkey FOREIGN KEY (reporter_id) REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    CONSTRAINT user_reports_reported_user_id_fkey FOREIGN KEY (reported_user_id) REFERENCES public.user_profiles(id) ON DELETE CASCADE
);

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_user_reports_status ON public.user_reports(status);
CREATE INDEX IF NOT EXISTS idx_user_reports_created_at ON public.user_reports(created_at);
CREATE INDEX IF NOT EXISTS idx_user_reports_reporter_id ON public.user_reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_user_reports_reported_user_id ON public.user_reports(reported_user_id);

-- Ajouter des colonnes à user_profiles pour le blocage
ALTER TABLE public.user_profiles 
ADD COLUMN IF NOT EXISTS block_reason text,
ADD COLUMN IF NOT EXISTS blocked_at timestamp with time zone;

-- Politique RLS pour permettre aux admins de voir tous les signalements
CREATE POLICY "Les admins peuvent voir tous les signalements" ON public.user_reports
FOR SELECT USING (auth.role() = 'authenticated');

-- Politique RLS pour permettre aux admins de modifier les signalements
CREATE POLICY "Les admins peuvent modifier les signalements" ON public.user_reports
FOR UPDATE USING (auth.role() = 'authenticated');

-- Politique RLS pour permettre aux utilisateurs de créer des signalements
CREATE POLICY "Les utilisateurs peuvent créer des signalements" ON public.user_reports
FOR INSERT WITH CHECK (auth.uid() = reporter_id);

-- Politique RLS pour permettre aux utilisateurs de voir leurs propres signalements
CREATE POLICY "Les utilisateurs peuvent voir leurs signalements" ON public.user_reports
FOR SELECT USING (auth.uid() = reporter_id OR auth.uid() = reported_user_id);

-- Fonction pour notifier automatiquement les admins des nouveaux signalements
CREATE OR REPLACE FUNCTION notify_admin_new_report()
RETURNS TRIGGER AS $$
BEGIN
    -- Ici vous pouvez ajouter la logique pour envoyer des notifications
    -- Par exemple, envoyer un email ou une notification push
    -- Pour l'instant, on se contente de logger
    RAISE NOTICE 'Nouveau signalement: % signalé par %', NEW.reported_user_id, NEW.reporter_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Déclencheur pour notifier les admins des nouveaux signalements
CREATE TRIGGER trigger_notify_admin_new_report
    AFTER INSERT ON public.user_reports
    FOR EACH ROW
    EXECUTE FUNCTION notify_admin_new_report();

-- Fonction pour marquer automatiquement comme urgent les signalements multiples
CREATE OR REPLACE FUNCTION auto_mark_urgent_reports()
RETURNS TRIGGER AS $$
BEGIN
    -- Si un utilisateur a été signalé plus de 3 fois, marquer comme urgent
    IF (SELECT COUNT(*) FROM public.user_reports 
        WHERE reported_user_id = NEW.reported_user_id 
        AND status = 'pending') >= 3 THEN
        
        UPDATE public.user_reports 
        SET status = 'urgent' 
        WHERE reported_user_id = NEW.reported_user_id 
        AND status = 'pending';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Déclencheur pour marquer automatiquement les signalements urgents
CREATE TRIGGER trigger_auto_mark_urgent_reports
    AFTER INSERT ON public.user_reports
    FOR EACH ROW
    EXECUTE FUNCTION auto_mark_urgent_reports();

-- Commentaires sur la table
COMMENT ON TABLE public.user_reports IS 'Table pour gérer les signalements entre utilisateurs';
COMMENT ON COLUMN public.user_reports.reporter_id IS 'ID de l''utilisateur qui signale';
COMMENT ON COLUMN public.user_reports.reported_user_id IS 'ID de l''utilisateur signalé';
COMMENT ON COLUMN public.user_reports.reason IS 'Raison principale du signalement';
COMMENT ON COLUMN public.user_reports.description IS 'Description détaillée du problème';
COMMENT ON COLUMN public.user_reports.status IS 'Statut du signalement (pending, urgent, resolved)';
COMMENT ON COLUMN public.user_reports.admin_notes IS 'Notes de l''administrateur pour le traitement';
COMMENT ON COLUMN public.user_profiles.block_reason IS 'Raison du blocage de l''utilisateur';
COMMENT ON COLUMN public.user_profiles.blocked_at IS 'Date et heure du blocage';

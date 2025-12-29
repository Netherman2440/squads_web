-- Add ranking settings columns to squads table
ALTER TABLE public.squads
ADD COLUMN ranking_update BOOLEAN NOT NULL DEFAULT TRUE,
ADD COLUMN ranking_multiplier NUMERIC(3,1) NOT NULL DEFAULT 1.0,
ADD COLUMN use_experience_factor BOOLEAN NOT NULL DEFAULT TRUE;

COMMENT ON COLUMN public.squads.ranking_update IS 'If false, matches in this squad do not affect player ranking.';
COMMENT ON COLUMN public.squads.ranking_multiplier IS 'Multiplier for ranking change calculation (e.g. 0.5, 1.0, 2.0).';
COMMENT ON COLUMN public.squads.use_experience_factor IS 'If true, reduces ranking change for experienced players vs new players.';



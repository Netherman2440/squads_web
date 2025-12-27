-- Drop existing score_history table if it exists
DROP TABLE IF EXISTS public.score_history CASCADE;

-- Create ranking_history table
CREATE TABLE public.ranking_history (
    ranking_history_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id UUID NOT NULL,
    match_id UUID NULL,
    ranking NUMERIC(6,3) NOT NULL,
    change NUMERIC(6,3) NULL,
    match_score JSONB NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NULL,

    CONSTRAINT ranking_history_player_fk
        FOREIGN KEY (player_id)
        REFERENCES public.players (player_id)
        ON DELETE CASCADE,

    CONSTRAINT ranking_history_match_fk
        FOREIGN KEY (match_id)
        REFERENCES public.matches (match_id)
        ON DELETE SET NULL
);

-- Partial unique index: one ranking_history entry per player per match
CREATE UNIQUE INDEX ranking_history_player_match_unique_idx 
    ON public.ranking_history (player_id, match_id) 
    WHERE match_id IS NOT NULL;

-- Index for fast history lookups
CREATE INDEX ranking_history_player_idx ON public.ranking_history (player_id);

-- Index for match details lookup
CREATE INDEX ranking_history_match_idx ON public.ranking_history (match_id) WHERE match_id IS NOT NULL;

-- Documentation
COMMENT ON TABLE public.ranking_history IS 'Stores the history of player ranking changes, both manual and from matches.';
COMMENT ON COLUMN public.ranking_history.ranking IS 'The snapshot of the player''s ranking BEFORE the change was applied.';
COMMENT ON COLUMN public.ranking_history.change IS 'The delta applied to the ranking. NULL if the match result is pending.';
COMMENT ON COLUMN public.ranking_history.match_score IS 'JSONB snapshot of the match score: {"player": int, "opponent": int}.';


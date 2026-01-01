-- Convert squad ranking_multiplier to integer factor 1..10 (default 5)
-- and drop mistakenly introduced experience_factor_value (if present).

ALTER TABLE public.squads
DROP COLUMN IF EXISTS experience_factor_value;

ALTER TABLE public.squads
ALTER COLUMN ranking_multiplier DROP DEFAULT;

-- Convert numeric -> integer using rounding, then clamp via check constraint.
ALTER TABLE public.squads
ALTER COLUMN ranking_multiplier TYPE INTEGER
USING ROUND(ranking_multiplier)::INTEGER;

ALTER TABLE public.squads
ALTER COLUMN ranking_multiplier SET DEFAULT 5;

ALTER TABLE public.squads
ADD CONSTRAINT squads_ranking_multiplier_1_10
CHECK (ranking_multiplier BETWEEN 1 AND 10);

COMMENT ON COLUMN public.squads.ranking_multiplier IS
  'Ranking change factor (1..10). Used as: delta = goalDiff * ranking_multiplier.';



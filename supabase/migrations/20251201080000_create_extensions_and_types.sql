-- ###########################################################################
-- Migration: create core extensions and types
-- Purpose:
--   - Ensure pgcrypto is available for UUID generation.
--   - Define shared enums/composite types in public schema.
-- ###########################################################################

create extension if not exists pgcrypto with schema public;

create type public.squad_visibility as enum ('public', 'private');

create type public.sport_type as enum ('football');

create type public.user_squad_role as enum (
  'owner',
  'admin',
  'member',
  'invited',
  'pending',
  'removed',
  'declined'
);

create type public.side_enum as enum ('home', 'away');

create type public.match_score_type as enum (
  'regular',
  'penalties',
  'walkover',
  'cancelled'
);

create type public.score_pair as (
  home smallint,
  away smallint
);

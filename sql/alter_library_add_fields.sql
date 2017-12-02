-- new fields to library

ALTER TABLE public.library
   ADD COLUMN properties jsonb;

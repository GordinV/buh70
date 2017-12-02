
ALTER TABLE docs.arv1
   ADD COLUMN kbm_maar text;
COMMENT ON COLUMN docs.arv1.kbm_maar
  IS 'Käibemaksu määr (0, 5, 9, 20)';

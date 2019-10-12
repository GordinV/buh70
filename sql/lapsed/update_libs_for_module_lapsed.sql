UPDATE libs.library
SET properties = properties::JSONB || '{"module":["Raamatupidamine","Lapsed"]}'
WHERE library = 'DOK'
  AND kood IN ('ARV','SORDER','SMK','NOMENCLATURE','TUNNUS','ASUTUSED');

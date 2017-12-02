ALTER TABLE docs.doc ADD COLUMN rigths jsonb;
COMMENT ON COLUMN docs.doc.rigths  IS 'Права пользователей на доступ к документам';

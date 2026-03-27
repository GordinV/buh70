CREATE OR REPLACE FUNCTION docs.refresh_kaibed_public()
    RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW docs.kaibed;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION docs.refresh_kaibed_public() TO PUBLIC;
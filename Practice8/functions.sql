CREATE OR REPLACE FUNCTION find_contacts(p_pattern TEXT)
RETURNS TABLE (
    id BIGINT,
    name VARCHAR,
    phone VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT c.id, c.name, c.phone
    FROM contacts AS c
    WHERE c.name ILIKE '%' || COALESCE(p_pattern, '') || '%'
       OR c.phone ILIKE '%' || COALESCE(p_pattern, '') || '%'
    ORDER BY c.name, c.id;
END;
$$;

CREATE OR REPLACE FUNCTION get_contacts_page(
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id BIGINT,
    name VARCHAR,
    phone VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_limit IS NULL OR p_limit < 1 THEN
        RAISE EXCEPTION 'Limit must be a positive integer';
    END IF;
    IF p_offset IS NULL OR p_offset < 0 THEN
        RAISE EXCEPTION 'Offset must be zero or greater';
    END IF;

    RETURN QUERY
    SELECT c.id, c.name, c.phone
    FROM contacts AS c
    ORDER BY c.id
    LIMIT p_limit
    OFFSET p_offset;
END;
$$;

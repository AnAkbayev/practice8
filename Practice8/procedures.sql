CREATE OR REPLACE PROCEDURE upsert_contact(
    IN p_name VARCHAR,
    IN p_phone VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_name IS NULL OR BTRIM(p_name) = '' THEN
        RAISE EXCEPTION 'Name must not be empty';
    END IF;
    IF p_phone IS NULL OR p_phone !~ '^\+?[0-9]{7,15}$' THEN
        RAISE EXCEPTION 'Phone must contain an optional leading + followed by 7 to 15 digits';
    END IF;

    INSERT INTO contacts (name, phone)
    VALUES (BTRIM(p_name), p_phone)
    ON CONFLICT (name) DO UPDATE
       SET phone = EXCLUDED.phone,
           updated_at = CURRENT_TIMESTAMP;
END;
$$;

CREATE OR REPLACE PROCEDURE bulk_upsert_contacts(
    IN p_names TEXT[],
    IN p_phones TEXT[],
    INOUT p_invalid JSONB
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_index INTEGER;
    v_count INTEGER;
    v_name TEXT;
    v_phone TEXT;
    v_reason TEXT;
BEGIN
    p_invalid := COALESCE(p_invalid, '[]'::JSONB);
    v_count := GREATEST(
        COALESCE(array_length(p_names, 1), 0),
        COALESCE(array_length(p_phones, 1), 0)
    );

    IF v_count > 0 THEN
        FOR v_index IN 1..v_count LOOP
            v_name := p_names[v_index];
            v_phone := p_phones[v_index];
            v_reason := NULL;

            IF v_name IS NULL OR BTRIM(v_name) = '' THEN
                v_reason := 'Name must not be empty';
            ELSIF v_phone IS NULL OR v_phone !~ '^\+?[0-9]{7,15}$' THEN
                v_reason := 'Phone must contain an optional leading + followed by 7 to 15 digits';
            END IF;

            IF v_reason IS NOT NULL THEN
                p_invalid := p_invalid || jsonb_build_array(
                    jsonb_build_object(
                        'row', v_index,
                        'name', v_name,
                        'phone', v_phone,
                        'reason', v_reason
                    )
                );
            ELSE
                INSERT INTO contacts (name, phone)
                VALUES (BTRIM(v_name), v_phone)
                ON CONFLICT (name) DO UPDATE
                   SET phone = EXCLUDED.phone,
                       updated_at = CURRENT_TIMESTAMP;
            END IF;
        END LOOP;
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE delete_contact(IN p_username_or_phone TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_username_or_phone IS NULL OR BTRIM(p_username_or_phone) = '' THEN
        RAISE EXCEPTION 'Provide a username or phone number';
    END IF;

    DELETE FROM contacts
    WHERE name = BTRIM(p_username_or_phone)
       OR phone = BTRIM(p_username_or_phone);
END;
$$;

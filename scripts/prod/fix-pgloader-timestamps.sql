-- Tras migración MariaDB→PostgreSQL (pgloader), Frappe falla en migrate con:
-- TypeError: can't compare offset-naive and offset-aware datetimes
DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT table_name, column_name
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND column_name IN ('creation', 'modified')
      AND data_type = 'timestamp with time zone'
  LOOP
    EXECUTE format(
      'ALTER TABLE %I ALTER COLUMN %I TYPE timestamp without time zone USING %I AT TIME ZONE ''UTC''',
      r.table_name, r.column_name, r.column_name
    );
  END LOOP;
END $$;

CREATE OR REPLACE FUNCTION cons(TEXT, INTEGER)
RETURNS INTEGER AS $$
DECLARE
  key ALIAS FOR $2;
  value ALIAS FOR $1;
BEGIN
  CREATE TABLE IF NOT EXISTS "__cons" (
    "key" INTEGER PRIMARY KEY NOT NULL,
    "value" TEXT NOT NULL,
    "nextKey" INTEGER REFERENCES "__cons" ("key")
  );

  INSERT INTO "__cons" ("value", "nextKey")
  VALUES (value,key)
  RETURNING "key";
END;
$$ LANGUAGE plpgsql;

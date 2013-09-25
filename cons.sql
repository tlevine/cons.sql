CREATE OR REPLACE FUNCTION cons(TEXT, INTEGER)
RETURNS INTEGER AS $$
DECLARE
  nextKey ALIAS FOR $2;
  value ALIAS FOR $1;
BEGIN
  CREATE TABLE IF NOT EXISTS "__cons" (
    "thisKey" INTEGER PRIMARY KEY NOT NULL,
    "value" TEXT NOT NULL,
    "nextKey" INTEGER REFERENCES "__cons" ("thisKey")
  );

  INSERT INTO "__cons" ("value", "nextKey")
  VALUES (value, nextKkey)
  RETURNING "thisKey";
END;
$$ LANGUAGE plpgsql;

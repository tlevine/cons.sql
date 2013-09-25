CREATE FUNCTION cons(value, key) RETURNS integer AS $$
BEGIN
  CREATE TABLE IF NOT EXISTS "__cons" (
    "key" INTEGER PRIMARY KEY NOT NULL,
    "value" TEXT NOT NULL,
    "nextKey" INTEGER REFERENCES "__cons" ("key"),
  );

  INSERT INTO "__cons" ("value", "nextKey")
  VALUES (value,key)
  RETURNING "key";
END;
$$ LANGUAGE plpgsql;

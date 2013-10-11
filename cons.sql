DROP TABLE IF EXISTS "__cons";
CREATE TABLE "__cons" (
  "thisKey" SERIAL PRIMARY KEY NOT NULL,
  "value" TEXT NOT NULL,
  "nextKey" INTEGER -- REFERENCES "__cons" ("thisKey")
);

CREATE OR REPLACE FUNCTION cons(TEXT, INTEGER)
RETURNS INTEGER AS $$
DECLARE
  nextKey ALIAS FOR $2;
  value ALIAS FOR $1;
BEGIN
  INSERT INTO "__cons" ("value", "nextKey")
  VALUES (value, nextKey);

  -- http://stackoverflow.com/questions/2944297/postgresql-function-for-last-inserted-id
  RETURN LASTVAL();
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION head(INTEGER)
RETURNS TEXT AS $$
DECLARE
  thisKey ALIAS FOR $1;
BEGIN
  RETURN (
    SELECT _head(' ', thisKey)
  );
END;
$$ LANGUAGE plpgsql;

-- DROP TYPE IF EXISTS NECK;
CREATE TYPE NECK AS (values TEXT, nextKey INTEGER);

CREATE OR REPLACE FUNCTION _head(TEXT, INTEGER)
RETURNS NECK AS $$
DECLARE
  prevValues ALIAS FOR $1;
  thisKey ALIAS FOR $2;
BEGIN
  RETURN (
    SELECT
      "prevValues" || ' ' || (SELECT "value" FROM "__cons" WHERE "thisKey" = thisKey),
      _head(SELECT "nextKey" FROM "__cons" WHERE "thisKey" = thisKey);
  );
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION last(INTEGER)
RETURNS TEXT AS $$
DECLARE
  thisKey ALIAS FOR $1;
  nextKey INTEGER := (SELECT "nextKey" FROM "__cons" WHERE "thisKey" = thisKey);
BEGIN
  IF nextKey IS NULL THEN
    RETURN (SELECT "value" FROM "__cons" WHERE "thisKey" = thisKey);
  ELSE
    RETURN (SELECT 'aou');
  END IF;
END;
$$ LANGUAGE plpgsql;



-- select cons('abc', cons('ggg', cons('zzz', NULL)));
-- select * from "__cons";
-- select head(2);
-- select last(0);
-- select last(2);

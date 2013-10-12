DROP TABLE IF EXISTS "__memory";
CREATE TABLE IF NOT EXISTS "__memory" (
  "thisKey" SERIAL PRIMARY KEY NOT NULL,
  "value" TEXT NOT NULL,
  "nextKey" INTEGER -- REFERENCES "__memory" ("thisKey")
);

CREATE OR REPLACE FUNCTION cons(TEXT, INTEGER)
RETURNS INTEGER AS $$
DECLARE
  nextKey ALIAS FOR $2;
  value ALIAS FOR $1;
BEGIN
  INSERT INTO "__memory" ("value", "nextKey")
  VALUES (value, nextKey);

  -- http://stackoverflow.com/questions/2944297/postgresql-function-for-last-inserted-id
  RETURN LASTVAL();
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION head(INTEGER)
RETURNS INTEGER AS $$
DECLARE
  key ALIAS FOR $1;
BEGIN
  INSERT INTO "__memory" ("value","nextKey")
    SELECT "value", NULL
    FROM "__memory"
    WHERE "thisKey" = key;
  RETURN LASTVAL();
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION tail(INTEGER)
RETURNS INTEGER AS $$
DECLARE
  key ALIAS FOR $1;
  result INTEGER;
BEGIN
  SELECT cons(
    (SELECT "value" FROM "__memory" WHERE "thisKey" = key),
    (SELECT "nextKey" FROM "__memory" WHERE "thisKey" = key)
  ) INTO result;
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- CREATE OR REPLACE FUNCTION init(INTEGER)
-- RETURNS INTEGER AS $$
-- DECLARE
--   key ALIAS FOR $1;
-- BEGIN
-- RETURN LASTVAL();
-- END;
-- $$ LANGUAGE plpgsql;

-- DROP FUNCTION take(TAKING);
-- CREATE TYPE TAKING (INTEGER, INTEGER);
-- CREATE OR REPLACE FUNCTION take(TAKING)
-- RETURNS TAKING AS $$
-- DECLARE
--   inputs ALIAS FOR $1;
--   result TAKING;
-- BEGIN
--   SELECT cons( (SELECT "value" FROM "__memory" WHERE "thisKey" = key),
--                (SELECT "nextKey" FROM "__memory" WHERE "thisKey" = key))
--   INTO result.key;
--   RETURN (result, toGo - 1);
-- END;
-- $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION drop(INTEGER, INTEGER)
RETURNS INTEGER AS $$
DECLARE
  key ALIAS FOR $1;
  toDrop ALIAS FOR $2;
BEGIN
  IF toDrop > 0
  THEN
    RETURN drop((SELECT "nextKey" FROM "__memory" WHERE "thisKey" = key), toDrop - 1);
  ELSE
    RETURN key;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION init(INTEGER, INTEGER)
RETURNS INTEGER AS $$
DECLARE
  first ALIAS FOR $1;
  x ALIAS FOR $2;
  next INTEGER;
BEGIN
  SELECT "nextKey" FROM "__memory" WHERE "thisKey" = x INTO next;
  IF next IS NULL
  THEN
    RETURN NULL;
  ELSE
    RETURN cons((SELECT "value" FROM "__memory" WHERE "thisKey" = x), init(first, next));
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION init(INTEGER)
RETURNS INTEGER AS $$
BEGIN
  RETURN init($1, $1);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION copy(INTEGER, INTEGER)
RETURNS INTEGER AS $$
DECLARE
  first ALIAS FOR $1;
  x ALIAS FOR $2;
  thisValue TEXT;
  next INTEGER;
BEGIN
  SELECT "value" FROM "__memory" WHERE "thisKey" = x INTO thisValue;
  SELECT "nextKey" FROM "__memory" WHERE "thisKey" = x INTO next;
  IF next IS NULL
  THEN
    RETURN cons(thisValue, NULL);
  ELSE
    RETURN cons(thisValue, copy(first, next));
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION copy(INTEGER)
RETURNS INTEGER AS $$
BEGIN
  RETURN copy($1, $1);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION last(INTEGER)
RETURNS INTEGER AS $$
DECLARE
  key ALIAS FOR $1;
  next INTEGER;
BEGIN
  SELECT "nextKey" FROM "__memory" WHERE "thisKey" = key INTO next;
  IF next IS NULL
  THEN
    RETURN key;
  ELSE
    RETURN last(next);
  END IF;
END;
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS toColumn(INTEGER);

-- http://stackoverflow.com/questions/4279876/plpgsql-function-returns-table
-- CREATE OR REPLACE FUNCTION toColumn(startKey INTEGER)
-- RETURNS TABLE (key INTEGER) AS $$
--     SELECT "thisKey" FROM "__memory" WHERE "thisKey" = startKey
--   UNION ALL
--     SELECT "nextKey" FROM "__memory" WHERE "thisKey" = startKey AND "nextKey" IS NOT NULL;
-- $$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION cat(INTEGER, INTEGER)
RETURNS INTEGER AS $$
DECLARE
  first ALIAS FOR $1;
  firstCopy INTEGER;
  second ALIAS FOR $2;
BEGIN
  SELECT copy(first) INTO firstCopy;

  UPDATE "__memory"
    SET "nextKey" = second
    WHERE "thisKey" = last(firstCopy);

  RETURN firstCopy;
END;
$$ LANGUAGE plpgsql;

SELECT cons('a',cons('b',cons('c',cons('d',cons('e', NULL)))));
SELECT cons('foo',cons('bar',cons('baz', NULL)));
SELECT cons('i',cons('am',cons('a',cons('banana',NULL))));
SELECT head(4);
SELECT tail(5);
SELECT drop(5, 2);
SELECT init(4);
SELECT init(4);
SELECT last(4);
SELECT copy(4);
SELECT copy(4);
SELECT cat(8,4);

-- SELECT * FROM toColumn(5);
-- SELECT "thisKey" FROM "__memory";

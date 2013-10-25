DROP TABLE IF EXISTS "__cons";
CREATE TABLE IF NOT EXISTS "__cons" (
  "thisKey" SERIAL PRIMARY KEY NOT NULL,
  "value" TEXT NOT NULL,
  "nextKey" INTEGER -- REFERENCES "__cons" ("thisKey")
);

CREATE OR REPLACE FUNCTION cons(TEXT)
RETURNS INTEGER AS $$
BEGIN
  RETURN cons($1, NULL);
END;
$$ LANGUAGE plpgsql;

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
  key ALIAS FOR $1;
  result TEXT;
BEGIN
  SELECT "value", NULL
  FROM "__cons"
  WHERE "thisKey" = key
  INTO result;
  RETURN result;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION tail(INTEGER)
RETURNS INTEGER AS $$
DECLARE
  key ALIAS FOR $1;
  result INTEGER;
BEGIN
  SELECT "nextKey" FROM "__cons" WHERE "thisKey" = key INTO result;
  RETURN result;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION drop(INTEGER, INTEGER)
RETURNS INTEGER AS $$
DECLARE
  key ALIAS FOR $1;
  toDrop ALIAS FOR $2;
BEGIN
  IF toDrop > 0
  THEN
    RETURN drop((SELECT "nextKey" FROM "__cons" WHERE "thisKey" = key), toDrop - 1);
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
  SELECT "nextKey" FROM "__cons" WHERE "thisKey" = x INTO next;
  IF next IS NULL
  THEN
    RETURN NULL;
  ELSE
    RETURN cons((SELECT "value" FROM "__cons" WHERE "thisKey" = x), init(first, next));
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
  SELECT "value" FROM "__cons" WHERE "thisKey" = x INTO thisValue;
  SELECT "nextKey" FROM "__cons" WHERE "thisKey" = x INTO next;
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
RETURNS TEXT AS $$
DECLARE
  key INTEGER;
  result TEXT;
BEGIN
  SELECT lastkey($1) INTO key;

  SELECT "value"
  FROM "__cons"
  WHERE "thisKey" = key
  INTO result;

  RETURN result;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION lastkey(INTEGER)
RETURNS INTEGER AS $$
DECLARE
  key ALIAS FOR $1;
  next INTEGER;
BEGIN
  SELECT "nextKey" FROM "__cons" WHERE "thisKey" = key INTO next;
  IF next IS NULL
  THEN
    RETURN key;
  ELSE
    RETURN lastkey(next);
  END IF;
END;
$$ LANGUAGE plpgsql;

-- http://stackoverflow.com/questions/14628771/postgres-function-returning-table-not-returning-data-in-columns
CREATE OR REPLACE FUNCTION toColumn(INTEGER)
RETURNS TABLE(value TEXT) AS $$
DECLARE
  dummy TEXT := '';
  key INTEGER := $1;
BEGIN
  DROP TABLE IF EXISTS tbl;
  CREATE TEMP TABLE tbl AS SELECT dummy LIMIT 0;
  WHILE key IS NOT NULL LOOP
    INSERT INTO tbl SELECT "__cons"."value" FROM "__cons" WHERE "thisKey" = key;
    SELECT "nextKey" FROM "__cons" WHERE "thisKey" = key INTO key;
  END LOOP;
  RETURN QUERY SELECT * FROM tbl;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cat(INTEGER, INTEGER)
RETURNS INTEGER AS $$
DECLARE
  first ALIAS FOR $1;
  firstCopy INTEGER;
  second ALIAS FOR $2;
BEGIN
  SELECT copy(first) INTO firstCopy;

  UPDATE "__cons"
    SET "nextKey" = second
    WHERE "thisKey" = lastkey(firstCopy);

  RETURN firstCopy;
END;
$$ LANGUAGE plpgsql;

DROP TABLE IF EXISTS "__stack";
CREATE TABLE IF NOT EXISTS "__stack" (
  "id" SERIAL PRIMARY KEY NOT NULL,
  "list" INTEGER,
  FOREIGN KEY ("list") REFERENCES "__cons" ("thisKey")
);

CREATE OR REPLACE FUNCTION stack()
RETURNS INTEGER AS $$
BEGIN
  INSERT INTO "__stack" ("list") VALUES (NULL);
  RETURN LASTVAL();
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION push(INTEGER, TEXT)
RETURNS INTEGER AS $$
DECLARE
  stack ALIAS FOR $1;
  newValue ALIAS FOR $2;
  oldList INTEGER;
BEGIN
  SELECT "list" FROM "__stack" WHERE "id" = stack INTO oldList;
  INSERT INTO "__stack" ("list") SELECT cons(newValue, oldList);
  RETURN LASTVAL();
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION pop(INTEGER)
RETURNS INTEGER AS $$
DECLARE
  oldStack ALIAS FOR $1;
  oldList INTEGER;
  newStack INTEGER;
  newList INTEGER;
  value TEXT;
BEGIN
  SELECT "list" FROM "__stack" WHERE "id" = oldStack INTO oldList;
  SELECT "__cons"."value" FROM "__cons" WHERE "thisKey" = oldList INTO value;
  SELECT tail(oldList) INTO newList;
  INSERT INTO "__stack" ("list") VALUES (newList);
  SELECT LASTVAL() INTO newStack;
  RETURN newStack;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION peek(INTEGER)
RETURNS TEXT AS $$
BEGIN
  RETURN (
    SELECT "value"
    FROM "__stack"
    JOIN "__cons"
    ON "__stack"."id" = $1
    WHERE "__stack"."list" = "__cons"."thisKey"
  );
END;
$$ LANGUAGE plpgsql;

DROP TABLE IF EXISTS "__queue";
CREATE TABLE IF NOT EXISTS "__queue" (
  "id" SERIAL PRIMARY KEY NOT NULL,
  "left" INTEGER,
  "right" INTEGER,
  FOREIGN KEY ("left") REFERENCES "__stack" ("id"),
  FOREIGN KEY ("right") REFERENCES "__stack" ("id")
);

CREATE OR REPLACE FUNCTION enqueue(INTEGER, TEXT)
RETURNS INTEGER AS $$
DECLARE
  newValue ALIAS FOR $2;
  oldQueue ALIAS FOR $1;
  newQueue INTEGER;
  oldLeft INTEGER;
  oldRight INTEGER;
  newLeft INTEGER;
  newRight INTEGER;
BEGIN
  SELECT "left", "right"
  FROM "__queue"
  WHERE "id" = newQueue
  INTO oldLeft, oldRight;

  IF (SELECT peek(oldLeft)) IS NULL
  THEN
    SELECT queue() INTO newLeft;
    SELECT queue() INTO newRight;
    WHILE (SELECT peek(oldRight)) IS NOT NULL LOOP
      SELECT push(newLeft, peek(oldRight)) INTO newLeft;
      SELECT pop(oldRight) INTO oldRight;
    END LOOP;
  ELSE
    SELECT oldLeft INTO newLeft;
    SELECT push(oldRight, newValue) INTO newRight;
  END IF;
  INSERT INTO "__stack" ("left","right")
  VALUES (newLeft, newRight);
  RETURN LASTVAL();
END;
$$ LANGUAGE plpgsql;

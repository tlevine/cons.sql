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



select cons('abc', cons('ggg', cons('zzz', NULL)));
-- select "a"."value","b"."value" from __cons as a join __cons as b on "a"."nextKey" = "b"."thisKey" where "a"."thisKey" = 2;


CREATE OR REPLACE FUNCTION list(INTEGER)
RETURNS TEXT AS $$
DECLARE
  startKey ALIAS FOR $1;
BEGIN
RETURN
  WITH list AS (
      SELECT  "this"."value"
      FROM    "__cons" as this
      JOIN    "__cons" as next
      ON      "this"."nextKey" = "next"."thisKey"
      WHERE   "this"."thisKey" = startKey
  )
  SELECT  "value"
  FROM    list;
END;
$$ LANGUAGE plpgsql;

list(2)

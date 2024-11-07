DROP TABLE IF EXISTS t;

CREATE TABLE t (n UInt8) ENGINE=MergeTree ORDER BY n SAMPLE BY tuple(); -- { serverError INCORRECT_QUERY }

CREATE TABLE t (n UInt8) ENGINE=MergeTree ORDER BY tuple();

ALTER TABLE t MODIFY SAMPLE BY tuple(); -- { serverError INCORRECT_QUERY }

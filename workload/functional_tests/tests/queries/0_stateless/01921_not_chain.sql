-- { echo }
SELECT 1 != (NOT 1);
SELECT 1 != NOT 1;
EXPLAIN SYNTAX SELECT 1 != (NOT 1);
EXPLAIN SYNTAX SELECT 1 != NOT 1;

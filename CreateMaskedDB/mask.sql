use world;
SELECT * FROM city LIMIT 1;
SELECT * FROM country LIMIT 1;
UPDATE city SET Name = REPEAT('*', CHAR_LENGTH(Name));
UPDATE country SET Name = REPEAT('*', CHAR_LENGTH(Name));
SELECT * FROM city LIMIT 1;
SELECT * FROM country LIMIT 1;
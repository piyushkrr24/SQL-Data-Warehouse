-- Database: DataWarehouse

-- DROP DATABASE IF EXISTS "DataWarehouse";

CREATE DATABASE "DataWarehouse"
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'English_India.1252'
    LC_CTYPE = 'English_India.1252'
    LOCALE_PROVIDER = 'libc'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;


-- now i will create Schemas, (Bronze, Sliver, Gold)

CREATE SCHEMA bronze;
CREATE SCHEMA sliver;
CREATE SCHEMA gold;
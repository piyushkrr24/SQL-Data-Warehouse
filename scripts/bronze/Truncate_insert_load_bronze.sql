CALL bronze.load_bronze();
-- run this line only to run the whole below code


CREATE OR REPLACE PROCEDURE bronze.load_bronze()
LANGUAGE plpgsql
AS $$
BEGIN
	RAISE NOTICE 'LOADING BRONZE LAYER';
    RAISE NOTICE 'LOADING CRM';
	TRUNCATE TABLE bronze.crm_cust_info;

    COPY bronze.crm_cust_info
    FROM 'C:/Program Files/PostgreSQL/15/data/source_crm/cust_info.csv'
    CSV HEADER;

    TRUNCATE TABLE bronze.crm_prd_info;

    COPY bronze.crm_prd_info
    FROM 'C:/Program Files/PostgreSQL/15/data/source_crm/prd_info.csv'
    CSV HEADER;

    TRUNCATE TABLE bronze.crm_sales_details;

    COPY bronze.crm_sales_details
    FROM 'C:/Program Files/PostgreSQL/15/data/source_crm/sales_details.csv'
    CSV HEADER;

	RAISE NOTICE 'LOADING ERP';

    TRUNCATE TABLE bronze.erp_cust_az12;

    COPY bronze.erp_cust_az12
    FROM 'C:/Program Files/PostgreSQL/15/data/source_erp/CUST_AZ12.csv'
    CSV HEADER;

    TRUNCATE TABLE bronze.erp_loc_a101;

    COPY bronze.erp_loc_a101
    FROM 'C:/Program Files/PostgreSQL/15/data/source_erp/LOC_A101.csv'
    CSV HEADER;

    TRUNCATE TABLE bronze.erp_px_cat_g1v2;

    COPY bronze.erp_px_cat_g1v2
    FROM 'C:/Program Files/PostgreSQL/15/data/source_erp/PX_CAT_G1V2.csv'
    CSV HEADER;

	RAISE NOTICE 'LOADING COMPLETED';
END;
$$;


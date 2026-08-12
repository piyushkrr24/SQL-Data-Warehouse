-- SILVER LAYER (TRUNCATE AND INSERT LOAD)

-- DATA CLEANING
-- DATA STANDARDISATION
-- DATA NORMALIZATION
-- DERIVED COLUMN
-- DATA ENRICHMENT

CALL silver.load_silver();
-- run this line only to run the whole below code

CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE plpgsql
AS $$
BEGIN

	
	-- 1. crm_cust_info
	
	-- remove duplicate cst_id & null cst_id,
	-- trim values (check for extra spaces) for firstname and lastname, 
	-- F-Female, M-Male
	-- M-Married, S-Single
	truncate table silver.crm_cust_info;
	insert into silver.crm_cust_info(
		cst_id,
		cst_key, 
		cst_firstname,
		cst_lastname,
		cst_marital_status, 
		cst_gndr,
		cst_create_date
	)
	
	
	select t.cst_id, t.cst_key, 
		trim(t.cst_firstname) cst_firstname, 
		trim(t.cst_lastname) cst_lastname, 
		case 
			when upper(trim(t.cst_marital_status))='S' then 'Single'
			when upper(trim(t.cst_marital_status))='M' then 'Married'
			else 'n/a'
		end cst_marital_status,
		case 
			when upper(trim(t.cst_gndr))='F' then 'Female'
			when upper(trim(t.cst_gndr))='M' then 'Male'
			else 'n/a'
		end cst_gndr, 
		t.cst_create_date
	from(
		select * , row_number() over(partition by cst_id order by cst_create_date desc) flag_last
		from bronze.crm_cust_info
		where cst_id is not null
	) t
	where flag_last=1;
	
	
	
	-- select * from silver.crm_cust_info;
	
	
	
	
	
	-- 2. crm_prd_info
	
	-- in bronze.erp_px_cat_g1v2, id is first 5 char of prd_key, so created cat_id
	-- in bronze.crm_sales_details, sls_prd_key is (7 to length(prd_key)) of prd_key, so created cat_id
	-- in prd_cost made null =0
	-- wrote full name for prd_line
	truncate table silver.crm_prd_info;
	insert into silver.crm_prd_info (
	    prd_id,
	    cat_id,
	    prd_key,
	    prd_nm,
	    prd_cost,
	    prd_line,
	    prd_start_dt,
	    prd_end_dt
	)
	
	select 
		prd_id,
		replace(substring(prd_key, 1, 5), '-', '_') cat_id,
		substring(prd_key, 7, length(prd_key)) prd_key,
		prd_nm, 
		COALESCE(prd_cost, 0) prd_cost,
		case upper(trim(prd_line))
			when 'S' then 'Other Sales'
			when 'M' then 'Mountain'
			when 'T' then 'Touring'
			when 'R' then 'Road'
			else 'n/a'
		end prd_line,
		cast(prd_start_dt as date) prd_start_dt, 
		cast(lead(prd_start_dt) over(partition by prd_key order by prd_start_dt)-INTERVAL '1 day' as date) prd_end_dt
	from bronze.crm_prd_info;
	
	-- select * from bronze.erp_px_cat_g1v2
	-- select * from bronze.crm_sales_details
	
	
	-- select * from silver.crm_prd_info;
	
	
	
	
	
	-- 3. crm_sales_details
	truncate table silver.crm_sales_details;
	INSERT INTO silver.crm_sales_details (
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		sls_order_dt,
		sls_ship_dt,
		sls_due_dt,
		sls_sales,
		sls_quantity,
		sls_price
	)
	
	SELECT 
	    sls_ord_num,
	    sls_prd_key,
	    sls_cust_id,
	
	    CASE 
	        WHEN sls_order_dt IS NULL 
	             OR sls_order_dt = 0
	             OR LENGTH(sls_order_dt::text) != 8
	        THEN NULL
	        ELSE TO_DATE(sls_order_dt::text, 'YYYYMMDD')
	    END AS sls_order_dt,
	
	    CASE 
	        WHEN sls_ship_dt IS NULL 
	             OR sls_ship_dt = 0
	             OR LENGTH(sls_ship_dt::text) != 8
	        THEN NULL
	        ELSE TO_DATE(sls_ship_dt::text, 'YYYYMMDD')
	    END AS sls_ship_dt,
	
	    CASE 
	        WHEN sls_due_dt IS NULL 
	             OR sls_due_dt = 0
	             OR LENGTH(sls_due_dt::text) != 8
	        THEN NULL
	        ELSE TO_DATE(sls_due_dt::text, 'YYYYMMDD')
	    END AS sls_due_dt,
	
	    CASE 
	        WHEN sls_sales IS NULL 
	             OR sls_sales <= 0 
	             OR sls_sales != sls_quantity * ABS(sls_price)
	        THEN sls_quantity * ABS(sls_price)
	        ELSE sls_sales
	    END AS sls_sales,
	
	    sls_quantity,
	
	    CASE 
	        WHEN sls_price IS NULL 
	             OR sls_price <= 0
	        THEN sls_sales / NULLIF(sls_quantity, 0)
	        ELSE sls_price
	    END AS sls_price
	
	FROM bronze.crm_sales_details;
	-- 
	-- select *
	-- FROM silver.crm_sales_details;
	
	
	
	
	
	-- 4. erp_cust_az12
	truncate table silver.erp_cust_az12;
	insert into silver.erp_cust_az12 (
	    cid,
	    bdate,
	    gen
	)
	
	select 
		substring(trim(cid),length(cid)-9,length(cid)) cid, 
		case 
			when bdate> current_date then null
			else bdate
		end	bdate,
		case
			when upper(substring(trim(gen),1,1))='F' then 'Female'
			when upper(substring(trim(gen),1,1))='M' then 'Male'
			else 'n/a'
		end gen
	FROM bronze.erp_cust_az12;
	
	
	-- select * FROM silver.erp_cust_az12;
	
	
	
	
	
	-- 5. erp_loc_a101
	truncate table silver.erp_loc_a101;
	insert into silver.erp_loc_a101 (
	    cid,
	    cntry
	)
	
	select
		replace(cid,'-','') cid,
		case 
			when trim(cntry) = 'DE' then 'Germany'
			when trim(cntry) in ('US', 'USA') then 'United States'
			when trim(cntry) = '' or cntry is null then 'n/a'
			else trim(cntry)
		end cntry
	from bronze.erp_loc_a101;
	
	
	-- select * from silver.erp_loc_a101;
	
	
	
	
	
	-- 6. erp_px_cat_g1v2
	truncate table silver.erp_px_cat_g1v2;
	insert into silver.erp_px_cat_g1v2 (
	    id,
	    cat,
	    subcat,
	    maintenance
	)
	
	select 
		id,
		cat,
		subcat,
		maintenance
	from bronze.erp_px_cat_g1v2;
	
	
	-- select * from silver.erp_px_cat_g1v2;

END;
$$;

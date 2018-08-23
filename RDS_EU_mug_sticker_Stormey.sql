

SELECT c.id AS campaign_id
	,CONCAT('J', HEX(fj.id)) AS job_id
	,o.id AS order_id
	,pg.name AS product_group
	,c.enddate AS campaign_enddate
	,c.relaunched_from_id
	,CASE WHEN c2.id IS NULL THEN 'No' ELSE 'Yes' END AS is_relaunch_same_design
	,p.name AS product_name
	,crr.campaign_region_id
	,pr.name AS printer_name
	,o.ship_country
	,UPPER(LEFT(pr.region, 3)) AS fulfillment_region
 	,CASE WHEN o.payment_method IN ('STRIPE', 'PAYPAL') THEN 'direct'
 		  WHEN o.payment_method IN ('WISH', 'WISHEXPRESS') THEN 'wish'
 		  WHEN o.payment_method = 'FREE' THEN ff.name
 		  ELSE LOWER(o.payment_method) END AS channel
 	,COALESCE(IF(WEEKDAY(fj.closed_at) + pr.sla > 4,
			      IF(MOD((FLOOR((WEEKDAY(fj.closed_at)+pr.sla)/7)*2) + WEEKDAY(fj.closed_at) + pr.sla, 7) IN (5,6) # skip weekends
				      ,fj.closed_at + INTERVAL (FLOOR((WEEKDAY(fj.closed_at)+pr.sla)/7)*2) + pr.sla + 2 DAY
				      ,fj.closed_at + INTERVAL (FLOOR((WEEKDAY(fj.closed_at)+pr.sla)/7)*2) + pr.sla DAY
				    )
				  ,fj.closed_at + INTERVAL pr.sla DAY
		        ), 'Preassigned') AS ship_due_date
	,o.captured_at
	,NOW() AS timestamp
FROM fulfillment_jobs fj
LEFT JOIN shipments s ON fj.id = s.fulfillment_job_id
LEFT JOIN orders o ON s.order_id = o.id
LEFT JOIN campaigns c ON fj.campaign_id = c.id
LEFT JOIN line_item_fulfillments lif ON fj.id = lif.fulfillment_job_id
LEFT JOIN line_items li ON lif.line_item_id = li.id
LEFT JOIN products p ON li.product_id = p.id
LEFT JOIN product_groups pg ON p.product_group_id = pg.id
LEFT JOIN printers pr ON fj.printer_id = pr.id
LEFT JOIN countries gl ON gl.name = o.ship_country
LEFT JOIN global_redirects gr ON gl.code = gr.country_code 
LEFT JOIN campaign_roots_campaigns crc ON c.id = crc.campaign_id
LEFT JOIN campaign_roots_campaign_regions crr ON crc.campaign_root_id = crr.campaign_root_id
LEFT JOIN campaigns c2 ON c.relaunched_from_id = c2.id AND c.design_id = c2.design_id
LEFT JOIN fulfillment_flags ff ON o.id = ff.flaggable_id AND ff.flaggable_type = 'Order'
WHERE pg.name IN ('Mugs', 'Stickers')
AND pr.region = 'EUR'
-- AND o.captured_at >= CURRENT_DATE - INTERVAL 10 DAY
AND o.cancel_date IS NULL
AND CONCAT('J', HEX(fj.id)) = 'J685B9D'
GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15

# pull campaigns not yet assigned to a printer that will be fulfilled in the EU
UNION ALL

SELECT campaign_id
	,job_id
	,order_id
	,product_group
	,enddate
	,relaunched_from_id
	,is_relaunch_same_design
	,product_name
	,campaign_region_id
	,printer_name
	,ship_country
	,fulfillment_region
	,channel
	,ship_due_date
	,timestamp
FROM (
	SELECT c.id AS campaign_id
		,'Job Not Yet Created' AS job_id
		,o.id AS order_id
		,pg.name AS product_group
		,c.enddate
		,c.relaunched_from_id
		,CASE WHEN c2.id IS NULL THEN 'No' ELSE 'Yes' END AS is_relaunch_same_design
		,p.name AS product_name
		,crr.campaign_region_id
		,NULL AS printer_name
		,o.ship_country
		,UPPER(gr.KEY) AS fulfillment_region
		,CASE WHEN o.payment_method IN ('STRIPE', 'PAYPAL') THEN 'direct'
			  WHEN o.payment_method IN ('WISH', 'WISHEXPRESS') THEN 'wish'
			  WHEN o.payment_method = 'FREE' THEN ff.name
			  ELSE LOWER(o.payment_method) END AS channel
		,'Not Yet Assigned' AS ship_due_date
		,NOW() AS timestamp
		,cg.id AS cg_id
	FROM orders o
	LEFT JOIN line_items li ON o.id = li.itemizable_id AND li.itemizable_type = 'Order'
	LEFT JOIN line_item_fulfillments lf ON li.id = lf.line_item_id
	LEFT JOIN fulfillment_jobs fj ON lf.fulfillment_job_id = fj.id
	LEFT JOIN products p ON li.product_id = p.id
	LEFT JOIN product_groups pg ON p.product_group_id = pg.id
	LEFT JOIN campaigns c ON o.campaign_id = c.id
	LEFT JOIN campaigns c2 ON c.relaunched_from_id = c2.id AND c.design_id = c2.design_id
	LEFT JOIN countries co ON o.ship_country = co.name
	LEFT JOIN global_redirects gr ON co.code = gr.country_code AND gr.mode = 'buyer_region'
	LEFT JOIN campaign_roots_campaigns crc ON c.id = crc.campaign_id
	LEFT JOIN campaign_roots_campaign_regions crr ON crc.campaign_root_id = crr.campaign_root_id
	LEFT JOIN campaign_globalizations cg ON c.id = cg.campaign_id
	LEFT JOIN fulfillment_flags ff ON o.id = ff.flaggable_id AND ff.flaggable_type = 'Order'
	WHERE o.captured_at >= CURRENT_DATE - INTERVAL 5 DAY
	AND fj.id IS NULL
	AND pg.name IN ('Mugs', 'Stickers')
	AND o.order_state_id = 3
	) unassigned
WHERE fulfillment_region = 'EUR'
AND (campaign_region_id = 2 OR cg_id IS NOT NULL)





/************************ 
 * TESTING

# get all mugs/stickers not yet assigned
SELECT c.id AS campaign_id
	,'Job Not Yet Created' AS job_id
	,o.id AS order_id
	,pg.name AS product_group
	,c.enddate
	,c.relaunched_from_id
	,CASE WHEN c2.id IS NULL THEN 'No' ELSE 'Yes' END AS is_relaunch_same_design
	,p.name AS product_name
	,crr.campaign_region_id
	,NULL AS printer_name
	,o.ship_country
	,gr.key AS fulfillment_region
	,CASE WHEN o.payment_method IN ('STRIPE', 'PAYPAL') THEN 'direct'
		  WHEN o.payment_method IN ('WISH', 'WISHEXPRESS') THEN 'wish'
		  WHEN o.payment_method = 'FREE' THEN ff.name
		  ELSE LOWER(o.payment_method) END AS channel
	,'Not Yet Assigned' AS ship_due_date
	,NOW() AS timestamp
	,gr.KEY AS gr_key
-- 	,crr.campaign_region_id
	,cg.id AS cg_id
	,o.captured_at
FROM orders o
LEFT JOIN line_items li ON o.id = li.itemizable_id AND li.itemizable_type = 'Order'
LEFT JOIN line_item_fulfillments lf ON li.id = lf.line_item_id
LEFT JOIN fulfillment_jobs fj ON lf.fulfillment_job_id = fj.id
LEFT JOIN products p ON li.product_id = p.id
LEFT JOIN product_groups pg ON p.product_group_id = pg.id
LEFT JOIN campaigns c ON o.campaign_id = c.id
LEFT JOIN campaigns c2 ON c.relaunched_from_id = c2.id AND c.design_id = c2.design_id
LEFT JOIN countries co ON o.ship_country = co.name
LEFT JOIN global_redirects gr ON co.code = gr.country_code AND gr.mode = 'buyer_region'
LEFT JOIN campaign_roots_campaigns crc ON c.id = crc.campaign_id
LEFT JOIN campaign_roots_campaign_regions crr ON crc.campaign_root_id = crr.campaign_root_id
LEFT JOIN campaign_globalizations cg ON c.id = cg.campaign_id
LEFT JOIN fulfillment_flags ff ON o.id = ff.flaggable_id AND ff.flaggable_type = 'Order'
WHERE o.captured_at >= CURRENT_DATE - INTERVAL 1 DAY
AND fj.id IS NULL
AND pg.name IN ('Mugs', 'Stickers')
-- AND gr.KEY = 'eur' 
-- AND (crr.campaign_region_id = 2 OR cg.id IS NOT NULL)
AND o.order_state_id = 3


SELECT o.id
	,o.campaign_id
	,CONCAT('J', HEX(fj.id)) AS job_id
	,p.name AS printer_name
	,p.region AS printer_region
	,pr.name AS product_name
FROM orders o
LEFT JOIN line_items li ON o.id = li.itemizable_id AND li.itemizable_type = 'Order'
LEFT JOIN line_item_fulfillments lf ON li.id = lf.line_item_id
LEFT JOIN fulfillment_jobs fj ON lf.fulfillment_job_id = fj.id
LEFT JOIN printers p ON fj.printer_id = p.id
LEFT JOIN products pr ON li.product_id = pr.id
LEFT JOIN product_groups pg ON pr.product_group_id = pg.id
WHERE pg.name IN ('Mugs', 'Stickers') 
AND o.id IN ('56272818'
,'56278150'
,'56278270'
)


************************/

/* 
 * Identify why an order for a campaign isn't showing up before it's assigned a
 * job/printer
 * 
*/
/*


SELECT fj.id AS job_id
	,CONCAT('J', HEX(fj.id)) AS job_hex_ix
	,fj.created_at AS job_created_at
	,fj.closed_at
	,fj.cancelled_at
	,fj.declined_at
	,c.id AS campaign_id
	,c.enddate
	,c.printer_id
	,s.token
	,s.created_at AS ship_created_at
	,s.updated_at AS ship_updated_at
	,li.itemizable_type
	,li.created_at AS line_item_created_at
	,p.name AS product_name
	,pg.name AS product_group
	,o.captured_at
	,o.order_date
	,o.updated_at AS order_updated_at
	,o.delivery_date
	,pr.name AS printer_name
	,pr.region AS printer_region
	,pr.sla AS printer_sla
	,cg.id AS campaign_globalization_id
	,cg.created_at AS campaign_globalization_created_at
	,crr.campaign_region_id
	,crr.created_at AS campaign_roots_regions_created_at
FROM fulfillment_jobs fj
JOIN campaigns c ON fj.campaign_id = c.id
JOIN shipments s ON s.fulfillment_job_id = fj.id
JOIN line_items li ON s.order_id = li.itemizable_id AND li.itemizable_type = 'Order'
JOIN products p ON li.product_id = p.id
JOIN product_groups pg ON p.product_group_id = pg.id
JOIN orders o ON s.order_id = o.id
JOIN printers pr ON fj.printer_id = pr.id
LEFT JOIN campaign_globalizations cg ON c.id = cg.campaign_id
LEFT JOIN campaign_roots_campaigns crc ON c.id = crc.campaign_id
LEFT JOIN campaign_roots_campaign_regions crr ON crc.campaign_root_id = crr.campaign_root_id
WHERE concat('J', HEX(fj.id)) IN ('J63E13A'
								 ,'J63E141'
								 ,'J63E16C'
								 ,'J63E7B2'
								 ,'J63C4A1'
								 ,'J63F7C9'
								 ,'J63F7CA'
								 ,'J63F7CE'
								 )
*/



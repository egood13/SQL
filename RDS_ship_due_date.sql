
SELECT *
FROM (
	SELECT '2018-1-1' as holiday # Near Year's Day
	UNION SELECT '2018-1-15' # MLK Day
	UNION SELECT '2018-2-19' # Washington's Day
	UNION SELECT '2018-5-28' # Memorial Day
	UNION SELECT '2018-7-4' # Independence Day
	UNION SELECT '2018-9-3' # Labor Day
	UNION SELECT '2018-10-8' # Columbus Day
	UNION SELECT '2018-11-12' # Veteran's Day
	UNION SELECT '2018-11-22' # Thanksgiving Day
	UNION SELECT '2018-12-24' # Christmas Eve
	UNION SELECT '2018-12-25' # Christmas Day
	UNION SELECT '2018-12-26') x # day after christmas
WHERE holiday between DATE('2018-1-12') AND DATE('2018-12-1')


SELECT *
FROM line_items li
LEFT JOIN orders o ON li.itemizable_id = o.id AND li.itemizable_type = 'Order'
WHERE o.id = 48492167

#------------------ US ------------------#

SELECT job_hex_id
	,campaign_id
	,order_id
	,printer_id
	,printer_name
	,product_name
	,sla
	,assigned_at
	,closed_at
	,due_date
	,CASE WHEN due_date < CURRENT_DATE THEN DATEDIFF(CURRENT_DATE, due_date) ELSE 0 END AS days_late
	,units
	,refund_reason
FROM (
	SELECT job_hex_id
		,campaign_id
		,order_id
		,printer_id
		,printer_name
		,product_name
		,sla
		,assigned_at
		,closed_at
		,CASE WHEN DATE('2018-1-1') BETWEEN closed_at AND due_date THEN due_date + 1 
			  WHEN DATE('2018-1-15') BETWEEN closed_at AND due_date THEN due_date + 1
			  WHEN DATE('2018-2-19') BETWEEN closed_at AND due_date THEN due_date + 1
			  WHEN DATE('2018-5-28') BETWEEN closed_at AND due_date THEN due_date + 1
			  WHEN DATE('2018-7-04') BETWEEN closed_at AND due_date THEN due_date + 1
			  WHEN DATE('2018-10-8') BETWEEN closed_at AND due_date THEN due_date + 1
			  WHEN DATE('2018-11-12') BETWEEN closed_at AND due_date THEN due_date + 1
			  WHEN DATE('2018-11-22') BETWEEN closed_at AND due_date THEN due_date + 1
			  WHEN DATE('2018-12-24') BETWEEN closed_at AND due_date THEN due_date + 1
			  WHEN DATE('2018-12-25') BETWEEN closed_at AND due_date THEN due_date + 1
			  WHEN DATE('2018-12-26') BETWEEN closed_at AND due_date THEN due_date + 1
			  ELSE due_date END as due_date
		,units
		,refund_reason
	FROM (SELECT job_hex_id
				,campaign_id
				,order_id
				,printer_id
				,printer_name
				,product_name
				,sla
				,assigned_at
				,closed_at
			    ,CASE WHEN (printer_id IN (123, 124, 125) AND WEEKDAY(closed_at) = 5) THEN closed_at + INTERVAL 2 DAY # 3rd Party has 1 day even on weekends
			          WHEN (printer_id IN (123, 124, 125) AND WEEKDAY(closed_at) = 6) THEN closed_at + INTERVAL 1 DAY
			          ELSE
					       IF(WEEKDAY(closed_at_adj) + sla > 4,
						     IF(MOD((FLOOR((WEEKDAY(closed_at_adj)+sla)/7)*2) + WEEKDAY(closed_at_adj) + sla, 7) IN (5,6) # skip weekends
							     ,closed_at_adj + INTERVAL (FLOOR((WEEKDAY(closed_at_adj)+sla)/7)*2) + sla + 2 DAY
						         ,closed_at_adj + INTERVAL (FLOOR((WEEKDAY(closed_at_adj)+sla)/7)*2) + sla DAY
							    )
							 ,closed_at_adj + INTERVAL sla DAY
					        )
					  END AS due_date
				,units
				,refund_reason
			FROM (
				Select concat('J',hex(f.id)) as job_hex_id
					, f.campaign_id
					, o.id AS order_id
					, f.printer_id
					, p.name as printer_name
					, po.name as product_name
					, p.sla
					, f.assigned_at
					, f.closed_at
					, CASE WHEN WEEKDAY(f.closed_at) = 6 THEN f.closed_at + INTERVAL 1 DAY
						   WHEN WEEKDAY(f.closed_at) = 5 THEN f.closed_at + INTERVAL 2 DAY
						   ELSE f.closed_at END AS closed_at_adj
				   	, sum(l.quantity) as units
				   	,CASE WHEN rr.description IS NULL THEN 'Not Refunded' ELSE rr.description END AS refund_reason
				from fulfillment_jobs f
				join printers p on f.printer_id = p.id
				join line_item_fulfillments li on f.id = li.fulfillment_job_id
				join line_items l on li.line_item_id = l.id
				LEFT JOIN orders o ON l.itemizable_id = o.id AND l.itemizable_type = 'Order'
				LEFT JOIN products po ON l.product_id = po.id
				LEFT JOIN refund_records r ON o.id = r.order_id
				LEFT JOIN refund_reasons rr ON r.refund_reason_id = rr.id
				where f.cancelled_at is NULL
				and f.declined_at is NULL
				and p.region = 'USA'
				and f.completed_at is null
				and f.closed_at IS NOT NULL
				AND f.printer_id not in (4,15,70,118,104,7,99)
				Group by 1,2,3,4,5,6,7
			) f
		) due_dates
	) x



#------------------ EU ------------------#

SELECT job_hex_id
	,printer_id
	,printer_name
	,printer_country
	,product_name
	,print_group
	,sla
	,assigned_at
	,closed_at
	,CASE WHEN DATE('2018-1-1') BETWEEN closed_at AND due_date THEN due_date + INTERVAL 1 DAY 
		  WHEN DATE('2018-1-15') BETWEEN closed_at AND due_date THEN due_date + INTERVAL 1 DAY
		  WHEN DATE('2018-2-19') BETWEEN closed_at AND due_date THEN due_date + INTERVAL 1 DAY
		  WHEN DATE('2018-5-28') BETWEEN closed_at AND due_date THEN due_date + INTERVAL 1 DAY
		  WHEN DATE('2018-7-04') BETWEEN closed_at AND due_date THEN due_date + INTERVAL 1 DAY
		  WHEN DATE('2018-10-8') BETWEEN closed_at AND due_date THEN due_date + INTERVAL 1 DAY
		  WHEN DATE('2018-11-12') BETWEEN closed_at AND due_date THEN due_date + INTERVAL 1 DAY
		  WHEN DATE('2018-11-22') BETWEEN closed_at AND due_date THEN due_date + INTERVAL 1 DAY
		  WHEN DATE('2018-12-24') BETWEEN closed_at AND due_date THEN due_date + INTERVAL 3 DAY 
		  WHEN closed_at = DATE('2018-12-25') THEN due_date + INTERVAL 2 DAY
		  WHEN closed_at = DATE('2018-12-26') THEN due_date + INTERVAL 1 DAY
		  ELSE due_date END as due_date
	,payment_method
	,units
FROM (SELECT job_hex_id
		,printer_id
		,printer_name
		,printer_country
		,product_name
		,print_group
		,sla
		,assigned_at
		,closed_at
	    ,CASE WHEN (printer_id IN (123, 124, 125) AND WEEKDAY(closed_at) = 5) THEN closed_at + INTERVAL 2 DAY # 3rd Party has 1 day even on weekends
	          WHEN (printer_id IN (123, 124, 125) AND WEEKDAY(closed_at) = 6) THEN closed_at + INTERVAL 1 DAY
	          ELSE
			       IF(WEEKDAY(closed_at_adj) + sla > 4,
				     IF(MOD((FLOOR((WEEKDAY(closed_at_adj)+sla)/7)*2) + WEEKDAY(closed_at_adj) + sla, 7) IN (5,6) # skip weekends
					     ,closed_at_adj + INTERVAL (FLOOR((WEEKDAY(closed_at_adj)+sla)/7)*2) + sla + 2 DAY
				         ,closed_at_adj + INTERVAL (FLOOR((WEEKDAY(closed_at_adj)+sla)/7)*2) + sla DAY
					    )
					 ,closed_at_adj + INTERVAL sla DAY
			        )
			  END AS due_date
		,payment_method
		,units
	FROM (
		SELECT concat('J',hex(f.id)) as job_hex_id
			, f.printer_id
			, p.name as printer_name
			, p.ship_country as printer_country
			, po.name as product_name
			, ps.name as print_group
			, p.sla
			, f.assigned_at
			, f.closed_at
			, f.accepted_at
			, CASE WHEN WEEKDAY(f.closed_at) = 6 THEN f.closed_at + INTERVAL 1 DAY
				   WHEN WEEKDAY(f.closed_at) = 5 THEN f.closed_at + INTERVAL 2 DAY
				   ELSE f.closed_at END AS closed_at_adj
			, payment_method
		   	, sum(l.quantity) as units
		FROM fulfillment_jobs f
		JOIN printers p ON f.printer_id = p.id
		JOIN line_item_fulfillments li ON f.id = li.fulfillment_job_id
		JOIN line_items l ON li.line_item_id = l.id
		JOIN print_groupings pg ON l.trade_item_id = pg.print_groupable_id AND pg.print_groupable_type = 'TradeItem'
		JOIN print_groups ps ON pg.print_group_id = ps.id
		LEFT JOIN products po ON l.product_id = po.id
		WHERE f.cancelled_at IS NULL
		AND f.declined_at IS NULL
		AND p.region <> 'USA'
		AND f.completed_at IS NULL
		AND f.closed_at IS NOT NULL
		AND f.printer_id NOT IN (60, 68, 73, 75, 79, 82, 95)
		AND f.shipped_to_aggregator_at IS NULL
		GROUP BY 1,2,3,4,5,6,7
		ORDER BY closed_at
		) f
	) due_dates
-- WHERE job_hex_id IN ()



	
#------------------ EU ------------------#
SELECT job_hex_id
		,order_id
		,printer_id
		,printer_name
		,printer_country
		,product_name
		,print_group
		,sla
		,assigned_at
		,closed_at
		,CASE WHEN DATE('2019-1-1') BETWEEN closed_at AND due_date THEN due_date + INTERVAL 1 DAY
		      ELSE due_date END as due_date
		,payment_method
		,units
FROM (
	SELECT job_hex_id
		,order_id
		,printer_id
		,printer_name
		,printer_country
		,product_name
		,print_group
		,sla
		,assigned_at
		,closed_at
		,CASE WHEN DATE('2018-1-1') BETWEEN closed_at AND due_date THEN due_date + INTERVAL 1 DAY 
			  WHEN DATE('2018-1-15') BETWEEN closed_at AND due_date THEN due_date + INTERVAL 1 DAY
			  WHEN DATE('2018-2-19') BETWEEN closed_at AND due_date THEN due_date + INTERVAL 1 DAY
			  WHEN DATE('2018-5-28') BETWEEN closed_at AND due_date THEN due_date + INTERVAL 1 DAY
			  WHEN DATE('2018-7-04') BETWEEN closed_at AND due_date THEN due_date + INTERVAL 1 DAY
			  WHEN DATE('2018-10-8') BETWEEN closed_at AND due_date THEN due_date + INTERVAL 1 DAY
			  WHEN DATE('2018-11-12') BETWEEN closed_at AND due_date THEN due_date + INTERVAL 1 DAY
			  WHEN DATE('2018-11-22') BETWEEN closed_at AND due_date THEN due_date + INTERVAL 1 DAY
			  WHEN DATE('2018-12-24') BETWEEN closed_at AND due_date THEN due_date + INTERVAL 3 DAY 
			  WHEN closed_at = DATE('2018-12-25') THEN due_date + INTERVAL 2 DAY
			  WHEN closed_at = DATE('2018-12-26') THEN due_date + INTERVAL 1 DAY
			  ELSE due_date END as due_date
		,payment_method
		,units
	FROM (SELECT job_hex_id
				,order_id
				,printer_id
				,printer_name
				,printer_country
				,product_name
				,print_group
				,sla
				,assigned_at
				,closed_at
				,CASE WHEN (printer_id IN (123, 124, 125) AND WEEKDAY(closed_at_adj) = 5) THEN closed_at_adj + INTERVAL 2 DAY # 3rd Party has 1 day even on weekends
		           	  WHEN (printer_id IN (123, 124, 125) AND WEEKDAY(closed_at) = 6) THEN closed_at_adj + INTERVAL 1 DAY
		              ELSE
				        IF(WEEKDAY(closed_at_adj) + sla > 4,
					      IF(MOD((FLOOR((WEEKDAY(closed_at_adj)+sla)/7)*2) + WEEKDAY(closed_at_adj) + sla, 7) IN (5,6) # skip weekends
						      ,closed_at_adj + INTERVAL (FLOOR((WEEKDAY(closed_at_adj)+sla)/7)*2) + sla + 2 DAY
						      ,closed_at_adj + INTERVAL (FLOOR((WEEKDAY(closed_at_adj)+sla)/7)*2) + sla DAY
						    )
						  ,closed_at_adj + INTERVAL sla DAY
				          )
				   END as due_date
				,payment_method
				,units
		  FROM (
			SELECT concat('J',hex(f.id)) as job_hex_id
				, o.id AS order_id
				, f.printer_id
				, p.name as printer_name
				, p.ship_country as printer_country
				, po.name as product_name
				, ps.name as print_group
				, p.sla
				, f.assigned_at
				, f.closed_at
				, CASE WHEN WEEKDAY(f.closed_at) = 5 THEN f.closed_at + INTERVAL 2 DAY
					   WHEN WEEKDAY(f.closed_at) = 6 THEN f.closed_at + INTERVAL 1 DAY
					   ELSE f.closed_at END AS closed_at_adj
				,CASE WHEN o.payment_method IN ('STRIPE', 'PAYPAL') THEN 'direct'
					  WHEN o.payment_method IN ('WISH', 'WISHEXPRESS') THEN 'wish'
					  WHEN o.payment_method = 'FREE' THEN
					  		CASE WHEN ff.name IN ('amazon', 'ebay', 'walmart', 'wish') THEN ff.name
					  			 WHEN fo.reference_order_id IS NOT NULL THEN
					  			 		CASE WHEN o2.payment_method IN ('STRIPE', 'PAYPAL') THEN 'direct'
					  						 WHEN o2.payment_method IN ('WISH', 'WISHEXPRESS') THEN 'wish'
					  						 WHEN o2.payment_method = 'FREE' THEN 'direct' 
					  						 ELSE LOWER(o2.payment_method)
					  					END
					  			 WHEN fr.description = 'Amazon order' THEN 'amazon'
					  			 WHEN fr.description = 'Wish orders' THEN 'wish'
					  			 WHEN fr.description = 'Ebay order' THEN 'ebay'
					  			 WHEN fr.description = 'Walmart order' THEN 'walmart'
					  			 ELSE 'direct'
					  		END 
					  ELSE LOWER(o.payment_method) 
				 END AS payment_method
				,sum(l.quantity) as units
			FROM fulfillment_jobs f
			JOIN printers p ON f.printer_id = p.id
			JOIN line_item_fulfillments li ON f.id = li.fulfillment_job_id
			JOIN line_items l ON li.line_item_id = l.id
			JOIN print_groupings pg ON l.trade_item_id = pg.print_groupable_id AND pg.print_groupable_type = 'TradeItem'
			JOIN print_groups ps ON pg.print_group_id = ps.id
			LEFT JOIN products po ON l.product_id = po.id
			LEFT JOIN shipments s ON li.shipment_id = s.id
			LEFT JOIN orders o ON s.order_id = o.id
			LEFT JOIN free_order_logs fo ON o.id = fo.order_id AND o.payment_method = 'FREE'
			LEFT JOIN orders o2 ON fo.reference_order_id = o2.id
	 		LEFT JOIN fulfillment_flags ff ON o.id = ff.flaggable_id 
	 									  AND ff.flaggable_type = 'Order'
	 									  AND ff.name IN ('amazon', 'ebay', 'walmart', 'wish')
	 		LEFT JOIN free_order_reasons fr ON fo.free_order_reason_id = fr.id
			WHERE f.cancelled_at IS NULL
			AND f.declined_at IS NULL
			AND p.region <> 'USA'
			AND f.completed_at IS NULL
			AND f.closed_at IS NOT NULL
			AND f.printer_id NOT IN (60, 68, 73, 75, 79, 82, 95)
			AND f.shipped_to_aggregator_at IS NULL
			GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12
			) f
		) due_dates
	) holiday_due_dates
WHERE job_hex_id IN ('J6614CB','J6614CC','J6614CD','J6614CE','J6614CF')





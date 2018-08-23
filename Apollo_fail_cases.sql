
SELECT lpn
	,qc_result
	,qc_fail_reason
	,load_data
	,qc_data
	,CASE WHEN fail_occurred_at = 'N/A' THEN hotpick_date ELSE COALESCE(fail_occurred_at, hotpick_date) END as fail_hotpick_date
 	,CASE WHEN fail_occurred_at = 'N/A' THEN TIME(hotpick_date) ELSE TIME(COALESCE(fail_occurred_at, hotpick_date)) END as fail_hotpick_time
	,employee
	,picker
	,station
	,pod
	,area_responsible
	,CASE WHEN area_responsible = 'picker' THEN picker ELSE employee END AS employee_responsible
	,fail_category
	,CASE WHEN fail_occurred_at = 'N/A' THEN 'N/A'
		  WHEN HOUR(fail_occurred_at) BETWEEN 7 AND 14 THEN 'A Shift'
		  WHEN HOUR(fail_occurred_at) BETWEEN 15 AND 22 THEN 'B Shift'
		  ELSE 'C Shift' END AS shift_responsible
FROM (
	# loader front/back
	SELECT l.lpn
		, l.qc_result
		, l.qc_fail_reason
		, loader.metadata as load_data
		, qc.metadata as qc_data
		, s.updated_at as hotpick_date
		, concat(e.firstname, ' ', e.lastname) as employee
		, CONCAT(p.firstname, ' ', p.lastname) AS picker
		, st.station
		, st.pod
		, case when qc_fail_reason = 'Wrong Shirt' then 'picker' else 'loader' end as area_responsible
		, 'Front/Load Match' as fail_category
		, CASE WHEN qc_fail_reason = 'Wrong Shirt' THEN a.picked_at ELSE loader.updated_at END AS fail_occurred_at
	FROM LMS_scan s
	join LMS_lpn l on l.lpn = s.barcode
	left join LMS_scan s2 on s.barcode = s2.barcode and s2.action = 'hotpicked' and s2.id > s.id
	join LMS_scan qc on s.barcode = qc.barcode and qc.metadata like 'fail :%'
	left join LMS_scan q2 on qc.barcode = q2.barcode and qc.metadata = q2.metadata and q2.id > qc.id
	join LMS_scan loader on qc.barcode = loader.barcode and loader.action = 'op_access'
	left join LMS_scan l2 on loader.barcode = l2.barcode and loader.metadata = l2.metadata and l2.id > loader.id
	JOIN LMS_employee e ON loader.employee_id = e.id
	JOIN LMS_station st ON loader.station_id = st.id
	LEFT JOIN LMS_lpnattributes a ON l.id = a.lpn_id
	LEFT JOIN LMS_employee p ON a.picker_id = p.id
	WHERE date(s.updated_at) >= CURRENT_DATE - INTERVAL '100' DAY
	and s.action = 'hotpicked'
	and s2.id is null
	and l2.id is null
	and q2.id is null
	and qc_fail_reason <> 'Missing Item' and qc_fail_reason is not null
	and right(qc.metadata,5) = right(loader.metadata,5)
		
	Union all
	
	# Missing Loader	
	Select l.lpn
		, l.qc_result
		, l.qc_fail_reason
		, '' as load_data
		, qc.metadata as qc_data
		, s.updated_at as hotpick_date
		, '' as employee
		,CONCAT(p.firstname, ' ', p.lastname) AS picker
		, '' as station
		, coalesce(st.pod,'') as pod
		, case when qc_fail_reason in ('Wrong Shirt','Item Missing') then 'picker' else 'N/A' end as area_responsible
		, 'Missing Loader' as fail_category
		, CASE WHEN qc_fail_reason IN ('Wrong Shirt', 'Item Missing') THEN a.picked_at ELSE 'N/A' END AS fail_occurred_at
	From LMS_scan s 
	join LMS_lpn l on l.lpn = s.barcode
	LEFT JOIN LMS_scan s2 on s.barcode = s2.barcode and s2.action = 'hotpicked' and s2.id > s.id
	left join LMS_scan loader on s.barcode = loader.barcode and loader.action = 'op_access'
	left join LMS_scan qc on s.barcode = qc.barcode and qc.metadata like 'fail%'
	left join LMS_scan q2 on qc.barcode = q2.barcode and q2.metadata like 'fail%' and q2.id > qc.id
	left JOIN LMS_station st ON qc.station_id = st.id
	LEFT JOIN LMS_lpnattributes a ON l.id = a.lpn_id
	LEFT JOIN LMS_employee p ON a.picker_id = p.id
	where s.action = 'hotpicked'
	and s2.id is null
	and q2.id is null
	and date(s.updated_at) >= CURRENT_DATE - INTERVAL '100' DAY
	and loader.action is null
	and qc_fail_reason <> 'Missing Item' and qc_fail_reason is not NULL
	
	Union ALL
	
	# fail general
	Select l.lpn
		, l.qc_result
		, l.qc_fail_reason
		, loader.metadata as load_data
		, COALESCE(qc.metadata, 'Fail Reason Not Selected') as qc_data
		, s.updated_at as hotpick_date
		, concat(e.firstname,' ', e.lastname) as employee
		,CONCAT(p.firstname, ' ', p.lastname) AS picker
		, st.station
		, st.pod
		, case when qc_fail_reason = 'Wrong Shirt' then 'picker' else 'loader' end as area_responsible
		, 'Front General - Last Loader' as fail_category
		, CASE WHEN qc_fail_reason = 'Wrong Shirt' THEN a.picked_at ELSE loader.updated_at END AS fail_occurred_at
	From LMS_scan s 
	join LMS_lpn l on l.lpn = s.barcode
	left join LMS_scan s2 on s.barcode = s2.barcode and s2.action = 'hotpicked' and s2.id > s.id
	join LMS_scan loader on s.barcode = loader.barcode and loader.action = 'op_access'
	left join LMS_scan l2 on loader.barcode = l2.barcode and loader.action = l2.action and l2.id > loader.id
	LEFT join LMS_scan qc on s.barcode = qc.barcode and (qc.metadata = 'fail')
	left join LMS_scan q2 on s.barcode = q2.barcode and qc.metadata = q2.metadata and q2.id > qc.id
	JOIN LMS_employee e ON loader.employee_id = e.id
	JOIN LMS_station st ON loader.station_id = st.id
	LEFT JOIN LMS_lpnattributes a ON l.id = a.lpn_id
	LEFT JOIN LMS_employee p ON a.picker_id = p.id
	where s.action = 'hotpicked'
	and s2.id is null
	and q2.id is NULL
	and l2.id is null
	and date(s.updated_at) >= CURRENT_DATE - INTERVAL '100' DAY
	and s.barcode not in (select barcode from LMS_scan where action = 'qc_result' and metadata like 'fail :%')
	and qc_fail_reason <> 'Missing Item' and qc_fail_reason is not NULL
	
	UNION ALL
	
	# missing items
	SELECT l.lpn
		, l.qc_result
		, CASE WHEN mll.created_at IS NOT NULL THEN 'Missing From Matching' ELSE COALESCE(l.qc_fail_reason, 'Missing Item') END AS qc_fail_reason
		, CASE WHEN scans.action = 'op_access' then scans.metadata end as load_data
		, case when scans.action = 'qc_access' then scans.action
			   when scans.action = 'qc_result' then scans.metadata end as qc_data
		, s.updated_at as hotpick_date
		, CASE WHEN mll.created_at IS NOT NULL THEN '' ELSE concat(e.firstname,' ', e.lastname) END as employee
		,CONCAT(p.firstname, ' ', p.lastname) AS picker
		, st.station
		, st.pod
		, case when scans.action is null then 'Picker'
			   when scans.action in ('qc_result','qc_access') then 'qc'
			   when scans.action = 'op_access' then 'loader' end as area_responsible
		, 'Missing Items' AS fail_category
		, CASE WHEN scans.ACTION IS NULL THEN a.picked_at ELSE scans.updated_at END AS fail_occurred_at
	From LMS_scan s 
	join LMS_lpn l on l.lpn = s.barcode
	LEFT JOIN matching_loc_lpn mll ON l.id = mll.lpn_id
	left join LMS_scan s2 on s.barcode = s2.barcode 
						  and s2.action = 'hotpicked' 
						  and s2.id > s.id
	Left join LMS_scan scans on s.barcode = scans.barcode
							 and scans.id < s.id  
							 and coalesce(scans.metadata,'') not like 'Change reason%' 
							 and coalesce(scans.metadata,'') not like '%fail%'
							 AND scans.ACTION <> 'hotpicked'
	Left join LMS_scan last_scan on scans.barcode = last_scan.barcode 
								 and last_scan.id > scans.id 
								 and last_scan.id < s.id  
								 and coalesce(last_scan.metadata,'') not like 'Change reason%' 
								 and coalesce(last_scan.metadata,'') not like '%fail%'
								 AND last_scan.ACTION <> 'hotpicked'
	Left join LMS_employee e on scans.employee_id = e.id
	Left join LMS_station st on scans.station_id = st.id
	LEFT JOIN LMS_lpnattributes a ON l.id = a.lpn_id
	LEFT JOIN LMS_employee p ON a.picker_id = p.id
	where s.action = 'hotpicked'
	and s2.id is NULL
	and last_scan.id is NULL
	and ((l.qc_fail_reason = 'Missing Item' or l.qc_fail_reason is null))
	AND date(s.updated_at) >= CURRENT_DATE - INTERVAL '100' DAY
	
	Union ALL
	
	# loader/qc mismatch
	SELECT l.lpn
		, l.qc_result
		, l.qc_fail_reason
		, loader.metadata as load_data
		, qc.metadata as qc_data
		, s.updated_at as hotpick_date
		, concat(e.firstname,' ', e.lastname) as employee
		,CONCAT(p.firstname, ' ', p.lastname) AS picker
		, st.station
		, st.pod
		, case when qc_fail_reason = 'Wrong Shirt' then 'picker' else 'loader' end as area_responsible
		, 'Front/Load Mismatch' as fail_category
		, CASE WHEN qc_fail_reason = 'Wrong Shirt' THEN a.picked_at ELSE loader.updated_at END AS fail_occurred_at
	FROM LMS_scan s
	join LMS_lpn l on l.lpn = s.barcode
	left join LMS_scan s2 on s.barcode = s2.barcode and s2.action = 'hotpicked' and s2.id > s.id
	join LMS_scan qc on s.barcode = qc.barcode and qc.metadata like 'fail :%'
	left join LMS_scan q2 on qc.barcode = q2.barcode and qc.metadata = q2.metadata and q2.id > qc.id
	join LMS_scan loader on qc.barcode = loader.barcode and loader.action = 'op_access'
	left join LMS_scan l2 on loader.barcode = l2.barcode and loader.metadata = l2.metadata and l2.id > loader.id
	Left join LMS_scan l3 on loader.barcode = l3.barcode and loader.action = l3.action and loader.metadata <> l3.metadata
	JOIN LMS_employee e ON loader.employee_id = e.id
	JOIN LMS_station st ON loader.station_id = st.id
	LEFT JOIN LMS_lpnattributes a ON l.id = a.lpn_id
	LEFT JOIN LMS_employee p ON a.picker_id = p.id
	WHERE date(s.updated_at) >= CURRENT_DATE - INTERVAL '100' DAY
	and s.action = 'hotpicked'
	and s2.id is null
	and l2.id is null
	and q2.id is null
	and qc_fail_reason <> 'Missing Item' and qc_fail_reason is not null
	and right(qc.metadata,5) <> right(loader.metadata,5)
	and l3.id is NULL
	) fails
WHERE COALESCE(DATE(fail_occurred_at), DATE(hotpick_date)) >= CURRENT_DATE - INTERVAL 100 DAY







--------------------------------------------------------------------------
-- Count page views, unique page visits and conversions per page
--------------------------------------------------------------------------
SELECT
  p.id,
  p.name,
  p.page_variant_id,
  p.variant_name,
  p.project_id,
  pv.published,
  round(p.ab_priority::numeric, 2)::float8 as ab_priority,
  (
    SELECT COUNT(*) FROM page_views pv
    INNER JOIN unique_page_visits upv ON upv.id = pv.unique_page_visit_id
    WHERE pv.page_id = p.id  AND pv.updated_at AT TIME ZONE '+01:00' >= '2017-02-27 00:00:00' AND pv.updated_at AT TIME ZONE '+01:00' <= '2017-03-06 23:59:59' AND upv.visitor_device_type = 'desktop'
  ) as views_count,
  (
    SELECT COUNT(*) FROM unique_page_visits upv
    WHERE upv.page_id = p.id  AND upv.updated_at AT TIME ZONE '+01:00' >= '2017-02-27 00:00:00' AND upv.updated_at AT TIME ZONE '+01:00' <= '2017-03-06 23:59:59' AND upv.visitor_device_type = 'desktop'
  ) as page_visits_count,
  (
    SELECT COUNT(*) FROM conversions c
    INNER JOIN conversion_goals cg ON cg.id = c.conversion_goal_id
    INNER JOIN unique_page_visits upv ON upv.id = c.unique_page_visit_id
    WHERE c.basepage_id = p.id  AND c.updated_at AT TIME ZONE '+01:00' >= '2017-02-27 00:00:00' AND c.updated_at AT TIME ZONE '+01:00' <= '2017-03-06 23:59:59' AND upv.visitor_device_type = 'desktop' AND cg.id = '640'
  ) as conversions_count
FROM
  pages p
  INNER JOIN page_variants pv ON pv.id = p.page_variant_id
WHERE
  p.backpage = false AND p.popup = false AND p.deleted_at IS NULL AND p.page_variant_id = '2606'
ORDER BY
  p.variant_name ASC
--------------------------------------------------------------------------
-- query used in analytics, group COUNTs for views, unique page visits and conversions per day from given time-range
--------------------------------------------------------------------------
WITH p AS (
  SELECT
    '2017-02-26 23:00:00'::timestamp AS a,
    '2017-03-06 22:59:59'::timestamp AS z,
    pages.id,
    pages.name,
    pages.page_variant_id,
    pages.variant_name
  FROM
    pages
  WHERE
        pages.id = 8350
    AND pages.backpage = false
    AND pages.popup = false
    AND pages.deleted_at IS NULL
)
SELECT
  date_numeral,
  '1' as day,
  p.id as page_id,
  p.name,
  p.page_variant_id,
  p.variant_name,
  coalesce(views_count, 0) as views_count,
  coalesce(page_visits_count, 0) as page_visits_count,
  coalesce(conversions_count, 0) as conversions_count
FROM
  p,
  LATERAL (
      SELECT tmpstamp::date as date_numeral
      FROM generate_series('2017-02-27 00:00:00', '2017-03-06 23:59:59', '1 day'::interval) tmpstamp
  ) d
LEFT JOIN (
  SELECT
    (pv.updated_at AT TIME ZONE '+01:00')::date AS date_numeral,
    count(*) AS views_count
  FROM                      p
  JOIN   page_views         pv  ON pv.page_id = p.id
  JOIN   unique_page_visits upv ON upv.id = pv.unique_page_visit_id
  WHERE
        upv.updated_at BETWEEN p.a AND p.z
         AND upv.visitor_device_type = 'desktop'
  GROUP BY 1
) v USING (date_numeral)
LEFT JOIN (
   SELECT
     (upv.updated_at AT TIME ZONE '+01:00')::date  AS date_numeral,
     count(*) AS page_visits_count
   FROM                      p
   JOIN   unique_page_visits upv ON upv.page_id = p.id
   WHERE
         upv.updated_at BETWEEN p.a AND p.z
          AND upv.visitor_device_type = 'desktop'
   GROUP BY 1
) pv USING (date_numeral)
LEFT JOIN (
   SELECT
     (c.updated_at AT TIME ZONE '+01:00')::date AS date_numeral,
     count(*) AS conversions_count
   FROM                      p
   JOIN   conversion_goals   cg  ON cg.page_variant_id = p.page_variant_id
   JOIN   conversions        c   ON c.conversion_goal_id = cg.id
   JOIN   unique_page_visits upv ON upv.id = c.unique_page_visit_id
   WHERE
         c.updated_at BETWEEN p.a AND p.z AND
         c.basepage_id = p.id
          AND upv.visitor_device_type = 'desktop' AND cg.id = '640'
   GROUP BY 1
) c USING (date_numeral)
ORDER  BY date_numeral, p.variant_name ASC;

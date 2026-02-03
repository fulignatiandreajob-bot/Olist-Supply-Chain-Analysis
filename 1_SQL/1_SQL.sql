SELECT 
    o.order_id,
    o.customer_id,
    i.seller_id,
    c.customer_state,
    SUM(p.product_weight_g) AS peso_totale_grammi,
    (NULLIF(o.order_delivered_carrier_date, '')::DATE - NULLIF(o.order_approved_at, '')::DATE) AS Seller_rank,
    (NULLIF(o.order_delivered_customer_date, '')::DATE - NULLIF(o.order_estimated_delivery_date, '')::DATE) AS Delivery_gap --al posto di questo nullif potevi mettere anche tutto nel ciclo where, in modo da escludere i valori vuoti, però facendo così escludevi un intero ordine solo perché magari mancava la data del pagamento magari. così escludi solo se manca la data della consegna altrimenti no
FROM olist_orders_dataset o
JOIN olist_order_items_dataset i ON o.order_id = i.order_id
JOIN olist_products_dataset p ON i.product_id = p.product_id
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'             -- only delivered order
  AND o.order_delivered_customer_date != ''    -- exclude the empty date
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY 
    o.order_id, 
    o.customer_id, 
    i.seller_id,
    c.customer_state, 
    o.order_delivered_carrier_date, 
    o.order_approved_at, 
    o.order_delivered_customer_date, 
    o.order_estimated_delivery_date;
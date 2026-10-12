-- Last line of defence behind the API's validation: a bug (or a hand-run
-- script) that tries to store a negative stock, a zero-quantity line or a
-- negative price is refused by the database itself.
--
-- Written against data that already satisfies every rule; the migration fails
-- loudly, rather than silently skipping a row, if that ever stops being true.

ALTER TABLE "products"
  ADD CONSTRAINT "products_current_stock_nonneg" CHECK ("currentStock" >= 0),
  ADD CONSTRAINT "products_minimum_stock_nonneg" CHECK ("minimumStock" >= 0),
  ADD CONSTRAINT "products_selling_price_nonneg" CHECK ("sellingPrice" >= 0),
  ADD CONSTRAINT "products_cost_price_nonneg" CHECK ("costPrice" >= 0);

ALTER TABLE "sale_items"
  ADD CONSTRAINT "sale_items_qty_positive" CHECK ("qty" > 0),
  ADD CONSTRAINT "sale_items_rate_nonneg" CHECK ("rate" >= 0);

ALTER TABLE "purchase_items"
  ADD CONSTRAINT "purchase_items_qty_positive" CHECK ("qty" > 0),
  ADD CONSTRAINT "purchase_items_rate_nonneg" CHECK ("rate" >= 0);

ALTER TABLE "stock_movements"
  ADD CONSTRAINT "stock_movements_qty_positive" CHECK ("qty" > 0);

ALTER TABLE "sales_orders"
  ADD CONSTRAINT "sales_orders_amount_nonneg" CHECK ("amount" >= 0),
  ADD CONSTRAINT "sales_orders_paid_nonneg" CHECK ("paidAmount" >= 0);

ALTER TABLE "purchase_orders"
  ADD CONSTRAINT "purchase_orders_amount_nonneg" CHECK ("amount" >= 0),
  ADD CONSTRAINT "purchase_orders_paid_nonneg" CHECK ("paidAmount" >= 0),
  ADD CONSTRAINT "purchase_orders_freight_nonneg" CHECK ("freight" >= 0);

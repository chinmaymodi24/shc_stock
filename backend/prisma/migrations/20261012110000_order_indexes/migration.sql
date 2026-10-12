-- Postgres does not index foreign keys on its own. Every order list, the
-- stock check (open sale lines per product) and the delivery sweep filter on
-- these columns, so without them each one scanned the whole table.
CREATE INDEX "purchase_orders_status_idx" ON "purchase_orders"("status");
CREATE INDEX "purchase_orders_updatedAt_idx" ON "purchase_orders"("updatedAt");
CREATE INDEX "purchase_orders_expectedDelivery_idx" ON "purchase_orders"("expectedDelivery");

CREATE INDEX "purchase_items_purchaseOrderId_idx" ON "purchase_items"("purchaseOrderId");
CREATE INDEX "purchase_items_productId_idx" ON "purchase_items"("productId");

CREATE INDEX "sales_orders_status_idx" ON "sales_orders"("status");
CREATE INDEX "sales_orders_updatedAt_idx" ON "sales_orders"("updatedAt");
CREATE INDEX "sales_orders_expectedDelivery_idx" ON "sales_orders"("expectedDelivery");

CREATE INDEX "sale_items_salesOrderId_idx" ON "sale_items"("salesOrderId");
CREATE INDEX "sale_items_productId_idx" ON "sale_items"("productId");

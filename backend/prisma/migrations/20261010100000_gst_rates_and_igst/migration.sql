-- GST per line, and IGST for a party in another state.
-- Existing lines were all charged 18%; existing orders as intra-state
-- (CGST + SGST), so both defaults describe them exactly.
ALTER TABLE "sale_items" ADD COLUMN "taxPercent" DECIMAL(5,2) NOT NULL DEFAULT 18;
ALTER TABLE "purchase_items" ADD COLUMN "taxPercent" DECIMAL(5,2) NOT NULL DEFAULT 18;
ALTER TABLE "sales_orders" ADD COLUMN "interState" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "purchase_orders" ADD COLUMN "interState" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "sale_items" ADD CONSTRAINT "sale_items_tax_range" CHECK ("taxPercent" >= 0 AND "taxPercent" <= 100);
ALTER TABLE "purchase_items" ADD CONSTRAINT "purchase_items_tax_range" CHECK ("taxPercent" >= 0 AND "taxPercent" <= 100);

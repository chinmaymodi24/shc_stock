-- Payments on a sale: every payment is one Transactions row, linked to its
-- sale (deleted with it), carrying the amount and how it was paid.
ALTER TABLE "transactions" ADD COLUMN "amount" DECIMAL(14,2) NOT NULL DEFAULT 0;
ALTER TABLE "transactions" ADD COLUMN "mode" TEXT NOT NULL DEFAULT '';
ALTER TABLE "transactions" ADD COLUMN "salesOrderId" INTEGER;

CREATE INDEX "transactions_salesOrderId_idx" ON "transactions"("salesOrderId");

ALTER TABLE "transactions" ADD CONSTRAINT "transactions_salesOrderId_fkey"
  FOREIGN KEY ("salesOrderId") REFERENCES "sales_orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- The paid-purchase rows already record a payment: give them its amount.
UPDATE "transactions" t
   SET "amount" = p."paidAmount"
  FROM "purchase_orders" p
 WHERE t."refType" = 'purchase' AND t."refId" = p."id";

-- A sale saved before this change with money against it gets one payment row
-- for what it recorded, so the order and its payments agree from day one.
INSERT INTO "transactions"
  ("item", "type", "party", "poNumber", "date", "status", "notes", "amount", "mode",
   "refType", "refId", "salesOrderId", "modifiedBy", "modifiedAt", "createdAt", "updatedAt")
SELECT
  COALESCE((SELECT si."product" FROM "sale_items" si WHERE si."salesOrderId" = s."id" ORDER BY si."id" LIMIT 1), 'Sale'),
  'Outbound', s."client", s."soNumber", s."date", 'Received', '', s."paidAmount", '',
  'sale', s."id", s."id", s."modifiedBy", NOW(), NOW(), NOW()
FROM "sales_orders" s
WHERE s."paidAmount" > 0;

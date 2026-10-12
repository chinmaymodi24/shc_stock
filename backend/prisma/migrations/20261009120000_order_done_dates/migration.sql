-- When an order actually reached its final status: a purchase "Received", a
-- sale "Delivered". Orders already there are stamped with their last change,
-- the best date we have for them.
ALTER TABLE "purchase_orders" ADD COLUMN "receivedAt" TIMESTAMP(3);
ALTER TABLE "sales_orders" ADD COLUMN "deliveredAt" TIMESTAMP(3);
UPDATE "purchase_orders" SET "receivedAt" = COALESCE("modifiedAt", "updatedAt") WHERE "status" = 'Received';
UPDATE "sales_orders" SET "deliveredAt" = COALESCE("modifiedAt", "updatedAt") WHERE "status" = 'Delivered';

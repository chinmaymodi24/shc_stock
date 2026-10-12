-- "Auto-generate invoice numbers" becomes one switch for Purchase and one for
-- Sales. Everyone keeps whatever they had chosen: both start from the old
-- single value (autoNumberDocs stays, now unused by the app).
ALTER TABLE "users" ADD COLUMN "autoNumberPurchase" BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE "users" ADD COLUMN "autoNumberSales" BOOLEAN NOT NULL DEFAULT true;
UPDATE "users" SET "autoNumberPurchase" = "autoNumberDocs", "autoNumberSales" = "autoNumberDocs";

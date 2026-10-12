-- A transaction can now be the record of a fully-paid order (see
-- src/paymentTransaction.js). Hand-entered rows keep both columns NULL.
ALTER TABLE "transactions" ADD COLUMN "refType" TEXT;
ALTER TABLE "transactions" ADD COLUMN "refId" INTEGER;
CREATE INDEX "transactions_refType_refId_idx" ON "transactions"("refType", "refId");

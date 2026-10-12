-- Stock in measured units (kg, m, sqm…) can be fractional: 12.5 kg of bulk
-- fibre. Three decimals, matching the order lines and the stock ledger.
-- Existing whole numbers convert exactly; the >= 0 CHECKs carry over.
ALTER TABLE "products" ALTER COLUMN "currentStock" TYPE DECIMAL(14,3) USING "currentStock"::DECIMAL(14,3);
ALTER TABLE "products" ALTER COLUMN "minimumStock" TYPE DECIMAL(14,3) USING "minimumStock"::DECIMAL(14,3);

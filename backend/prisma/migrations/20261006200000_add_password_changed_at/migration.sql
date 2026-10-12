-- Sessions signed before this moment stop working when the password changes.
-- NULL (every existing account) means "never changed": nothing is revoked.
ALTER TABLE "users" ADD COLUMN "passwordChangedAt" TIMESTAMP(3);

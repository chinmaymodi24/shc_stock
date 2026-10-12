-- Existing accounts keep working exactly as before (false); only accounts
-- created or reset from now on are asked to choose their own password.
ALTER TABLE "users" ADD COLUMN "mustChangePassword" BOOLEAN NOT NULL DEFAULT false;

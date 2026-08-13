-- AlterTable
ALTER TABLE "users" ADD COLUMN     "code" TEXT NOT NULL DEFAULT '',
ADD COLUMN     "department" TEXT NOT NULL DEFAULT '',
ADD COLUMN     "isActive" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN     "lastLoginAt" TIMESTAMP(3),
ADD COLUMN     "modifiedAt" TIMESTAMP(3),
ADD COLUMN     "modifiedBy" TEXT NOT NULL DEFAULT 'Admin',
ADD COLUMN     "phone" TEXT NOT NULL DEFAULT '';

-- Backfill employee codes for rows that predate the column, so the unique
-- index below can be created safely.
UPDATE "users" SET "code" = 'USR-' || LPAD("id"::text, 4, '0') WHERE "code" = '';

-- CreateIndex
CREATE UNIQUE INDEX "users_code_key" ON "users"("code");


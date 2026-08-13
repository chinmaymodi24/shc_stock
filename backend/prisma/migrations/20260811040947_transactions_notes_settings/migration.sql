-- AlterTable
ALTER TABLE "users" ADD COLUMN     "dateFormat" TEXT NOT NULL DEFAULT 'MMM D, YYYY (Jul 18, 2026)',
ADD COLUMN     "notifyDelivery" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN     "notifyLowStock" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN     "notifyPayment" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "notifyWeekly" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN     "rowsPerPage" INTEGER NOT NULL DEFAULT 10,
ADD COLUMN     "twoFactor" BOOLEAN NOT NULL DEFAULT false;

-- CreateTable
CREATE TABLE "transactions" (
    "id" SERIAL NOT NULL,
    "item" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "party" TEXT NOT NULL DEFAULT '',
    "poNumber" TEXT NOT NULL DEFAULT '',
    "date" TIMESTAMP(3) NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'Pending',
    "notes" TEXT NOT NULL DEFAULT '',
    "modifiedBy" TEXT NOT NULL DEFAULT 'Admin',
    "modifiedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "transactions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "dashboard_notes" (
    "id" SERIAL NOT NULL,
    "userId" INTEGER,
    "text" TEXT NOT NULL,
    "done" BOOLEAN NOT NULL DEFAULT false,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "dashboard_notes_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "transactions_date_idx" ON "transactions"("date");

-- CreateIndex
CREATE INDEX "dashboard_notes_userId_idx" ON "dashboard_notes"("userId");

-- AddForeignKey
ALTER TABLE "dashboard_notes" ADD CONSTRAINT "dashboard_notes_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

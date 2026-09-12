-- AlterTable
ALTER TABLE "app_settings" ADD COLUMN     "billingProfile" JSONB NOT NULL DEFAULT '{}';

-- CreateTable
CREATE TABLE "bills" (
    "id" SERIAL NOT NULL,
    "salesOrderId" INTEGER NOT NULL,
    "invoiceNo" TEXT NOT NULL,
    "issuedOn" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "showHsnSummary" BOOLEAN NOT NULL DEFAULT true,
    "showBankDetails" BOOLEAN NOT NULL DEFAULT true,
    "showUpiQr" BOOLEAN NOT NULL DEFAULT true,
    "showEInvoice" BOOLEAN NOT NULL DEFAULT true,
    "showDeclaration" BOOLEAN NOT NULL DEFAULT true,
    "irn" TEXT,
    "ackNo" TEXT,
    "ackDate" TIMESTAMP(3),
    "generatedBy" TEXT NOT NULL DEFAULT 'Admin',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "bills_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "bill_events" (
    "id" SERIAL NOT NULL,
    "billId" INTEGER NOT NULL,
    "type" TEXT NOT NULL,
    "note" TEXT NOT NULL DEFAULT '',
    "actor" TEXT NOT NULL DEFAULT 'Admin',
    "at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "bill_events_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "bills_salesOrderId_key" ON "bills"("salesOrderId");

-- CreateIndex
CREATE UNIQUE INDEX "bills_invoiceNo_key" ON "bills"("invoiceNo");

-- CreateIndex
CREATE INDEX "bill_events_billId_idx" ON "bill_events"("billId");

-- AddForeignKey
ALTER TABLE "bills" ADD CONSTRAINT "bills_salesOrderId_fkey" FOREIGN KEY ("salesOrderId") REFERENCES "sales_orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bill_events" ADD CONSTRAINT "bill_events_billId_fkey" FOREIGN KEY ("billId") REFERENCES "bills"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AlterTable
ALTER TABLE "purchase_orders" ADD COLUMN     "expectedDelivery" TIMESTAMP(3),
ADD COLUMN     "paymentType" TEXT NOT NULL DEFAULT '',
ADD COLUMN     "paidAmount" DOUBLE PRECISION NOT NULL DEFAULT 0;

-- AlterTable
ALTER TABLE "sales_orders" ADD COLUMN     "expectedDelivery" TIMESTAMP(3),
ADD COLUMN     "paymentType" TEXT NOT NULL DEFAULT '',
ADD COLUMN     "paidAmount" DOUBLE PRECISION NOT NULL DEFAULT 0;

-- CreateTable
CREATE TABLE "purchase_orders" (
    "id" SERIAL NOT NULL,
    "poNumber" TEXT NOT NULL,
    "supplier" TEXT NOT NULL,
    "supplierIcon" TEXT NOT NULL DEFAULT '',
    "date" TIMESTAMP(3) NOT NULL,
    "amount" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "status" TEXT NOT NULL DEFAULT 'Pending',
    "modifiedBy" TEXT NOT NULL DEFAULT 'Admin',
    "modifiedAt" TIMESTAMP(3),
    "supplierAddress" TEXT NOT NULL DEFAULT '',
    "buyerGst" TEXT NOT NULL DEFAULT '',
    "pan" TEXT NOT NULL DEFAULT '',
    "invoiceNo" TEXT NOT NULL DEFAULT '',
    "invoiceDate" TIMESTAMP(3),
    "despatchThrough" TEXT NOT NULL DEFAULT '',
    "lrNo" TEXT NOT NULL DEFAULT '',
    "lrDate" TIMESTAMP(3),
    "vehicleNo" TEXT NOT NULL DEFAULT '',
    "freight" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "placeOfSupply" TEXT NOT NULL DEFAULT '',
    "dueDate" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "purchase_orders_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "purchase_items" (
    "id" SERIAL NOT NULL,
    "purchaseOrderId" INTEGER NOT NULL,
    "product" TEXT NOT NULL,
    "hsn" TEXT NOT NULL DEFAULT '',
    "grade" TEXT NOT NULL DEFAULT '',
    "density" TEXT NOT NULL DEFAULT '',
    "qty" DOUBLE PRECISION NOT NULL,
    "unit" TEXT NOT NULL DEFAULT '',
    "rate" DOUBLE PRECISION NOT NULL,

    CONSTRAINT "purchase_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sales_orders" (
    "id" SERIAL NOT NULL,
    "soNumber" TEXT NOT NULL,
    "client" TEXT NOT NULL,
    "clientBadge" TEXT NOT NULL DEFAULT '',
    "date" TIMESTAMP(3) NOT NULL,
    "amount" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "status" TEXT NOT NULL DEFAULT 'Confirmed',
    "paymentStatus" TEXT NOT NULL DEFAULT 'Pending',
    "modifiedBy" TEXT NOT NULL DEFAULT 'Admin',
    "modifiedAt" TIMESTAMP(3),
    "clientAddress" TEXT NOT NULL DEFAULT '',
    "buyerGstin" TEXT NOT NULL DEFAULT '',
    "pan" TEXT NOT NULL DEFAULT '',
    "invoiceNo" TEXT NOT NULL DEFAULT '',
    "invoiceDate" TIMESTAMP(3),
    "despatchedThrough" TEXT NOT NULL DEFAULT '',
    "destination" TEXT NOT NULL DEFAULT '',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "sales_orders_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sale_items" (
    "id" SERIAL NOT NULL,
    "salesOrderId" INTEGER NOT NULL,
    "product" TEXT NOT NULL,
    "hsn" TEXT NOT NULL DEFAULT '',
    "qty" DOUBLE PRECISION NOT NULL,
    "unit" TEXT NOT NULL DEFAULT '',
    "rate" DOUBLE PRECISION NOT NULL,

    CONSTRAINT "sale_items_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "purchase_orders_poNumber_key" ON "purchase_orders"("poNumber");

-- CreateIndex
CREATE UNIQUE INDEX "sales_orders_soNumber_key" ON "sales_orders"("soNumber");

-- AddForeignKey
ALTER TABLE "purchase_items" ADD CONSTRAINT "purchase_items_purchaseOrderId_fkey" FOREIGN KEY ("purchaseOrderId") REFERENCES "purchase_orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sale_items" ADD CONSTRAINT "sale_items_salesOrderId_fkey" FOREIGN KEY ("salesOrderId") REFERENCES "sales_orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;

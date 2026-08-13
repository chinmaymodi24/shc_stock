-- CreateTable
CREATE TABLE "products" (
    "id" SERIAL NOT NULL,
    "name" TEXT NOT NULL,
    "sku" TEXT NOT NULL,
    "categoryId" INTEGER NOT NULL,
    "subCategoryId" INTEGER,
    "unit" TEXT NOT NULL,
    "sellingPrice" DOUBLE PRECISION NOT NULL,
    "costPrice" DOUBLE PRECISION NOT NULL,
    "currentStock" INTEGER NOT NULL DEFAULT 0,
    "minimumStock" INTEGER NOT NULL DEFAULT 0,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "brand" TEXT,
    "hsnCode" TEXT,
    "description" TEXT,
    "taxPercent" DOUBLE PRECISION NOT NULL DEFAULT 18.0,
    "stockLocation" TEXT NOT NULL DEFAULT 'Main Warehouse',
    "modifiedBy" TEXT NOT NULL DEFAULT 'Admin',
    "modifiedAt" TIMESTAMP(3),
    "densityVariants" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "boardVariants" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "thicknessVariants" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "reinforcementTypes" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "otherSpecs" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "products_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "products_sku_key" ON "products"("sku");

-- AddForeignKey
ALTER TABLE "products" ADD CONSTRAINT "products_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "categories"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "products" ADD CONSTRAINT "products_subCategoryId_fkey" FOREIGN KEY ("subCategoryId") REFERENCES "sub_categories"("id") ON DELETE SET NULL ON UPDATE CASCADE;

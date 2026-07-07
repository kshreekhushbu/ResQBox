-- CreateTable
CREATE TABLE "foodtype" (
    "id" SERIAL NOT NULL,
    "name" TEXT NOT NULL,
    "image" TEXT,
    "isActive" INTEGER DEFAULT 1,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "foodtype_pkey" PRIMARY KEY ("id")
);

-- AlterTable
ALTER TABLE "menu_items" ADD COLUMN "foodtypeId" INTEGER;

-- AddForeignKey
ALTER TABLE "menu_items" ADD CONSTRAINT "menu_items_foodtypeId_fkey" FOREIGN KEY ("foodtypeId") REFERENCES "foodtype"("id") ON DELETE SET NULL ON UPDATE CASCADE;

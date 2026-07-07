/*
  Warnings:

  - You are about to drop the column `expire` on the `kitchen_kyc` table. All the data in the column will be lost.
  - You are about to drop the column `cuisineId` on the `kitchens` table. All the data in the column will be lost.

*/
-- DropForeignKey
ALTER TABLE "public"."kitchens" DROP CONSTRAINT "kitchens_cuisineId_fkey";

-- AlterTable
ALTER TABLE "public"."kitchen_kyc" DROP COLUMN "expire",
ADD COLUMN     "expireDate" TIMESTAMP(3);

-- AlterTable
ALTER TABLE "public"."kitchens" DROP COLUMN "cuisineId";

-- CreateTable
CREATE TABLE "public"."_CuisineToKitchen" (
    "A" INTEGER NOT NULL,
    "B" INTEGER NOT NULL,

    CONSTRAINT "_CuisineToKitchen_AB_pkey" PRIMARY KEY ("A","B")
);

-- CreateIndex
CREATE INDEX "_CuisineToKitchen_B_index" ON "public"."_CuisineToKitchen"("B");

-- AddForeignKey
ALTER TABLE "public"."_CuisineToKitchen" ADD CONSTRAINT "_CuisineToKitchen_A_fkey" FOREIGN KEY ("A") REFERENCES "public"."cuisines"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."_CuisineToKitchen" ADD CONSTRAINT "_CuisineToKitchen_B_fkey" FOREIGN KEY ("B") REFERENCES "public"."kitchens"("kitchenId") ON DELETE CASCADE ON UPDATE CASCADE;

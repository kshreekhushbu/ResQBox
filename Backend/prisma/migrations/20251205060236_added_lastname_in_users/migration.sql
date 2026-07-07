/*
  Warnings:

  - You are about to drop the column `categoryId` on the `menu_items` table. All the data in the column will be lost.

*/
-- DropForeignKey
ALTER TABLE "public"."menu_items" DROP CONSTRAINT "menu_items_categoryId_fkey";

-- AlterTable
ALTER TABLE "public"."menu_items" DROP COLUMN "categoryId";

-- AlterTable
ALTER TABLE "public"."users" ADD COLUMN     "lastName" TEXT;

-- CreateTable
CREATE TABLE "public"."_MenuItemCategories" (
    "A" INTEGER NOT NULL,
    "B" INTEGER NOT NULL,

    CONSTRAINT "_MenuItemCategories_AB_pkey" PRIMARY KEY ("A","B")
);

-- CreateIndex
CREATE INDEX "_MenuItemCategories_B_index" ON "public"."_MenuItemCategories"("B");

-- AddForeignKey
ALTER TABLE "public"."_MenuItemCategories" ADD CONSTRAINT "_MenuItemCategories_A_fkey" FOREIGN KEY ("A") REFERENCES "public"."categories"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."_MenuItemCategories" ADD CONSTRAINT "_MenuItemCategories_B_fkey" FOREIGN KEY ("B") REFERENCES "public"."menu_items"("id") ON DELETE CASCADE ON UPDATE CASCADE;

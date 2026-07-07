/*
  Warnings:

  - You are about to drop the `AdminRoles` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `AdminUsers` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `Kitchen` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE "public"."Kitchen" DROP CONSTRAINT "Kitchen_cuisineId_fkey";

-- DropForeignKey
ALTER TABLE "public"."kitchen_address" DROP CONSTRAINT "kitchen_address_kitchenId_fkey";

-- DropForeignKey
ALTER TABLE "public"."kitchen_kyc" DROP CONSTRAINT "kitchen_kyc_kitchenId_fkey";

-- DropForeignKey
ALTER TABLE "public"."kitchen_photos" DROP CONSTRAINT "kitchen_photos_kitchenId_fkey";

-- DropForeignKey
ALTER TABLE "public"."kitchen_reviews" DROP CONSTRAINT "kitchen_reviews_kitchenId_fkey";

-- DropForeignKey
ALTER TABLE "public"."menu_items" DROP CONSTRAINT "menu_items_kitchenId_fkey";

-- DropForeignKey
ALTER TABLE "public"."orders" DROP CONSTRAINT "orders_kitchenId_fkey";

-- DropForeignKey
ALTER TABLE "public"."wishlist" DROP CONSTRAINT "wishlist_kitchenId_fkey";

-- DropTable
DROP TABLE "public"."AdminRoles";

-- DropTable
DROP TABLE "public"."AdminUsers";

-- DropTable
DROP TABLE "public"."Kitchen";

-- CreateTable
CREATE TABLE "public"."admin_users" (
    "adminId" SERIAL NOT NULL,
    "name" TEXT NOT NULL,
    "emailId" VARCHAR(75) NOT NULL,
    "password" TEXT NOT NULL,
    "roleId" INTEGER NOT NULL,
    "token" TEXT NOT NULL,
    "status" INTEGER NOT NULL DEFAULT 1,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "otp" TEXT,
    "otpStatus" INTEGER,

    CONSTRAINT "admin_users_pkey" PRIMARY KEY ("adminId")
);

-- CreateTable
CREATE TABLE "public"."admin_roles" (
    "id" SERIAL NOT NULL,
    "role" VARCHAR(50) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "permissions" JSONB,

    CONSTRAINT "admin_roles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."kitchens" (
    "kitchenId" SERIAL NOT NULL,
    "password" TEXT NOT NULL,
    "kitchenName" TEXT NOT NULL,
    "email" TEXT,
    "ownerName" TEXT,
    "contactNumber" TEXT,
    "openingTime" TEXT,
    "closingTime" TEXT,
    "description" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "status" "public"."KitchenStatus" NOT NULL DEFAULT 'PENDING',
    "isActive" INTEGER NOT NULL DEFAULT 1,
    "rating" DECIMAL(65,30) NOT NULL DEFAULT 0,
    "ratingCount" INTEGER NOT NULL DEFAULT 0,
    "deviceToken" TEXT,
    "cuisineId" INTEGER,

    CONSTRAINT "kitchens_pkey" PRIMARY KEY ("kitchenId")
);

-- CreateIndex
CREATE UNIQUE INDEX "admin_roles_role_key" ON "public"."admin_roles"("role");

-- AddForeignKey
ALTER TABLE "public"."kitchens" ADD CONSTRAINT "kitchens_cuisineId_fkey" FOREIGN KEY ("cuisineId") REFERENCES "public"."cuisines"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."kitchen_address" ADD CONSTRAINT "kitchen_address_kitchenId_fkey" FOREIGN KEY ("kitchenId") REFERENCES "public"."kitchens"("kitchenId") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."kitchen_kyc" ADD CONSTRAINT "kitchen_kyc_kitchenId_fkey" FOREIGN KEY ("kitchenId") REFERENCES "public"."kitchens"("kitchenId") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."kitchen_photos" ADD CONSTRAINT "kitchen_photos_kitchenId_fkey" FOREIGN KEY ("kitchenId") REFERENCES "public"."kitchens"("kitchenId") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."menu_items" ADD CONSTRAINT "menu_items_kitchenId_fkey" FOREIGN KEY ("kitchenId") REFERENCES "public"."kitchens"("kitchenId") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."orders" ADD CONSTRAINT "orders_kitchenId_fkey" FOREIGN KEY ("kitchenId") REFERENCES "public"."kitchens"("kitchenId") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."wishlist" ADD CONSTRAINT "wishlist_kitchenId_fkey" FOREIGN KEY ("kitchenId") REFERENCES "public"."kitchens"("kitchenId") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."kitchen_reviews" ADD CONSTRAINT "kitchen_reviews_kitchenId_fkey" FOREIGN KEY ("kitchenId") REFERENCES "public"."kitchens"("kitchenId") ON DELETE RESTRICT ON UPDATE CASCADE;

/*
  Warnings:

  - You are about to drop the `Permission` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `_RolePermissions` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE "public"."_RolePermissions" DROP CONSTRAINT "_RolePermissions_A_fkey";

-- DropForeignKey
ALTER TABLE "public"."_RolePermissions" DROP CONSTRAINT "_RolePermissions_B_fkey";

-- DropForeignKey
ALTER TABLE "public"."admin_users" DROP CONSTRAINT "admin_users_roleId_fkey";

-- AlterTable
ALTER TABLE "public"."admin_roles" ADD COLUMN     "permissions" JSONB;

-- DropTable
DROP TABLE "public"."Permission";

-- DropTable
DROP TABLE "public"."_RolePermissions";

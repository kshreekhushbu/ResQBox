-- CreateEnum
CREATE TYPE "public"."LinkType" AS ENUM ('INTERNAL', 'EXTERNAL');

-- CreateEnum
CREATE TYPE "public"."CouponType" AS ENUM ('FLAT', 'PERCENTAGE');

-- CreateEnum
CREATE TYPE "public"."AddressType" AS ENUM ('HOME', 'WORK', 'OTHER');

-- CreateEnum
CREATE TYPE "public"."KitchenStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED');

-- CreateEnum
CREATE TYPE "public"."DeliveryType" AS ENUM ('PICKUP');

-- CreateEnum
CREATE TYPE "public"."OrderStatus" AS ENUM ('PENDING', 'ACCEPTED', 'PREPARING', 'READY', 'OUT_FOR_DELIVERY', 'DELIVERED', 'CANCELLED', 'REJECTED');

-- CreateEnum
CREATE TYPE "public"."PaymentMethod" AS ENUM ('COD', 'ONLINE');

-- CreateEnum
CREATE TYPE "public"."PaymentStatus" AS ENUM ('PENDING', 'PAID', 'FAILED', 'REFUNDED');

-- CreateEnum
CREATE TYPE "public"."UserRole" AS ENUM ('USER', 'KITCHEN');

-- CreateEnum
CREATE TYPE "public"."AdminRole" AS ENUM ('SUPER_ADMIN', 'ADMIN');

-- CreateEnum
CREATE TYPE "public"."SpicyLevel" AS ENUM ('NORMAL', 'MEDIUM', 'EXTRA_SPICY');

-- CreateTable
CREATE TABLE "public"."AdminUsers" (
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

    CONSTRAINT "AdminUsers_pkey" PRIMARY KEY ("adminId")
);

-- CreateTable
CREATE TABLE "public"."AdminRoles" (
    "id" SERIAL NOT NULL,
    "role" VARCHAR(50) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "permissions" JSONB,

    CONSTRAINT "AdminRoles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."banners" (
    "bannerId" SERIAL NOT NULL,
    "banner" TEXT,
    "isActive" INTEGER NOT NULL DEFAULT 1,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "linkUrl" TEXT,
    "linkType" "public"."LinkType",

    CONSTRAINT "banners_pkey" PRIMARY KEY ("bannerId")
);

-- CreateTable
CREATE TABLE "public"."users" (
    "userId" SERIAL NOT NULL,
    "phoneNumber" TEXT NOT NULL,
    "name" TEXT,
    "email" TEXT,
    "profilePicture" TEXT,
    "deviceToken" TEXT,
    "latitude" DOUBLE PRECISION,
    "longitude" DOUBLE PRECISION,
    "isActive" INTEGER NOT NULL DEFAULT 1,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("userId")
);

-- CreateTable
CREATE TABLE "public"."verify_mobile_number" (
    "id" SERIAL NOT NULL,
    "phoneNumber" TEXT NOT NULL,
    "otp" TEXT NOT NULL,
    "isVerified" INTEGER NOT NULL DEFAULT 0,
    "status" INTEGER NOT NULL DEFAULT 1,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "verify_mobile_number_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."Kitchen" (
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

    CONSTRAINT "Kitchen_pkey" PRIMARY KEY ("kitchenId")
);

-- CreateTable
CREATE TABLE "public"."kitchen_address" (
    "addressId" SERIAL NOT NULL,
    "kitchenId" INTEGER NOT NULL,
    "houseNo" TEXT,
    "street" TEXT,
    "pincode" TEXT,
    "state" TEXT,
    "city" TEXT,
    "country" TEXT,
    "landmark" TEXT,
    "latitude" DOUBLE PRECISION,
    "longitude" DOUBLE PRECISION,

    CONSTRAINT "kitchen_address_pkey" PRIMARY KEY ("addressId")
);

-- CreateTable
CREATE TABLE "public"."kitchen_kyc" (
    "kycId" SERIAL NOT NULL,
    "kitchenId" INTEGER NOT NULL,
    "abnNumber" TEXT,
    "acn" TEXT,
    "foodCertificateNumber" TEXT,
    "foodCertificateImage" TEXT,
    "expire" TEXT,
    "fssaiNumber" TEXT,

    CONSTRAINT "kitchen_kyc_pkey" PRIMARY KEY ("kycId")
);

-- CreateTable
CREATE TABLE "public"."kitchen_photos" (
    "id" SERIAL NOT NULL,
    "kitchenId" INTEGER NOT NULL,
    "kitchenImages" JSONB,
    "kitchenProfilePhoto" TEXT,

    CONSTRAINT "kitchen_photos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."menu_items" (
    "id" SERIAL NOT NULL,
    "kitchenId" INTEGER NOT NULL,
    "name" TEXT NOT NULL,
    "categoryId" INTEGER NOT NULL,
    "quantity" INTEGER NOT NULL,
    "price" DOUBLE PRECISION NOT NULL,
    "discountPrice" DOUBLE PRECISION NOT NULL,
    "description" TEXT,
    "image" TEXT,
    "isVegetarian" BOOLEAN NOT NULL DEFAULT false,
    "isSpicy" "public"."SpicyLevel" NOT NULL DEFAULT 'NORMAL',
    "isActive" INTEGER NOT NULL DEFAULT 1,
    "startTime" TEXT,
    "endTime" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "rating" DECIMAL(3,2) NOT NULL DEFAULT 0,
    "ratingCount" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "menu_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."categories" (
    "id" SERIAL NOT NULL,
    "name" TEXT NOT NULL,
    "isActive" INTEGER NOT NULL DEFAULT 1,
    "image" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "categories_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."cuisines" (
    "id" SERIAL NOT NULL,
    "name" TEXT NOT NULL,
    "isActive" INTEGER NOT NULL DEFAULT 1,
    "image" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "cuisines_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."cart" (
    "cartId" SERIAL NOT NULL,
    "userId" INTEGER NOT NULL,
    "isActive" INTEGER NOT NULL DEFAULT 1,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "cart_pkey" PRIMARY KEY ("cartId")
);

-- CreateTable
CREATE TABLE "public"."cart_items" (
    "cartItemId" SERIAL NOT NULL,
    "cartId" INTEGER NOT NULL,
    "menuItemId" INTEGER NOT NULL,
    "quantity" INTEGER NOT NULL DEFAULT 1,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "cart_items_pkey" PRIMARY KEY ("cartItemId")
);

-- CreateTable
CREATE TABLE "public"."orders" (
    "orderId" SERIAL NOT NULL,
    "userId" INTEGER NOT NULL,
    "kitchenId" INTEGER NOT NULL,
    "deliveryType" "public"."DeliveryType" NOT NULL DEFAULT 'PICKUP',
    "deliveryAddress" JSONB,
    "status" "public"."OrderStatus" NOT NULL DEFAULT 'PENDING',
    "itemTotal" DOUBLE PRECISION NOT NULL,
    "gstAmount" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "platformFee" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "discount" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "totalAmount" DOUBLE PRECISION NOT NULL,
    "paymentMethod" "public"."PaymentMethod",
    "paymentStatus" "public"."PaymentStatus" NOT NULL DEFAULT 'PENDING',
    "orderedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "distance" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "acceptedAt" TIMESTAMP(3),
    "cancelReason" TEXT,
    "cancelledAt" TIMESTAMP(3),
    "rating" DECIMAL(3,2) NOT NULL DEFAULT 0,

    CONSTRAINT "orders_pkey" PRIMARY KEY ("orderId")
);

-- CreateTable
CREATE TABLE "public"."order_items" (
    "orderItemId" SERIAL NOT NULL,
    "orderId" INTEGER NOT NULL,
    "menuItemId" INTEGER NOT NULL,
    "quantity" INTEGER NOT NULL,
    "price" DOUBLE PRECISION NOT NULL,
    "totalPrice" DOUBLE PRECISION NOT NULL,
    "itemQuantityLabel" TEXT,

    CONSTRAINT "order_items_pkey" PRIMARY KEY ("orderItemId")
);

-- CreateTable
CREATE TABLE "public"."config" (
    "configId" SERIAL NOT NULL,
    "configKey" VARCHAR(45) NOT NULL DEFAULT 'NA',
    "configValue" VARCHAR(45) NOT NULL DEFAULT 'NA',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "config_pkey" PRIMARY KEY ("configId")
);

-- CreateTable
CREATE TABLE "public"."wishlist" (
    "id" SERIAL NOT NULL,
    "userId" INTEGER NOT NULL,
    "kitchenId" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "wishlist_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."coupons" (
    "couponId" SERIAL NOT NULL,
    "adminId" INTEGER NOT NULL,
    "couponCode" TEXT NOT NULL,
    "description" TEXT,
    "startDate" TIMESTAMP(3) NOT NULL,
    "endDate" TIMESTAMP(3) NOT NULL,
    "type" "public"."CouponType" NOT NULL,
    "title" TEXT DEFAULT 'NA',
    "offerValue" DOUBLE PRECISION NOT NULL,
    "maxDiscount" DOUBLE PRECISION NOT NULL,
    "minOrderAmount" DOUBLE PRECISION,
    "status" INTEGER NOT NULL DEFAULT 1,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "coupons_pkey" PRIMARY KEY ("couponId")
);

-- CreateTable
CREATE TABLE "public"."kitchen_reviews" (
    "id" SERIAL NOT NULL,
    "orderId" INTEGER NOT NULL,
    "userId" INTEGER NOT NULL,
    "kitchenId" INTEGER NOT NULL,
    "rating" DECIMAL(3,2) NOT NULL,
    "review" TEXT,
    "images" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "kitchen_reviews_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."notifications" (
    "id" SERIAL NOT NULL,
    "ownerId" INTEGER NOT NULL,
    "ownerType" "public"."UserRole" NOT NULL DEFAULT 'USER',
    "title" TEXT NOT NULL,
    "message" TEXT NOT NULL,
    "type" INTEGER NOT NULL DEFAULT 1,
    "isRead" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notifications_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "AdminRoles_role_key" ON "public"."AdminRoles"("role");

-- CreateIndex
CREATE UNIQUE INDEX "users_phoneNumber_key" ON "public"."users"("phoneNumber");

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "public"."users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "verify_mobile_number_phoneNumber_key" ON "public"."verify_mobile_number"("phoneNumber");

-- CreateIndex
CREATE INDEX "verify_mobile_number_phoneNumber_isVerified_status_idx" ON "public"."verify_mobile_number"("phoneNumber", "isVerified", "status");

-- CreateIndex
CREATE UNIQUE INDEX "kitchen_address_kitchenId_key" ON "public"."kitchen_address"("kitchenId");

-- CreateIndex
CREATE UNIQUE INDEX "kitchen_kyc_kitchenId_key" ON "public"."kitchen_kyc"("kitchenId");

-- CreateIndex
CREATE UNIQUE INDEX "kitchen_photos_kitchenId_key" ON "public"."kitchen_photos"("kitchenId");

-- CreateIndex
CREATE UNIQUE INDEX "wishlist_userId_kitchenId_key" ON "public"."wishlist"("userId", "kitchenId");

-- CreateIndex
CREATE UNIQUE INDEX "kitchen_reviews_orderId_key" ON "public"."kitchen_reviews"("orderId");

-- AddForeignKey
ALTER TABLE "public"."Kitchen" ADD CONSTRAINT "Kitchen_cuisineId_fkey" FOREIGN KEY ("cuisineId") REFERENCES "public"."cuisines"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."kitchen_address" ADD CONSTRAINT "kitchen_address_kitchenId_fkey" FOREIGN KEY ("kitchenId") REFERENCES "public"."Kitchen"("kitchenId") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."kitchen_kyc" ADD CONSTRAINT "kitchen_kyc_kitchenId_fkey" FOREIGN KEY ("kitchenId") REFERENCES "public"."Kitchen"("kitchenId") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."kitchen_photos" ADD CONSTRAINT "kitchen_photos_kitchenId_fkey" FOREIGN KEY ("kitchenId") REFERENCES "public"."Kitchen"("kitchenId") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."menu_items" ADD CONSTRAINT "menu_items_kitchenId_fkey" FOREIGN KEY ("kitchenId") REFERENCES "public"."Kitchen"("kitchenId") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."menu_items" ADD CONSTRAINT "menu_items_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "public"."categories"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."cart" ADD CONSTRAINT "cart_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."users"("userId") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."cart_items" ADD CONSTRAINT "cart_items_cartId_fkey" FOREIGN KEY ("cartId") REFERENCES "public"."cart"("cartId") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."cart_items" ADD CONSTRAINT "cart_items_menuItemId_fkey" FOREIGN KEY ("menuItemId") REFERENCES "public"."menu_items"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."orders" ADD CONSTRAINT "orders_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."users"("userId") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."orders" ADD CONSTRAINT "orders_kitchenId_fkey" FOREIGN KEY ("kitchenId") REFERENCES "public"."Kitchen"("kitchenId") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."order_items" ADD CONSTRAINT "order_items_menuItemId_fkey" FOREIGN KEY ("menuItemId") REFERENCES "public"."menu_items"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."order_items" ADD CONSTRAINT "order_items_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "public"."orders"("orderId") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."wishlist" ADD CONSTRAINT "wishlist_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."users"("userId") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."wishlist" ADD CONSTRAINT "wishlist_kitchenId_fkey" FOREIGN KEY ("kitchenId") REFERENCES "public"."Kitchen"("kitchenId") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."kitchen_reviews" ADD CONSTRAINT "kitchen_reviews_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "public"."orders"("orderId") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."kitchen_reviews" ADD CONSTRAINT "kitchen_reviews_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."users"("userId") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."kitchen_reviews" ADD CONSTRAINT "kitchen_reviews_kitchenId_fkey" FOREIGN KEY ("kitchenId") REFERENCES "public"."Kitchen"("kitchenId") ON DELETE RESTRICT ON UPDATE CASCADE;

export interface Invoice {
  invoiceId: number;
  invoiceNumber: string;
  date?: string;
  restaurantName: string;
  restaurantId?: number;
  restaurantCode: string;
  kitchenId: number;
  numberOfOrders?: number;
  ordersCount?: number;
  invoicedAmount?: number;
  totalOrderAmount?: number;
  netAmount?: number;
  platformFeeAmount?: number;
  periodStart: string;
  periodEnd: string;
  invoice?: string;
  pdfUrl?: string;
  stripeTransferId?: string;
  month?: number;
  year?: number;
  createdAt?: string;
}

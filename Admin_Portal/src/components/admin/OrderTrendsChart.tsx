import { TrendingUp, Package } from "lucide-react";
import { Bar, BarChart, CartesianGrid, Rectangle, XAxis, YAxis } from "recharts";

import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import {
  ChartConfig,
  ChartContainer,
  ChartTooltip,
  ChartTooltipContent,
} from "@/components/ui/chart";

const chartConfig = {
  orders: {
    label: "Orders",
    color: "hsl(var(--primary))",
    icon: Package,
  },
} satisfies ChartConfig;

interface OrderTrendsChartProps {
  data?: { month: string; orders: number }[];
  loading?: boolean;
}

export function OrderTrendsChart({ data = [], loading = false }: OrderTrendsChartProps) {
  const currentMonth = data[data.length - 1]?.orders || 0;
  const previousMonth = data[data.length - 2]?.orders || 1;
  const trend = ((currentMonth - previousMonth) / previousMonth) * 100;
  const isPositive = trend >= 0;

  return (
    <Card className="hover-lift border card-shadow">
      <CardHeader>
        <CardTitle className="text-lg font-semibold">Monthly Order Trends</CardTitle>
        <CardDescription>
          {data[0]?.month} - {data[data.length - 1]?.month}
        </CardDescription>
      </CardHeader>
      <CardContent className="pb-2">
        {loading ? (
          <div className="h-[300px] w-full flex items-center justify-center">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary/60"></div>
          </div>
        ) : (
          <ChartContainer config={chartConfig} className="min-h-[300px] w-full">
            <BarChart accessibilityLayer data={data} margin={{ top: 20, right: 10, left: -10, bottom: 0 }}>
              <CartesianGrid vertical={false} strokeDasharray="3 3" stroke="hsl(var(--primary) / 0.1)" />
              <XAxis
                dataKey="month"
                tickLine={false}
                tickMargin={10}
                axisLine={false}
                tickFormatter={(value) => value.split(' ')[0]}
                stroke="hsl(var(--primary) / 0.5)"
                fontSize={11}
                fontWeight={600}
              />
              <YAxis
                tickLine={false}
                axisLine={false}
                tickMargin={10}
                stroke="hsl(var(--primary) / 0.5)"
                fontSize={11}
                fontWeight={600}
              />
              <ChartTooltip
                cursor={false}
                content={<ChartTooltipContent hideLabel indicator="dashed" />}
              />
              <Bar
                dataKey="orders"
                fill="var(--color-orders)"
                radius={[4, 4, 0, 0]}
                barSize={32}
                activeBar={({ ...props }) => {
                  return (
                    <Rectangle
                      {...props}
                      fillOpacity={0.8}
                      stroke="var(--color-orders)"
                      strokeWidth={1}
                    />
                  )
                }}
              />
            </BarChart>
          </ChartContainer>
        )}
      </CardContent>
    </Card>
  );
}

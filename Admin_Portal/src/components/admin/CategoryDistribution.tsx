import * as React from "react";
import { Label, Pie, PieChart } from "recharts";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";

import {
  ChartConfig,
  ChartContainer,
  ChartLegend,
  ChartLegendContent,
  ChartTooltip,
  ChartTooltipContent,
} from "@/components/ui/chart";

interface CategoryDistributionProps {
  data?: { name: string }[];
  loading?: boolean;
}

export function CategoryDistribution({ data = [], loading = false }: CategoryDistributionProps) {
  const chartData = React.useMemo(() => {
    const colors = [
      "hsl(145 63% 42%)", // Primary Green
      "hsl(24 95% 53%)",  // Theme Orange
      "hsl(160 84% 39%)", // Emerald
      "hsl(32 95% 44%)",  // Amber
      "hsl(145 80% 60%)", // Light Green
      "hsl(199 89% 48%)", // Sky Blue
    ];

    if (data && data.length > 0) {
      return data.map((item, index) => ({
        category: item.name,
        value: Math.floor(Math.random() * 40) + 10,
        fill: colors[index % colors.length],
      }));
    }

    return [
      { category: "Vegetarian", value: 35, fill: colors[0] },
      { category: "Non-Veg", value: 28, fill: colors[1] },
      { category: "Vegan", value: 18, fill: colors[2] },
      { category: "Halal", value: 12, fill: colors[3] },
      { category: "Other", value: 7, fill: colors[4] },
    ];
  }, [data]);

  const dynamicConfig = React.useMemo(() => {
    const config: ChartConfig = {
      category: {
        label: "Category",
      },
    };
    chartData.forEach((item) => {
      config[item.category] = {
        label: item.category,
      };
    });
    return config;
  }, [chartData]);

  const totalValue = React.useMemo(() => {
    return chartData.reduce((acc, curr) => acc + curr.value, 0);
  }, [chartData]);

  if (loading) {
    return (
      <Card className="flex flex-col border card-shadow h-full min-h-[400px]">
        <CardHeader className="items-start pb-0">
          <CardTitle className="text-lg font-semibold">Category Distribution</CardTitle>
          <CardDescription>Loading distribution data...</CardDescription>
        </CardHeader>
        <CardContent className="flex-1 flex items-center justify-center">
          <div className="h-48 w-48 rounded-full border-4 border-primary/20 border-t-primary animate-spin" />
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className="flex flex-col hover-lift border card-shadow group">
      <CardHeader className="items-start pb-0">
        <CardTitle className="text-lg font-semibold group-hover:text-primary transition-colors">
          Food Restaurant Types Distribution
        </CardTitle>
        <CardDescription>Based on active restaurant menus</CardDescription>
      </CardHeader>
      <CardContent className="flex-1 pb-4">
        <ChartContainer
          config={dynamicConfig}
          className="mx-auto aspect-auto h-[300px]"
        >
          <PieChart>
            <ChartTooltip
              cursor={false}
              content={<ChartTooltipContent hideLabel />}
            />
            <Pie
              data={chartData}
              dataKey="value"
              nameKey="category"
              innerRadius={70}
              strokeWidth={8}
              stroke="hsl(var(--background))"
              paddingAngle={2}
            >
              <Label
                content={({ viewBox }) => {
                  if (viewBox && "cx" in viewBox && "cy" in viewBox) {
                    return (
                      <text
                        x={viewBox.cx}
                        y={viewBox.cy}
                        textAnchor="middle"
                        dominantBaseline="middle"
                      >
                        <tspan
                          x={viewBox.cx}
                          y={viewBox.cy}
                          className="fill-primary text-4xl font-black tracking-tighter"
                        >
                          {totalValue.toLocaleString()}
                        </tspan>
                        <tspan
                          x={viewBox.cx}
                          y={(viewBox.cy || 0) + 28}
                          className="fill-muted-foreground text-[10px] uppercase font-bold tracking-[0.2em]"
                        >
                          Total Items
                        </tspan>
                      </text>
                    );
                  }
                }}
              />
            </Pie>
            <ChartLegend
              content={<ChartLegendContent nameKey="category" />}
              className="mt-4 flex-wrap justify-center gap-x-3 gap-y-1"
            />
          </PieChart>
        </ChartContainer>
      </CardContent>
    </Card>
  );
}

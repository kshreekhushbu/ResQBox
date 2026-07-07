import { useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { useDispatch, useSelector } from "react-redux";
import { AppDispatch, RootState } from "@/store/store";
import { getDashboardData } from "@/features/dashboard/dashboardSlice";
import { StatCard } from "@/components/admin/StatCard";
import { QuickActions } from "@/components/admin/QuickActions";
import { OrderTrendsChart } from "@/components/admin/OrderTrendsChart";
import {
  DashboardSkeleton,
  WelcomeHeader,
} from "@/components/admin/DashboardSkeleton";
import { ErrorDisplay } from "@/components/ErrorDisplay/ErrorDisplay";
import { CategoryDistribution } from "@/components/admin/CategoryDistribution";
import {
  Store,
  Clock,
  CheckCircle,
  Package,
  Users,
  AlertCircle,
  TrendingUp,
  Leaf,
  DollarSign,
} from "lucide-react";
import { usePermissions } from "@/hooks/usePermissions";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";

const Dashboard: React.FC = () => {
  const navigate = useNavigate();
  const dispatch = useDispatch<AppDispatch>();
  const permissions = usePermissions("dashboard");

  const { data, isLoading, error } = useSelector(
    (state: RootState) => state.dashboard
  );

  useEffect(() => {
    if (!permissions.hasRead) {
      navigate("/403", { replace: true });
    }
  }, [permissions.hasRead, navigate]);

  useEffect(() => {
    dispatch(getDashboardData());
  }, [dispatch]);

  if (!permissions.hasRead) return null;

  if (isLoading && !data) {
    return (
      <div className="space-y-6">
        <WelcomeHeader loading />
        <DashboardSkeleton />
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <ErrorDisplay
          message={error}
          getdata={() => dispatch(getDashboardData())}
        />
      </div>
    );
  }

  if (!data) return null;

  return (
    <div className="space-y-8 animate-in fade-in duration-700 pb-10">
      <WelcomeHeader />
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <StatCard
          title="TOTAL RESTAURANTS"
          value={data.totalRestaurants}
          icon={Store}
          variant="default"
          onClick={() => navigate('/restaurants')}
        />
        <StatCard
          title="PENDING APPROVALS"
          value={data.pendingApprovals}
          icon={Clock}
          variant="warning"
          onClick={() => navigate('/restaurants?status=PENDING')}
        />
        <StatCard
          title="APPROVED"
          value={data.approvedRestaurants}
          icon={CheckCircle}
          variant="success"
          onClick={() => navigate('/restaurants?status=APPROVED')}
        />
        <StatCard
          title="TOTAL ORDERS"
          value={data.totalOrders}
          icon={Package}
          variant="info"
          onClick={() => navigate('/orders')}
        />
        <StatCard
          title="TOTAL USERS"
          value={data.totalUsers}
          icon={Users}
          variant="success"
          onClick={() => navigate('/users')}
        />
        <StatCard
          title="EXPIRING SOON"
          value={data.expiringSoon}
          icon={AlertCircle}
          variant="warning"
          onClick={() => navigate('/restaurants?status=EXPIRING')}
        />
      </div>
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 items-stretch">
        <div className="h-full">
          <OrderTrendsChart
            data={data.monthlyOrderTrends}
            loading={isLoading}
          />
        </div>
        <div className="h-full">
          <CategoryDistribution data={data.foodTypes} loading={isLoading} />
        </div>
      </div>
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-stretch">
        <div className="lg:col-span-4 h-full">
          <QuickActions />
        </div>

        <div className="lg:col-span-8 grid grid-cols-1 md:grid-cols-2 gap-6">
          <Card className="group relative overflow-hidden border-border/50 bg-gradient-to-br from-emerald-500/5 via-emerald-500/0 to-transparent hover:shadow-xl hover:shadow-emerald-500/5 transition-all duration-300 hover:border-emerald-500/20">
            <div className="absolute top-0 right-0 p-4 opacity-[0.03] group-hover:opacity-[0.08] transition-opacity pointer-events-none">
              <Leaf className="w-32 h-32 text-emerald-500 transform rotate-12 group-hover:scale-110 transition-transform duration-500" />
            </div>
            <CardContent className="p-6 relative">
              <div className="flex items-center gap-4 mb-6">
                <div className="p-3.5 rounded-2xl bg-gradient-to-br from-emerald-500/10 to-emerald-500/5 text-emerald-600 ring-1 ring-emerald-500/20 shadow-sm group-hover:scale-110 transition-transform duration-500">
                  <Leaf className="w-6 h-6" />
                </div>
                <div>
                  <h3 className="font-semibold text-sm text-muted-foreground uppercase tracking-wider">
                    Impact Today
                  </h3>
                  <p className="font-bold text-lg text-foreground">
                    Meals Saved
                  </p>
                </div>
              </div>
              <div className="space-y-4">
                <p className="text-5xl font-bold text-foreground tracking-tight tabular-nums">
                  {data?.todayorders || 0}
                </p>
                <div className="flex items-center gap-2 text-sm text-emerald-600 font-medium bg-emerald-500/10 w-fit px-3 py-1.5 rounded-full border border-emerald-500/10">
                  <TrendingUp className="h-4 w-4" />
                  <span>Saved from waste today</span>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card className="group relative overflow-hidden border-border/50 bg-gradient-to-br from-orange-500/5 via-orange-500/0 to-transparent hover:shadow-xl hover:shadow-orange-500/5 transition-all duration-300 hover:border-orange-500/20">
            <div className="absolute top-0 right-0 p-4 opacity-[0.03] group-hover:opacity-[0.08] transition-opacity pointer-events-none">
              <DollarSign className="w-32 h-32 text-orange-500 transform -rotate-12 group-hover:scale-110 transition-transform duration-500" />
            </div>
            <CardContent className="p-6 relative">
              <div className="flex items-center gap-4 mb-6">
                <div className="p-3.5 rounded-2xl bg-gradient-to-br from-orange-500/10 to-orange-500/5 text-orange-600 ring-1 ring-orange-500/20 shadow-sm group-hover:scale-110 transition-transform duration-500">
                  <DollarSign className="w-6 h-6" />
                </div>
                <div>
                  <h3 className="font-semibold text-sm text-muted-foreground uppercase tracking-wider">
                    Platform Revenue
                  </h3>
                  <p className="font-bold text-lg text-foreground">
                    Total Earnings
                  </p>
                </div>
              </div>
              <div className="space-y-4">
                <p
                  className="text-5xl font-bold text-foreground tracking-tight tabular-nums truncate"
                  title={data?.monthlyAmount?.toString()}
                >
                  {Number(data?.monthlyAmount || 0).toFixed(2)}
                </p>
                <div className="flex items-center gap-2 text-sm text-orange-600 font-medium bg-orange-500/10 w-fit px-3 py-1.5 rounded-full border border-orange-500/10">
                  <Clock className="h-4 w-4" />
                  <span>Earnings this month</span>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;

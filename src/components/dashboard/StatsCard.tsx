import { cn } from "@/lib/utils";
import { TrendingUp, TrendingDown } from "lucide-react";

interface StatsCardProps {
  title: string;
  value: string | number;
  subtitle?: string;
  icon: React.ReactNode;
  trend?: number;
  trendLabel?: string;
  gradient?: string;
  iconBg?: string;
}

export default function StatsCard({
  title,
  value,
  subtitle,
  icon,
  trend,
  trendLabel,
  gradient = "from-white to-white",
  iconBg = "bg-[#16a34a]",
}: StatsCardProps) {
  const isPositive = trend !== undefined && trend >= 0;

  return (
    <div className={cn(
      "rounded-2xl border border-gray-100 bg-gradient-to-br p-6 shadow-sm hover:shadow-lg transition-all duration-300 hover:-translate-y-0.5",
      gradient
    )}>
      <div className="flex items-start justify-between">
        <div>
          <p className="text-sm font-medium text-gray-500 mb-1">{title}</p>
          <p className="text-3xl font-bold text-gray-900 tracking-tight">{value}</p>
          {subtitle && (
            <p className="text-xs text-gray-400 mt-1">{subtitle}</p>
          )}
        </div>
        <div className={cn(
          "w-12 h-12 rounded-2xl flex items-center justify-center text-white shadow-md",
          iconBg
        )}>
          {icon}
        </div>
      </div>
      {trend !== undefined && (
        <div className="mt-4 flex items-center gap-1.5">
          <div className={cn(
            "flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-semibold",
            isPositive
              ? "bg-green-100 text-green-700"
              : "bg-red-100 text-red-700"
          )}>
            {isPositive ? <TrendingUp size={12} /> : <TrendingDown size={12} />}
            {Math.abs(trend)}%
          </div>
          <span className="text-xs text-gray-400">{trendLabel ?? "o'tgan oyga nisbatan"}</span>
        </div>
      )}
    </div>
  );
}

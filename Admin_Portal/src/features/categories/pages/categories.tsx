import { useState, useEffect, useCallback } from "react";
import { useDispatch, useSelector } from "react-redux";
import { useNavigate, useSearchParams } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { Badge } from "@/components/ui/badge";
import { Plus, Edit, Trash2, Search, Utensils, Store, Layers, UtensilsCrossed } from "lucide-react";
import { Input } from "@/components/ui/input";
import Pagination from "@/components/Pagination/Pagination";
import { useToast } from "@/hooks/use-toast";
import { AppDispatch, RootState } from "@/store/store";
import { toast as sonnerToast } from "sonner";
import {
  getAllCategories,
  editCategory,
  removeCategory,
  clearError,
} from "../categoriesSlice";
import {
  getAllCuisines,
  editCuisine,
  removeCuisine,
  clearError as clearCuisineError,
} from "@/features/cuisines/cuisinesSlice";
import {
  getAllFoodTypesThunk,
  updateFoodTypeThunk,
  deleteFoodTypeThunk,
  clearError as clearFoodTypeError,
} from "@/features/foodTypes/foodTypesSlice";
import {
  getAllMenuTypesThunk,
  updateMenuTypeThunk,
  deleteMenuTypeThunk,
  clearError as clearMenuTypeError,
} from "@/features/menuTypes/menuTypesSlice";
import { Category } from "../types";
import { Cuisine } from "@/features/cuisines/types";
import { FoodType } from "@/features/foodTypes/types";
import { MenuType } from "@/features/menuTypes/types";
import { CategoryFormModal } from "./addCategory";
import { CuisineFormModal } from "@/features/cuisines/pages/addCuisine";
import { FoodTypeFormModal } from "@/features/foodTypes/pages/addFoodType";
import { MenuTypeFormModal } from "@/features/menuTypes/pages/addMenuType";
import { DynamicTable, TableColumn } from "@/components/table/DynamicTable";
import { usePermissions } from "@/hooks/usePermissions";
import fallbackCuisineImage from "@assets/image.png";
import debounce from "lodash/debounce";

const Categories: React.FC = () => {
  const dispatch = useDispatch<AppDispatch>();
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();
  const permissions = usePermissions("categories");
  const {
    categories,
    loading,
    error,
    pagination: categoriesPagination,
  } = useSelector((state: RootState) => state.categories);
  const {
    cuisines,
    loading: cuisinesLoading,
    error: cuisinesError,
    pagination: cuisinesPagination,
  } = useSelector((state: RootState) => state.cuisines);
  const {
    foodTypes,
    loading: foodTypesLoading,
    error: foodTypesError,
    pagination: foodTypesPagination,
  } = useSelector((state: RootState) => state.foodTypes);
  const {
    menuTypes,
    loading: menuTypesLoading,
    error: menuTypesError,
    pagination: menuTypesPagination,
  } = useSelector((state: RootState) => state.menuTypes);

  const [activeTab, setActiveTab] = useState<
    "food" | "restaurant" | "foodTypes" | "menuTypes"
  >("food");
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isCuisineModalOpen, setIsCuisineModalOpen] = useState(false);
  const [isFoodTypeModalOpen, setIsFoodTypeModalOpen] = useState(false);
  const [isMenuTypeModalOpen, setIsMenuTypeModalOpen] = useState(false);
  const [modalMode, setModalMode] = useState<"add" | "edit">("add");
  const [selectedCategory, setSelectedCategory] = useState<Category | null>(
    null
  );
  const [selectedCuisine, setSelectedCuisine] = useState<Cuisine | null>(null);
  const [selectedFoodType, setSelectedFoodType] = useState<FoodType | null>(
    null
  );
  const [selectedMenuType, setSelectedMenuType] = useState<MenuType | null>(
    null
  );
  const [selectedCategoryId, setSelectedCategoryId] = useState<string | null>(
    null
  );
  const [selectedCuisineId, setSelectedCuisineId] = useState<string | null>(
    null
  );
  const [selectedFoodTypeId, setSelectedFoodTypeId] = useState<string | null>(
    null
  );
  const [selectedMenuTypeId, setSelectedMenuTypeId] = useState<string | null>(
    null
  );
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [categoryToDelete, setCategoryToDelete] = useState<number | null>(null);
  const [cuisineToDelete, setCuisineToDelete] = useState<number | null>(null);
  const [foodTypeToDelete, setFoodTypeToDelete] = useState<number | null>(null);
  const [menuTypeToDelete, setMenuTypeToDelete] = useState<number | null>(null);
  const { toast } = useToast();

  const [categoryPage, setCategoryPage] = useState(1);
  const [cuisinePage, setCuisinePage] = useState(1);
  const [foodTypePage, setFoodTypePage] = useState(1);
  const [menuTypePage, setMenuTypePage] = useState(1);
  const ITEMS_PER_PAGE = 10;
  const searchQuery = searchParams.get("search") || "";
  const [searchInput, setSearchInput] = useState(searchQuery);

  const updateSearchParams = useCallback(
    debounce((value: string) => {
      const trimmedValue = value.trim();
      if (trimmedValue.length >= 3) {
        searchParams.set("search", trimmedValue);
        setSearchParams(searchParams);
        setCategoryPage(1);
        setCuisinePage(1);
        setFoodTypePage(1);
        setMenuTypePage(1);
      } else if (trimmedValue.length === 0) {
        searchParams.delete("search");
        setSearchParams(searchParams);
        setCategoryPage(1);
        setCuisinePage(1);
        setFoodTypePage(1);
        setMenuTypePage(1);
      }
    }, 500),
    [searchParams, setSearchParams]
  );

  const handleSearchChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    setSearchInput(value);
    updateSearchParams(value);
  };

  useEffect(() => {
    setSearchInput(searchQuery);
  }, [searchQuery]);

  useEffect(() => {
    return () => {
      updateSearchParams.cancel();
    };
  }, [updateSearchParams]);

  useEffect(() => {
    if (!permissions.hasRead) {
      navigate("/403", { replace: true });
    }
  }, [permissions.hasRead, navigate]);

  useEffect(() => {
    dispatch(getAllCategories({ page: categoryPage, limit: ITEMS_PER_PAGE, search: searchQuery }));
  }, [dispatch, categoryPage, searchQuery]);

  useEffect(() => {
    dispatch(getAllCuisines({ page: cuisinePage, limit: ITEMS_PER_PAGE, search: searchQuery }));
  }, [dispatch, cuisinePage, searchQuery]);

  useEffect(() => {
    dispatch(
      getAllFoodTypesThunk({ page: foodTypePage, limit: ITEMS_PER_PAGE, search: searchQuery })
    );
  }, [dispatch, foodTypePage, searchQuery]);

  useEffect(() => {
    dispatch(
      getAllMenuTypesThunk({ page: menuTypePage, limit: ITEMS_PER_PAGE, search: searchQuery })
    );
  }, [dispatch, menuTypePage, searchQuery]);

  useEffect(() => {
    if (error) {
      toast({ title: "Error", description: error, variant: "destructive" });
      dispatch(clearError());
    }
  }, [error, toast, dispatch]);

  useEffect(() => {
    if (cuisinesError) {
      toast({
        title: "Error",
        description: cuisinesError,
        variant: "destructive",
      });
      dispatch(clearCuisineError());
    }
  }, [cuisinesError, toast, dispatch]);

  useEffect(() => {
    if (foodTypesError) {
      toast({
        title: "Error",
        description: foodTypesError,
        variant: "destructive",
      });
      dispatch(clearFoodTypeError());
    }
  }, [foodTypesError, toast, dispatch]);

  useEffect(() => {
    if (menuTypesError) {
      toast({
        title: "Error",
        description: menuTypesError,
        variant: "destructive",
      });
      dispatch(clearMenuTypeError());
    }
  }, [menuTypesError, toast, dispatch]);

  const handleDelete = async () => {
    if (activeTab === "food" && categoryToDelete) {
      try {
        const res = await dispatch(removeCategory(categoryToDelete.toString())).unwrap();
        if (res) {
          sonnerToast.success(res.message || "Category deleted successfully");
        }
        setDeleteDialogOpen(false);
        setCategoryToDelete(null);
        dispatch(
          getAllCategories({ page: categoryPage, limit: ITEMS_PER_PAGE })
        );
      } catch (err: any) {
        toast({
          title: "Failed to delete category",
          description: err || "Something went wrong",
          variant: "destructive",
        });
      }
    } else if (activeTab === "restaurant" && cuisineToDelete) {
      try {
        await dispatch(removeCuisine(cuisineToDelete.toString())).unwrap();
        toast({
          title: "Cuisine deleted",
          description: "The cuisine has been removed.",
        });
        setDeleteDialogOpen(false);
        setCuisineToDelete(null);
        dispatch(getAllCuisines({ page: cuisinePage, limit: ITEMS_PER_PAGE }));
      } catch (err: any) {
        toast({
          title: "Failed to delete cuisine",
          description: err || "Something went wrong",
          variant: "destructive",
        });
      }
    } else if (activeTab === "foodTypes" && foodTypeToDelete) {
      try {
        await dispatch(
          deleteFoodTypeThunk(foodTypeToDelete.toString())
        ).unwrap();
        toast({
          title: "Food type deleted",
          description: "The food type has been removed.",
        });
        setDeleteDialogOpen(false);
        setFoodTypeToDelete(null);
        dispatch(
          getAllFoodTypesThunk({ page: foodTypePage, limit: ITEMS_PER_PAGE })
        );
      } catch (err: any) {
        toast({
          title: "Failed to delete food type",
          description: err || "Something went wrong",
          variant: "destructive",
        });
      }
    } else if (activeTab === "menuTypes" && menuTypeToDelete) {
      try {
        const result = await dispatch(
          deleteMenuTypeThunk(menuTypeToDelete.toString())
        ).unwrap();
        sonnerToast.success(result?.message || "Food type deleted successfully");
        setDeleteDialogOpen(false);
        setMenuTypeToDelete(null);
        dispatch(
          getAllMenuTypesThunk({ page: menuTypePage, limit: ITEMS_PER_PAGE })
        );
      } catch (err: any) {
        toast({
          title: "Failed to delete menu type",
          description: err || "Something went wrong",
          variant: "destructive",
        });
      }
    }
  };

  const getStatusBadge = (isActive: number) => {
    switch (isActive) {
      case 1:
        return {
          label: "Active",
          variant: "default" as const,
          className: "bg-green-500 hover:bg-green-600",
        };
      case 0:
        return {
          label: "Inactive",
          variant: "secondary" as const,
          className: "bg-gray-500 hover:bg-gray-600 text-white",
        };
      case 2:
        return { label: "Pending", variant: "outline" as const, className: "" };
      default:
        return {
          label: "Unknown",
          variant: "secondary" as const,
          className: "",
        };
    }
  };


  // --- Toggle Functions ---
  const toggleCategoryStatus = async (category: Category) => {
    const newStatus = category.isActive === 1 ? 0 : 1;
    try {
      await dispatch(
        editCategory({
          id: category.id.toString(),
          data: {
            name: category.name,
            image: category.image,
            isActive: newStatus,
          },
        })
      ).unwrap();
      toast({
        title: `Category ${newStatus === 1 ? "activated" : "deactivated"}`,
      });
      dispatch(getAllCategories({ page: categoryPage, limit: ITEMS_PER_PAGE }));
    } catch (err: any) {
      toast({
        title: "Failed to update status",
        description: err || "Something went wrong",
        variant: "destructive",
      });
    }
  };

  const toggleCuisineStatus = async (cuisine: Cuisine) => {
    const newStatus = cuisine.isActive === 1 ? 0 : 1;
    try {
      await dispatch(
        editCuisine({
          id: cuisine.id.toString(),
          data: {
            name: cuisine.name,
            image: cuisine.image,
            isActive: newStatus,
          },
        })
      ).unwrap();
      toast({
        title: `Cuisine ${newStatus === 1 ? "activated" : "deactivated"}`,
      });
      dispatch(getAllCuisines({ page: cuisinePage, limit: ITEMS_PER_PAGE }));
    } catch (err: any) {
      toast({
        title: "Failed to update status",
        description: err || "Something went wrong",
        variant: "destructive",
      });
    }
  };

  const toggleFoodTypeStatus = async (foodType: FoodType) => {
    const newStatus = foodType.isActive === 1 ? 0 : 1;
    try {
      await dispatch(
        updateFoodTypeThunk({
          id: foodType.id.toString(),
          data: {
            name: foodType.name,
            image: foodType.image,
            isActive: newStatus,
          },
        })
      ).unwrap();
      toast({
        title: `Food type ${newStatus === 1 ? "activated" : "deactivated"}`,
      });
      dispatch(
        getAllFoodTypesThunk({ page: foodTypePage, limit: ITEMS_PER_PAGE })
      );
    } catch (err: any) {
      toast({
        title: "Failed to update status",
        description: err || "Something went wrong",
        variant: "destructive",
      });
    }
  };

  const toggleMenuTypeStatus = async (menuType: MenuType) => {
    const newStatus = menuType.isActive === 1 ? 0 : 1;
    try {
      const result = await dispatch(
        updateMenuTypeThunk({
          id: menuType.id.toString(),
          data: {
            name: menuType.name,
            image: menuType.image,
            isActive: newStatus,
          },
        })
      ).unwrap();
      toast({
        title: result?.message || `Menu type ${newStatus === 1 ? "activated" : "deactivated"}`,
      });
      dispatch(
        getAllMenuTypesThunk({ page: menuTypePage, limit: ITEMS_PER_PAGE })
      );
    } catch (err: any) {
      toast({
        title: "Failed to update status",
        description: err || "Something went wrong",
        variant: "destructive",
      });
    }
  };

  // --- Modal Openers ---
  const openAddModal = () => {
    if (!permissions.checkWrite()) {
      return;
    }
    if (activeTab === "food") {
      setModalMode("add");
      setSelectedCategory(null);
      setSelectedCategoryId(null);
      setIsModalOpen(true);
    } else if (activeTab === "restaurant") {
      setModalMode("add");
      setSelectedCuisine(null);
      setSelectedCuisineId(null);
      setIsCuisineModalOpen(true);
    } else if (activeTab === "foodTypes") {
      setModalMode("add");
      setSelectedFoodType(null);
      setSelectedFoodTypeId(null);
      setIsFoodTypeModalOpen(true);
    } else if (activeTab === "menuTypes") {
      setModalMode("add");
      setSelectedMenuType(null);
      setSelectedMenuTypeId(null);
      setIsMenuTypeModalOpen(true);
    }
  };

  const openEditModal = (item: Category | Cuisine | FoodType) => {
    if (!permissions.checkEdit()) {
      return;
    }
    if (activeTab === "food") {
      const cat = item as Category;
      setModalMode("edit");
      setSelectedCategory(cat);
      setSelectedCategoryId(cat.id.toString());
      setIsModalOpen(true);
    } else if (activeTab === "restaurant") {
      const cuis = item as Cuisine;
      setModalMode("edit");
      setSelectedCuisine(cuis);
      setSelectedCuisineId(cuis.id.toString());
      setIsCuisineModalOpen(true);
    } else if (activeTab === "foodTypes") {
      const ft = item as FoodType;
      setModalMode("edit");
      setSelectedFoodType(ft);
      setSelectedFoodTypeId(ft.id.toString());
      setIsFoodTypeModalOpen(true);
    } else if (activeTab === "menuTypes") {
      const mt = item as MenuType;
      setModalMode("edit");
      setSelectedMenuType(mt);
      setSelectedMenuTypeId(mt.id.toString());
      setIsMenuTypeModalOpen(true);
    }
  };

  const openDeleteDialog = (id: number) => {
    if (!permissions.checkDelete()) {
      return;
    }
    if (activeTab === "food") setCategoryToDelete(id);
    else if (activeTab === "restaurant") setCuisineToDelete(id);
    else if (activeTab === "foodTypes") setFoodTypeToDelete(id);
    else if (activeTab === "menuTypes") setMenuTypeToDelete(id);
    setDeleteDialogOpen(true);
  };

  const categoryColumns: TableColumn<Category>[] = [
    {
      key: "image",
      label: "Image",
      width: "80px",
      render: (_, record) => {
        const imageUrl =
          record.image && record.image.trim() !== ""
            ? record.image
            : fallbackCuisineImage;
        return (
          <img
            src={imageUrl}
            alt={record.name}
            className="w-12 h-12 object-cover rounded-md border"
            onError={(e) => {
              const target = e.target as HTMLImageElement;
              if (target.src !== fallbackCuisineImage)
                target.src = fallbackCuisineImage;
            }}
          />
        );
      },
    },
    {
      key: "name",
      label: "Category Name",
      className: "font-medium min-w-[150px]",
      width: "25%",
    },
    {
      key: "isActive",
      label: "Status",
      width: "120px",
      render: (_, record) => {
        const status = getStatusBadge(record.isActive);
        return (
          <Badge
            variant={status.variant}
            className={`cursor-pointer ${status.className}`}
            onClick={() => toggleCategoryStatus(record)}
          >
            {status.label}
          </Badge>
        );
      },
    },
    {
      key: "isPopular",
      label: "Popular",
      width: "100px",
      render: (_, record) => (
        <Badge variant={record.isPopular === 1 ? "default" : "secondary"}>
          {record.isPopular === 1 ? "Yes" : "No"}
        </Badge>
      ),
    },
    {
      key: "createdAt",
      label: "Created At",
      width: "150px",
      render: (_, record) => new Date(record.createdAt).toLocaleDateString(),
    },
    {
      key: "actions",
      label: "Actions",
      align: "right",
      width: "150px",
      render: (_, record) => (
        <div className="flex justify-end gap-2">
          <Button
            variant="ghost"
            size="sm"
            onClick={() => openEditModal(record)}
            className="text-[#f47923] hover:bg-[#f47923]/10"
          >
            <Edit className="h-4 w-4" />
          </Button>
          <Button
            variant="ghost"
            size="sm"
            onClick={() => openDeleteDialog(record.id)}
            className="text-destructive hover:bg-destructive/10"
          >
            <Trash2 className="h-4 w-4" />
          </Button>
        </div>
      ),
    },
  ];

  const cuisineColumns: TableColumn<Cuisine>[] = [
    {
      key: "image",
      label: "Image",
      width: "80px",
      render: (_, record) => {
        const imageUrl =
          record.image && record.image.trim() !== ""
            ? record.image
            : fallbackCuisineImage;
        return (
          <img
            src={imageUrl}
            alt={record.name}
            className="w-12 h-12 object-cover rounded-md border"
            onError={(e) => {
              const target = e.target as HTMLImageElement;
              if (target.src !== fallbackCuisineImage)
                target.src = fallbackCuisineImage;
            }}
          />
        );
      },
    },
    {
      key: "name",
      label: "Cuisine Name",
      className: "font-medium min-w-[150px]",
      width: "25%",
    },
    {
      key: "isActive",
      label: "Status",
      width: "120px",
      render: (_, record) => {
        const status = getStatusBadge(record.isActive);
        return (
          <Badge
            variant={status.variant}
            className={`cursor-pointer ${status.className}`}
            onClick={() => toggleCuisineStatus(record)}
          >
            {status.label}
          </Badge>
        );
      },
    },
    {
      key: "is_popular",
      label: "Popular",
      width: "100px",
      render: (_, record) => (
        <Badge variant={record.is_popular === 1 ? "default" : "secondary"}>
          {record.is_popular === 1 ? "Yes" : "No"}
        </Badge>
      ),
    },
    {
      key: "createdAt",
      label: "Created At",
      width: "150px",
      render: (_, record) => new Date(record.createdAt).toLocaleDateString(),
    },
    {
      key: "actions",
      label: "Actions",
      align: "right",
      width: "150px",
      render: (_, record) => (
        <div className="flex justify-end gap-2">
          <Button
            variant="ghost"
            size="sm"
            onClick={() => openEditModal(record)}
            className="text-[#f47923] hover:bg-[#f47923]/10"
          >
            <Edit className="h-4 w-4" />
          </Button>
          <Button
            variant="ghost"
            size="sm"
            onClick={() => openDeleteDialog(record.id)}
            className="text-destructive hover:bg-destructive/10"
          >
            <Trash2 className="h-4 w-4" />
          </Button>
        </div>
      ),
    },
  ];

  const foodTypeColumns: TableColumn<FoodType>[] = [
    {
      key: "image",
      label: "Image",
      width: "80px",
      render: (_, record) => (
        <img
          src={record.image}
          alt={record.name}
          className="w-12 h-12 object-cover rounded-md border"
        />
      ),
    },
    {
      key: "name",
      label: "Restaurant Type Name",
      className: "font-medium min-w-[150px]",
      width: "25%",
    },
    {
      key: "question",
      label: "Question",
      className: "font-medium min-w-[150px]",
      render: (_, record) => record.question ? record.question : "__",
      width: "25%",
    },
    {
      key: "isActive",
      label: "Status",
      width: "120px",
      render: (_, record) => {
        const status = getStatusBadge(record.isActive);
        return (
          <Badge
            variant={status.variant}
            className={`cursor-pointer ${status.className}`}
            onClick={() => toggleFoodTypeStatus(record)}
          >
            {status.label}
          </Badge>
        );
      },
    },
    {
      key: "createdAt",
      label: "Created At",
      width: "150px",
      render: (_, record) => new Date(record.createdAt).toLocaleDateString(),
    },
    {
      key: "actions",
      label: "Actions",
      align: "right",
      width: "150px",
      render: (_, record) => (
        <div className="flex justify-end gap-2">
          <Button
            variant="ghost"
            size="sm"
            onClick={() => openEditModal(record)}
            className="text-[#f47923] hover:bg-[#f47923]/10"
          >
            <Edit className="h-4 w-4" />
          </Button>
          <Button
            variant="ghost"
            size="sm"
            onClick={() => openDeleteDialog(record.id)}
            className="text-destructive hover:bg-destructive/10"
          >
            <Trash2 className="h-4 w-4" />
          </Button>
        </div>
      ),
    },
  ];

  const menuTypeColumns: TableColumn<MenuType>[] = [
    {
      key: "image",
      label: "Image",
      width: "80px",
      render: (_, record) => {
        const imageUrl =
          record.image && record.image.trim() !== ""
            ? record.image
            : fallbackCuisineImage;
        return (
          <img
            src={imageUrl}
            alt={record.name}
            className="w-12 h-12 object-cover rounded-md border"
            onError={(e) => {
              const target = e.target as HTMLImageElement;
              if (target.src !== fallbackCuisineImage)
                target.src = fallbackCuisineImage;
            }}
          />
        );
      },
    },
    {
      key: "name",
      label: "Food Type Name",
      className: "font-medium min-w-[150px]",
      width: "25%",
    },
    {
      key: "isActive",
      label: "Status",
      width: "120px",
      render: (_, record) => {
        const status = getStatusBadge(record.isActive);
        return (
          <Badge
            variant={status.variant}
            className={`cursor-pointer ${status.className}`}
            onClick={() => toggleMenuTypeStatus(record)}
          >
            {status.label}
          </Badge>
        );
      },
    },
    {
      key: "createdAt",
      label: "Created At",
      width: "150px",
      render: (_, record) => new Date(record.createdAt).toLocaleDateString(),
    },
    {
      key: "actions",
      label: "Actions",
      align: "right",
      width: "150px",
      render: (_, record) => (
        <div className="flex justify-end gap-2">
          <Button
            variant="ghost"
            size="sm"
            onClick={() => openEditModal(record)}
            className="text-[#f47923] hover:bg-[#f47923]/10"
          >
            <Edit className="h-4 w-4" />
          </Button>
          <Button
            variant="ghost"
            size="sm"
            onClick={() => openDeleteDialog(record.id)}
            className="text-destructive hover:bg-destructive/10"
          >
            <Trash2 className="h-4 w-4" />
          </Button>
        </div>
      ),
    },
  ];

  return (
    <>
      <Tabs
        value={activeTab}
        onValueChange={(v) =>
          setActiveTab(v as "food" | "restaurant" | "foodTypes" | "menuTypes")
        }
      >
        <div className="flex flex-col md:flex-row gap-4 mb-6">
          <div className="relative flex-1 md:max-w-md">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground z-10 pointer-events-none" />
            <Input
              placeholder="Search using category name"
              value={searchInput}
              onChange={handleSearchChange}
              className="pl-10 h-10 bg-background/50 backdrop-blur-sm border-muted transition-all focus:bg-background shadow-sm"
            />
          </div>
        </div>

        <div className="flex flex-col lg:flex-row items-start lg:items-center justify-between gap-6 mb-8 bg-zinc-50/50 dark:bg-zinc-900/50 p-6 rounded-3xl border border-zinc-200/20 dark:border-zinc-700/20 backdrop-blur-xl shadow-sm">
          <div className="w-full lg:hidden">
            <Select
              value={activeTab}
              onValueChange={(v) =>
                setActiveTab(v as "food" | "restaurant" | "foodTypes" | "menuTypes")
              }
            >
              <SelectTrigger className="w-full h-12 rounded-2xl bg-white dark:bg-zinc-950 border-zinc-200/40 dark:border-zinc-800/40">
                <SelectValue placeholder="Select Category Type" />
              </SelectTrigger>
              <SelectContent className="rounded-2xl">
                <SelectItem value="food" className="rounded-xl">Food Categories</SelectItem>
                <SelectItem value="restaurant" className="rounded-xl">
                  Restaurant Categories
                </SelectItem>
                <SelectItem value="foodTypes" className="rounded-xl">Restaurant Types</SelectItem>
                <SelectItem value="menuTypes" className="rounded-xl">Food Types</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <TabsList className="hidden lg:flex w-full lg:w-auto h-12 p-1.5 bg-zinc-200/40 dark:bg-zinc-800/40 rounded-2xl border border-zinc-200/10 dark:border-zinc-700/10 backdrop-blur-md">
            <TabsTrigger
              value="food"
              className="px-6 py-2 rounded-xl text-xs font-bold transition-all data-[state=active]:bg-white dark:data-[state=active]:bg-zinc-950 data-[state=active]:text-primary data-[state=active]:shadow-lg flex items-center gap-2.5"
            >
              <Utensils className="h-4 w-4" />
              <span>Food Categories</span>
            </TabsTrigger>
            <TabsTrigger
              value="restaurant"
              className="px-6 py-2 rounded-xl text-xs font-bold transition-all data-[state=active]:bg-white dark:data-[state=active]:bg-zinc-950 data-[state=active]:text-primary data-[state=active]:shadow-lg flex items-center gap-2.5"
            >
              <Store className="h-4 w-4" />
              <span>Restaurant Categories</span>
            </TabsTrigger>
            <TabsTrigger
              value="foodTypes"
              className="px-6 py-2 rounded-xl text-xs font-bold transition-all data-[state=active]:bg-white dark:data-[state=active]:bg-zinc-950 data-[state=active]:text-primary data-[state=active]:shadow-lg flex items-center gap-2.5"
            >
              <Layers className="h-4 w-4" />
              <span>Restaurant Types</span>
            </TabsTrigger>
            <TabsTrigger
              value="menuTypes"
              className="px-6 py-2 rounded-xl text-xs font-bold transition-all data-[state=active]:bg-white dark:data-[state=active]:bg-zinc-950 data-[state=active]:text-primary data-[state=active]:shadow-lg flex items-center gap-2.5"
            >
              <UtensilsCrossed className="h-4 w-4" />
              <span>Food Types</span>
            </TabsTrigger>
          </TabsList>

          <Button
            onClick={openAddModal}
            disabled={loading || cuisinesLoading || foodTypesLoading || menuTypesLoading}
            className="w-full lg:w-auto h-12 px-6 rounded-2xl bg-primary hover:bg-primary/90 text-white font-bold transition-all shadow-md active:scale-95"
          >
            <Plus className="mr-2 h-5 w-5" />
            Add{" "}
            {activeTab === "food"
              ? "Category"
              : activeTab === "restaurant"
                ? "Category"
                : activeTab === "foodTypes"
                  ? "Restaurant Type"
                  : "Food Type"}
          </Button>
        </div>

        <TabsContent value="food">
          <Card className="border-none shadow-md bg-card/50 backdrop-blur-sm">
            <CardHeader>
              <CardTitle>Food Categories</CardTitle>
              <CardDescription>
                Manage food categories for your platform
              </CardDescription>
            </CardHeader>
            <CardContent>
              <DynamicTable
                columns={categoryColumns}
                data={categories}
                loading={loading}
                emptyMessage="No categories found. Add your first category!"
                skeletonRows={5}
                minWidth="800px"
              />
              {categoriesPagination && (
                <div className="mt-4">
                  <Pagination
                    Pagination={{
                      page: categoryPage,
                      totalCount: categoriesPagination.totalRecords,
                      totalPages: categoriesPagination.totalPages,
                      size: ITEMS_PER_PAGE,
                    }}
                    onPageChange={setCategoryPage}
                  />
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="restaurant">
          <Card className="border-none shadow-md bg-card/50 backdrop-blur-sm">
            <CardHeader>
              <CardTitle>Restaurant Categories</CardTitle>
              <CardDescription>
                Manage categories for restaurants
              </CardDescription>
            </CardHeader>
            <CardContent>
              <DynamicTable
                columns={cuisineColumns}
                data={cuisines}
                loading={cuisinesLoading}
                emptyMessage="No cuisines found. Add your first cuisine!"
                skeletonRows={5}
                minWidth="800px"
              />
              {cuisinesPagination && (
                <div className="mt-4">
                  <Pagination
                    Pagination={{
                      page: cuisinePage,
                      totalCount: cuisinesPagination.totalRecords,
                      totalPages: cuisinesPagination.totalPages,
                      size: ITEMS_PER_PAGE,
                    }}
                    onPageChange={setCuisinePage}
                  />
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="foodTypes">
          <Card className="border-none shadow-md bg-card/50 backdrop-blur-sm">
            <CardHeader>
              <CardTitle>Restaurant Types</CardTitle>
              <CardDescription>
                Manage restaurant types and categories
              </CardDescription>
            </CardHeader>
            <CardContent>
              <DynamicTable
                columns={foodTypeColumns}
                data={foodTypes}
                loading={foodTypesLoading}
                emptyMessage="No food types found. Add your first food type!"
                skeletonRows={5}
                minWidth="800px"
              />
              {foodTypesPagination && (
                <div className="mt-4">
                  <Pagination
                    Pagination={{
                      page: foodTypePage,
                      totalCount: foodTypesPagination.totalRecords,
                      totalPages: foodTypesPagination.totalPages,
                      size: ITEMS_PER_PAGE,
                    }}
                    onPageChange={setFoodTypePage}
                  />
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="menuTypes">
          <Card className="border-none shadow-md bg-card/50 backdrop-blur-sm">
            <CardHeader>
              <CardTitle>Food Types</CardTitle>
              <CardDescription>
                Manage food types for your menu
              </CardDescription>
            </CardHeader>
            <CardContent>
              <DynamicTable
                columns={menuTypeColumns}
                data={menuTypes}
                loading={menuTypesLoading}
                emptyMessage="No food types found. Add your first food type!"
                skeletonRows={5}
                minWidth="800px"
              />
              {menuTypesPagination && (
                <div className="mt-4">
                  <Pagination
                    Pagination={{
                      page: menuTypePage,
                      totalCount: menuTypesPagination.totalRecords,
                      totalPages: menuTypesPagination.totalPages,
                      size: ITEMS_PER_PAGE,
                    }}
                    onPageChange={setMenuTypePage}
                  />
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      <CategoryFormModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        category={selectedCategory}
        mode={modalMode}
        id={selectedCategoryId}
      />
      <CuisineFormModal
        isOpen={isCuisineModalOpen}
        onClose={() => setIsCuisineModalOpen(false)}
        cuisine={selectedCuisine}
        mode={modalMode}
        id={selectedCuisineId}
      />
      <FoodTypeFormModal
        isOpen={isFoodTypeModalOpen}
        onClose={() => setIsFoodTypeModalOpen(false)}
        foodType={selectedFoodType}
        mode={modalMode}
        id={selectedFoodTypeId}
      />
      <MenuTypeFormModal
        isOpen={isMenuTypeModalOpen}
        onClose={() => setIsMenuTypeModalOpen(false)}
        menuType={selectedMenuType}
        mode={modalMode}
        id={selectedMenuTypeId}
      />

      <AlertDialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Are you sure?</AlertDialogTitle>
            <AlertDialogDescription>
              This action cannot be undone. This will permanently delete the
              {activeTab === "food"
                ? " category"
                : activeTab === "restaurant"
                  ? " cuisine"
                  : activeTab === "foodTypes"
                    ? " restaurant type"
                    : " food type"}
              .
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel
              onClick={() => {
                setCategoryToDelete(null);
                setCuisineToDelete(null);
                setFoodTypeToDelete(null);
                setMenuTypeToDelete(null);
              }}
            >
              Cancel
            </AlertDialogCancel>
            <AlertDialogAction
              onClick={handleDelete}
              className="bg-destructive hover:bg-destructive/90"
            >
              Delete
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
};
export default Categories;

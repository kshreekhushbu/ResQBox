import { useState, useEffect, useCallback } from "react";
import { useDispatch, useSelector } from "react-redux";
import { useNavigate } from "react-router-dom";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Loader2, Plus, Search, Pencil, Trash2 } from "lucide-react"; // Import Pencil
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { useToast } from "@/hooks/use-toast";
import { AppDispatch, RootState } from "@/store/store";
import { fetchAdminUsers, removeAdminUser, clearError } from "../teamSlice";
import { DynamicTable, TableColumn } from "@/components/table/DynamicTable";
import Pagination from "@/components/Pagination/Pagination";
import { AdminUser } from "../types";
import debounce from "lodash/debounce";
import { fetchRoles } from "@/features/permissions/permissionsSlice";
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
import { usePermissions } from "@/hooks/usePermissions";

const Teams: React.FC = () => {
    const dispatch = useDispatch<AppDispatch>();
    const navigate = useNavigate();
    const permissions = usePermissions("teams");
    const { users, loading, error, pagination } = useSelector((state: RootState) => state.team);
    const { roles } = useSelector((state: RootState) => state.permissions);
    const { toast } = useToast();

    const [searchQuery, setSearchQuery] = useState("");
    const [page, setPage] = useState(1);
    const ITEMS_PER_PAGE = 10;
    const [userToDelete, setUserToDelete] = useState<number | null>(null);

    // Check read permission on mount
    useEffect(() => {
        if (!permissions.hasRead) {
            navigate("/403", { replace: true });
        }
    }, [permissions.hasRead, navigate]);

    useEffect(() => {
        dispatch(fetchRoles());
    }, [dispatch]);

    const debouncedFetch = useCallback(
        debounce((query: string) => {
            dispatch(fetchAdminUsers({ page: 1, limit: ITEMS_PER_PAGE, search: query }));
        }, 500),
        [dispatch]
    );

    useEffect(() => {
        if (searchQuery.length >= 3 || searchQuery.length === 0) {
            dispatch(fetchAdminUsers({ page, limit: ITEMS_PER_PAGE, search: searchQuery }));
        }
    }, [dispatch, page, searchQuery]);

    useEffect(() => {
        if (error) {
            toast({
                title: "Error",
                description: error,
                variant: "destructive",
            });
            dispatch(clearError());
        }
    }, [error, toast, dispatch]);

    const handleSearchChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        setSearchQuery(e.target.value);
        setPage(1);
    };

    const handleDeleteUser = async () => {
        if (userToDelete) {
            if (!permissions.checkDelete()) {
                setUserToDelete(null);
                return;
            }
            try {
                await dispatch(removeAdminUser(userToDelete)).unwrap();
                toast({ title: "Success", description: "User deleted successfully" });
                dispatch(fetchAdminUsers({ page, limit: ITEMS_PER_PAGE, search: searchQuery }));
            } catch (err) {
                console.log(err);
            } finally {
                setUserToDelete(null);
            }
        }
    };

    const getInitials = (name: string) => {
        return name
            .split(" ")
            .map((n) => n[0])
            .join("")
            .toUpperCase()
            .substring(0, 2);
    };

    const columns: TableColumn<AdminUser>[] = [
        {
            key: "member",
            label: "Member",
            render: (_, record) => (
                <div className="flex items-center gap-3 max-w-[200px]">
                    <Avatar className="flex-shrink-0">
                        <AvatarFallback className="bg-primary/10 text-primary">
                            {getInitials(record.name)}
                        </AvatarFallback>
                    </Avatar>
                    <span className="font-medium truncate" title={record.name}>{record.name}</span>
                </div>
            ),
        },
        {
            key: "emailId",
            label: "Email",
            render: (val) => (
                <div className="max-w-[200px] truncate" title={val}>
                    {val}
                </div>
            ),
        },
        {
            key: "roleId",
            label: "Role",
            render: (_, record) => {
                const role = roles.find(r => r.id === record.roleId);
                return role ? role.role : `Role ${record.roleId}`;
            },
        },
        {
            key: "createdAt",
            label: "Joined",
            render: (_, record) => new Date(record.created_at).toLocaleDateString(),
        },
        {
            key: "actions",
            label: "Actions",
            align: "right",
            render: (_, record) => (
                <div className="flex justify-end gap-2">
                    <Button variant="ghost" size="icon" onClick={() => {
                        if (!permissions.checkEdit()) {
                            return;
                        }
                        navigate(`/teams/edit/${record.adminId}`);
                    }}>
                        <Pencil className="h-4 w-4" />
                    </Button>
                    <Button variant="ghost" size="icon" onClick={() => setUserToDelete(record.adminId)}>
                        <Trash2 className="h-4 w-4 text-destructive" />
                    </Button>
                </div>
            )
        }
    ];

    return (
        <>

            <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 bg-card p-4 rounded-lg border shadow-sm">
                <div className="relative flex-1 w-full sm:max-w-md">
                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                    <Input
                        placeholder="Search team members..."
                        value={searchQuery}
                        onChange={handleSearchChange}
                        className="pl-9 bg-background"
                    />
                </div>

                <Button className="bg-primary hover:bg-primary/90" onClick={() => {
                    if (!permissions.checkWrite()) {
                        return;
                    }
                    navigate("/teams/add");
                }}>
                    <Plus className="mr-2 h-4 w-4" />
                    Invite Member
                </Button>
            </div>

            <div className="bg-card rounded-lg border shadow-sm overflow-hidden">
                <DynamicTable
                    columns={columns}
                    data={users}
                    loading={loading}
                    emptyMessage="No team members found."
                    className="border-0 shadow-none"
                />
                {pagination && (
                    <div className="p-4 border-t">
                        <Pagination
                            Pagination={{
                                page: page,
                                totalCount: pagination.total,
                                totalPages: pagination.totalPages,
                                size: ITEMS_PER_PAGE,
                            }}
                            onPageChange={setPage}
                        />
                    </div>
                )}
            </div>


            <AlertDialog open={!!userToDelete} onOpenChange={(open) => !open && setUserToDelete(null)}>
                <AlertDialogContent>
                    <AlertDialogHeader>
                        <AlertDialogTitle>Are you sure?</AlertDialogTitle>
                        <AlertDialogDescription>
                            This action cannot be undone. This will permanently remove the team member account.
                        </AlertDialogDescription>
                    </AlertDialogHeader>
                    <AlertDialogFooter>
                        <AlertDialogCancel>Cancel</AlertDialogCancel>
                        <AlertDialogAction onClick={handleDeleteUser} className="bg-destructive text-destructive-foreground hover:bg-destructive/90">
                            Delete
                        </AlertDialogAction>
                    </AlertDialogFooter>
                </AlertDialogContent>
            </AlertDialog>
        </>
    );
};

export default Teams;

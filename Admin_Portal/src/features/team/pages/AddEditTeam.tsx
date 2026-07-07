import { useEffect, useState } from "react";
import { useDispatch, useSelector } from "react-redux";
import { useParams, useNavigate } from "react-router-dom";
import { AppDispatch, RootState } from "@/store/store";
import { fetchAdminUserById, addAdminUser, modifyAdminUser } from "../teamSlice";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from "@/components/ui/select";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { useToast } from "@/hooks/use-toast";
import { Loader2, ArrowLeft, Save, User as UserIcon } from "lucide-react";
import { UpdateAdminUser, CreateAdminUser } from "../types";
import { fetchRoles } from "@/features/permissions/permissionsSlice";
import { useForm, Controller } from "react-hook-form";
import { yupResolver } from "@hookform/resolvers/yup";
import * as yup from "yup";
import { noLeadingSpace, maxTwoSpaces, nameRegex, normalizeInput } from "@/lib/utils";
import {
    Breadcrumb,
    BreadcrumbItem,
    BreadcrumbLink,
    BreadcrumbList,
    BreadcrumbPage,
    BreadcrumbSeparator,
} from "@/components/ui/breadcrumb";

const teamSchema = yup.object().shape({
    name: yup
        .string()
        .required("Full Name is required")
        .max(20, "Name must be at most 20 characters")
        .test("no-leading-space", "No leading spaces allowed", noLeadingSpace)
        .test("max-two-spaces", "No more than 2 consecutive spaces allowed", maxTwoSpaces)
        .matches(nameRegex, "Only alphabets allowed"),
    emailId: yup
        .string()
        .required("Email is required")
        .email("Invalid email format")
        .matches(/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/, "Strict email validation failed"),
    roleId: yup.string().required("Role is required"),
    status: yup.string().required("Status is required"),
    password: yup.string().test("password-required", "Password is required", function (value) {
        const isEditMode = this.options.context?.isEditMode;
        if (!isEditMode && !value) return false;
        return true;
    }),
});

type TeamFormData = yup.InferType<typeof teamSchema>;

export default function AddEditTeam() {
    const { id } = useParams<{ id: string }>();
    const isEditMode = !!id;
    const dispatch = useDispatch<AppDispatch>();
    const navigate = useNavigate();
    const { toast } = useToast();
    const { roles } = useSelector((state: RootState) => state.permissions);
    const [loading, setLoading] = useState(false);
    const [fetching, setFetching] = useState(isEditMode);

    const {
        register,
        handleSubmit,
        control,
        setValue,
        reset,
        formState: { errors },
    } = useForm<TeamFormData>({
        resolver: yupResolver(teamSchema),
        context: { isEditMode },
        defaultValues: {
            name: "",
            emailId: "",
            password: "",
            roleId: undefined, // undefined to show placeholder
            status: undefined, // undefined to show placeholder
        },
    });

    useEffect(() => {
        dispatch(fetchRoles());
        if (isEditMode) {
            setFetching(true);
            dispatch(fetchAdminUserById(parseInt(id)))
                .unwrap()
                .then((user) => {
                    // Populate form
                    setValue("name", user.name);
                    setValue("emailId", user.emailId);
                    setValue("roleId", user.roleId.toString());
                    setValue("status", user.status.toString());
                })
                .catch((err) => {
                    toast({
                        title: "Error",
                        description: "Failed to fetch user details",
                        variant: "destructive",
                    });
                    navigate("/teams");
                })
                .finally(() => setFetching(false));
        }
    }, [isEditMode, id, dispatch, navigate, toast, setValue]);

    const onSubmit = async (data: TeamFormData) => {
        setLoading(true);
        try {
            if (isEditMode) {
                const payload: UpdateAdminUser = {
                    name: data.name,
                    emailId: data.emailId,
                    roleId: parseInt(data.roleId),
                    status: parseInt(data.status),
                };

                if (data.password && data.password.trim() !== "") {
                    payload.password = data.password;
                }
                await dispatch(modifyAdminUser({ id: parseInt(id), userData: payload })).unwrap();
                toast({ title: "Success", description: "Team member updated successfully" });
            } else {
                const payload: CreateAdminUser = {
                    name: data.name,
                    emailId: data.emailId,
                    password: data.password!,
                    roleId: parseInt(data.roleId),
                };
                await dispatch(addAdminUser(payload)).unwrap();
                toast({ title: "Success", description: "Team member added successfully" });
            }
            navigate("/teams");
        } catch (error: any) {
            toast({
                title: "Error",
                description: error || "Something went wrong",
                variant: "destructive",
            });
        } finally {
            setLoading(false);
        }
    };

    if (fetching) {
        return (
            <div className="flex h-screen items-center justify-center">
                <Loader2 className="h-8 w-8 animate-spin text-primary" />
            </div>
        );
    }

    return (
        <div className="max-w-4xl mx-auto space-y-6">
            <div className="flex items-center gap-2 mb-6">
                <Breadcrumb>
                    <BreadcrumbList>
                        <BreadcrumbItem>
                            <BreadcrumbLink href="/teams">Teams</BreadcrumbLink>
                        </BreadcrumbItem>
                        <BreadcrumbSeparator />
                        <BreadcrumbItem>
                            <BreadcrumbPage className="text-primary font-semibold">{isEditMode ? "Edit Team Member" : "Add Team Member"}</BreadcrumbPage>
                        </BreadcrumbItem>
                    </BreadcrumbList>
                </Breadcrumb>
            </div>
            <form onSubmit={handleSubmit(onSubmit)} className="space-y-8">
                <Card className="border-none shadow-md bg-card/50 backdrop-blur-sm">
                    <CardHeader>
                        <div className="flex items-center gap-3">
                            <div className="p-2 bg-primary/10 rounded-lg">
                                <UserIcon className="h-6 w-6 text-primary" />
                            </div>
                            <div>
                                <CardTitle>Member Details</CardTitle>
                                <CardDescription>
                                    Enter the personal details and role assignment for the team member.
                                </CardDescription>
                            </div>
                        </div>
                    </CardHeader>
                    <CardContent className="space-y-6">
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                            <div className="space-y-2">
                                <Label htmlFor="name">Full Name <span className="text-destructive">*</span></Label>
                                <Input
                                    id="name"
                                    placeholder="e.g. John Doe"
                                    {...register("name", {
                                        onChange: (e) => {
                                            e.target.value = normalizeInput(e.target.value);
                                        }
                                    })}
                                    className={errors.name ? "border-destructive focus-visible:ring-destructive" : ""}
                                />
                                {errors.name && <span className="text-xs text-destructive">{errors.name.message}</span>}
                            </div>

                            <div className="space-y-2">
                                <Label htmlFor="emailId">Email Address <span className="text-destructive">*</span></Label>
                                <Input
                                    id="emailId"
                                    type="email"
                                    placeholder="john.doe@example.com"
                                    {...register("emailId")}
                                    className={errors.emailId ? "border-destructive focus-visible:ring-destructive" : ""}
                                />
                                {errors.emailId && <span className="text-xs text-destructive">{errors.emailId.message}</span>}
                            </div>

                            <div className="space-y-2">
                                <Label htmlFor="roleId">Role <span className="text-destructive">*</span></Label>
                                <Controller
                                    name="roleId"
                                    control={control}
                                    render={({ field }) => (
                                        <Select onValueChange={field.onChange} value={field.value}>
                                            <SelectTrigger className={errors.roleId ? "border-destructive focus:ring-destructive" : ""}>
                                                <SelectValue placeholder="Select Role" />
                                            </SelectTrigger>
                                            <SelectContent>
                                                {roles.map((role) => (
                                                    <SelectItem key={role.id} value={role.id.toString()}>
                                                        {role.role}
                                                    </SelectItem>
                                                ))}
                                            </SelectContent>
                                        </Select>
                                    )}
                                />
                                {errors.roleId && <span className="text-xs text-destructive">{errors.roleId.message}</span>}
                            </div>
                            <div className="space-y-2">
                                <Label htmlFor="status">Status <span className="text-destructive">*</span></Label>
                                <Controller
                                    name="status"
                                    control={control}
                                    render={({ field }) => (
                                        <Select onValueChange={field.onChange} value={field.value}>
                                            <SelectTrigger className={errors.status ? "border-destructive focus:ring-destructive" : ""}>
                                                <SelectValue placeholder="Select Status" />
                                            </SelectTrigger>
                                            <SelectContent>
                                                <SelectItem value="1">Active</SelectItem>
                                                <SelectItem value="0">Inactive</SelectItem>
                                            </SelectContent>
                                        </Select>
                                    )}
                                />
                                {errors.status && <span className="text-xs text-destructive">{/* errors.status.message */} Status is required</span>}
                            </div>
                        </div>

                        <div className="space-y-2 max-w-md">
                            <Label htmlFor="password">
                                {isEditMode ? "Password (Leave blank to keep current)" : "Password"}
                                {!isEditMode && <span className="text-destructive">*</span>}
                            </Label>
                            <Input
                                id="password"
                                type="text"
                                placeholder={isEditMode ? "******" : "Enter secure password"}
                                {...register("password")}
                                className={errors.password ? "border-destructive focus-visible:ring-destructive" : ""}
                            />
                            {errors.password && <span className="text-xs text-destructive">{errors.password.message}</span>}
                        </div>

                    </CardContent>
                </Card>

                <div className="flex justify-end gap-3">
                    <Button
                        type="button"
                        variant="outline"
                        onClick={() => navigate("/teams")}
                        disabled={loading}
                    >
                        Cancel
                    </Button>
                    <Button type="submit" disabled={loading} className="bg-primary hover:bg-primary/90 min-w-[120px]">
                        {loading ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <Save className="mr-2 h-4 w-4" />}
                        {isEditMode ? "Update Member" : "Create Member"}
                    </Button>
                </div>
            </form>
        </div>
    );
}

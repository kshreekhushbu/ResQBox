export interface AdminUser {
    adminId: number;
    name: string;
    emailId: string;
    roleId: number;
    status: number;
    created_at: string;
}

export interface CreateAdminUser {
    name: string;
    emailId: string;
    password?: string;
    roleId: number;
}

export interface Pagination {
    total: number;
    currentPage: number;
    totalPages: number;
}

export interface AdminUsersResponse {
    status: number;
    message: string;
    subadmins: AdminUser[];
    pagination:Pagination
}

export interface UpdateAdminUser {
    name: string;
    emailId: string;
    password?: string;
    roleId: number;
    status: number;
}

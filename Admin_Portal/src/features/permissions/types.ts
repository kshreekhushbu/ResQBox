export interface Permission {
  edit: number;
  read: number;
  write: number;
  delete: number;
  PageName: string;
}

export interface Role {
  id: number;
  role: string;
  permissions?: Permission[];
}

export interface RolesResponse {
  status: number;
  roles: Role[];
}

export interface RoleDetailsResponse {
  status: number;
  role: Role[];
}

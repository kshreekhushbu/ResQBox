import { useMemo } from 'react';
import { toast } from '@/components/ui/sonner';
import {
  hasReadPermission,
  hasWritePermission,
  hasEditPermission,
  hasDeletePermission,
  getAllPermissions,
} from '@/utils/permissions';

export interface UsePermissionsReturn {
  hasRead: boolean;
  hasWrite: boolean;
  hasEdit: boolean;
  hasDelete: boolean;
  checkWrite: (customMessage?: string) => boolean;
  checkEdit: (customMessage?: string) => boolean;
  checkDelete: (customMessage?: string) => boolean;
}

/**
 * Custom hook for checking permissions on a page
 * @param pageName - The name of the page to check permissions for
 * @returns Permission states and check functions with toast notifications
 */
export const usePermissions = (pageName: string): UsePermissionsReturn => {
  const permissions = useMemo(() => getAllPermissions(pageName), [pageName]);

  const checkWrite = (customMessage?: string): boolean => {
    if (!permissions.hasWrite) {
      toast.error(customMessage || "You don't have permission to create items", {
        description: "Please contact your administrator for access.",
      });
      return false;
    }
    return true;
  };

  const checkEdit = (customMessage?: string): boolean => {
    if (!permissions.hasEdit) {
      toast.error(customMessage || "You don't have permission to edit items", {
        description: "Please contact your administrator for access.",
      });
      return false;
    }
    return true;
  };

  const checkDelete = (customMessage?: string): boolean => {
    if (!permissions.hasDelete) {
      toast.error(customMessage || "You don't have permission to delete items", {
        description: "Please contact your administrator for access.",
      });
      return false;
    }
    return true;
  };

  return {
    hasRead: permissions.hasRead,
    hasWrite: permissions.hasWrite,
    hasEdit: permissions.hasEdit,
    hasDelete: permissions.hasDelete,
    checkWrite,
    checkEdit,
    checkDelete,
  };
};

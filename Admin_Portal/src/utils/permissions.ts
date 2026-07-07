/**
 * Permission Utility Functions
 * Handles permission checking from localStorage
 */

export interface AccessItem {
  PageName: string;
  read: number;
  write: number;
  edit: number;
  delete: number;
}

/**
 * Retrieve all access items from localStorage
 */
export const getAccessItems = (): AccessItem[] => {
  try {
    const stored = localStorage.getItem("AccessItems");
    return stored ? JSON.parse(stored) : [];
  } catch (error) {
    console.error("Error parsing AccessItems from localStorage:", error);
    return [];
  }
};

/**
 * Get permissions for a specific page
 * @param pageName - The name of the page (case-insensitive)
 */
export const getPagePermissions = (pageName: string): AccessItem | null => {
  const accessItems = getAccessItems();
  const normalizedPageName = pageName.toLowerCase();
  
  return accessItems.find(
    (item) => item.PageName.toLowerCase() === normalizedPageName
  ) || null;
};

/**
 * Check if user has read permission for a page
 */
export const hasReadPermission = (pageName: string): boolean => {
  const permissions = getPagePermissions(pageName);
  return permissions?.read === 1;
};

/**
 * Check if user has write permission for a page
 */
export const hasWritePermission = (pageName: string): boolean => {
  const permissions = getPagePermissions(pageName);
  return permissions?.write === 1;
};

/**
 * Check if user has edit permission for a page
 */
export const hasEditPermission = (pageName: string): boolean => {
  const permissions = getPagePermissions(pageName);
  return permissions?.edit === 1;
};

/**
 * Check if user has delete permission for a page
 */
export const hasDeletePermission = (pageName: string): boolean => {
  const permissions = getPagePermissions(pageName);
  return permissions?.delete === 1;
};

/**
 * Check if user has any permission for a page
 */
export const hasAnyPermission = (pageName: string): boolean => {
  const permissions = getPagePermissions(pageName);
  return !!permissions;
};

/**
 * Get all permissions for a page as an object
 */
export const getAllPermissions = (pageName: string) => {
  const permissions = getPagePermissions(pageName);
  
  return {
    hasRead: permissions?.read === 1,
    hasWrite: permissions?.write === 1,
    hasEdit: permissions?.edit === 1,
    hasDelete: permissions?.delete === 1,
    exists: !!permissions,
  };
};

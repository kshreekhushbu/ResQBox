// Normalize input: trim, remove leading spaces, collapse 3+ spaces to 2
export function normalizeInput(value: string): string {
  if (!value) return value;
  return value
    .replace(/^\s+/, "") // remove leading spaces
    .replace(/ {3,}/g, "  "); // collapse 3+ spaces to 2
}

// Yup regex for names: only alphabets and spaces, no leading spaces, max 2 consecutive spaces
export const nameRegex = /^(?! )[A-Za-z]+( {1,2}[A-Za-z]+)*$/;

// Yup test for no leading spaces
export function noLeadingSpace(value: string) {
  return !value || !/^\s/.test(value);
}

// Yup test for max 2 consecutive spaces
export function maxTwoSpaces(value: string) {
  return !value || !/ {3,}/.test(value);
}
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

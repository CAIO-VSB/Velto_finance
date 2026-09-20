import { format } from "date-fns"

export function formatDate(value: Date | string | null | undefined) {

    if (!value) {
        return ""
    }

    const d = new Date(value)
    const utcDate = new Date(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate())

    return format(utcDate, "dd/MM/yyyy")
}
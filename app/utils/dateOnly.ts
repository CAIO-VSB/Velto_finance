import { formatInTimeZone } from "date-fns-tz"
import { datetime } from "rrule"

//Função que converte a data no envio para o bakcend
export function dateToDateOnly(date: Date): string {
    return formatInTimeZone(date, "UTC", "yyyy-MM-dd")
}

//Função que converte a data no formato que RRule precisa
export function dateOnlyToRRuleDate(value: string): Date {
    const [year, month, day] = value.split("-").map(Number)

    return datetime(year, month, day, 0, 0, 0)
}

////Função que converte a data no formato que RRule precisa
export function rruleDateToDateOnly(date: Date): string {
    const year = date.getUTCFullYear()
    const month = String(date.getUTCMonth() + 1).padStart(2, "0")
    const day = String(date.getUTCDate()).padStart(2, "0")

    return `${year}-${month}-${day}`
}

//Função que converte a data recebida do backend para o front
export function parseDateOnlyToLocalDate(value: string): Date {
    const datePart = value.split("T")[0]
    const [year, month, day] = datePart.split("-").map(Number)
    return new Date(year, month - 1, day) 
}
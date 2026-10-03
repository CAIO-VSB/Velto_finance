import type  { EChartsOption as ECOption  } from "echarts"
import { useChartTheme } from "./useChartTheme"
import type { CallbackDataParams } from "echarts/types/dist/shared"
import { useTheme } from 'vuetify'

export type BarDatum = {
    name: string | number,
    value: number,
    color?: string
}

export function useBarChart(data: MaybeRefOrGetter<BarDatum[]>) {
    const {colors, textStyle } = useChartTheme()
    const vuetifyTheme = useTheme()
    const isDark = computed(() => vuetifyTheme.global.current.value.dark)

    const option = computed<ECOption>(() => {

        return {
            darkMode: isDark.value,
            backgroundColor: 'transparent',
            color: colors,
            textStyle: textStyle.value,
            tooltip: {trigger: 'axis', valueFormatter: (value) => formatCurrency(Number(value))},
            grid: {left: 0, right: 50, top: 30 },
            dataset: {
                source: toValue(data)
            },
            xAxis: {
                type: 'category',
                axisLabel: { color: textStyle.value.color}
            },
            yAxis: {
                type: 'value',
                axisLabel: { color: textStyle.value.color}
            },
            series: [
                {
                    name: 'Total',
                    stack: 'Total',
                    type: 'bar',
                    label: {
                        show: true,
                        position: 'inside',
                        formatter: (params: CallbackDataParams) => {
                            const value = (params.value as {value: number}).value
                            return formatCurrency(value)
                        }
                    },
                    barMaxWidth: 48,
                    itemStyle: { 
                        borderRadius: [6, 6, 0, 0],
                        color: (params: any) => params.data.color ?? colors[params.dataIndex % colors.length]
                    },
                    encode: {
                        x: 'name',
                        y: 'value'
                    },
                    
                },
            ]
        }
    })

    return {option}
}
import type  { EChartsOption as ECOption  } from "echarts"
import { useChartTheme } from "./useChartTheme"

export type DonutDatum = {
    name: string,
    value: number
}

export function useDonutChart(data: MaybeRefOrGetter<DonutDatum[]>) {
    const {colors, textStyle } = useChartTheme()

    const option = computed<ECOption>(() => ({
        color: colors,
        tooltip: {
            trigger: 'item'
        },
        legend: {
            orient: 'vertical',
            left: 'left',
            textStyle
        },
        series: [
            {
                type: 'pie',
                radius: ['45%', '70%'],
                center: ['60%', '45%'],
                avoidLabelOverlap: true,
                itemStyle: {borderRadius: 10, borderColor: '#fff', borderWidth: 7},
                label: { formatter: '{b}\n{d}%' },
                data: toValue(data)
            }
        ]
    }))

    return {option}
}
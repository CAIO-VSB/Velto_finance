import type { EChartsOption as ECOption, TooltipComponentFormatterCallbackParams } from "echarts"
import { useChartTheme } from "./useChartTheme"

export type DonutDatum = {
    name: string,
    value: number
}

export function useDonutChart(
    data: MaybeRefOrGetter<DonutDatum[]>,
    center: MaybeRefOrGetter<[string, string]> = ['50%', '62%'] 
) {
    const { colors, textStyle } = useChartTheme()

    const option = computed<ECOption>(() => ({
        color: colors,
        tooltip: {
            trigger: 'item',
            formatter: (params: TooltipComponentFormatterCallbackParams) => {
                const p = Array.isArray(params) ? params[0] : params
                return `${p?.marker} ${p?.name}<br/>${formatCurrency(Number(p?.value))} (${p?.percent}%)`
            }
        },
        legend: {
            top: '5%',
            left: 'center',
        },
        series: [
            {
                type: 'pie',
                radius: ['40%', '70%'],
                center: toValue(center),   
                avoidLabelOverlap: false,
                padAngle: 5,
                data: toValue(data),

                labelLine: {
                    show: false
                },

                label: {
                    show: false,
                    position: 'center'
                },

                emphasis: {
                    label: {
                        show: true,
                        fontSize: 20,
                        fontWeight: 'bold'
                    }
                }
            },

        ]
    }))

    return { option }
}
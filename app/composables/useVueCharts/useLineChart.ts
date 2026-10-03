import type  { EChartsOption as ECOption  } from "echarts"
import { useChartTheme } from "./useChartTheme"

export type LineDatum = {
    name: string | number,
    value: number,
    color?: string
}

export function useLineChart(data: MaybeRefOrGetter<LineDatum[]>) {
    const {colors, textStyle } = useChartTheme()

    const option = computed<ECOption>(() => {

        return {
            color: colors,
            textStyle: textStyle.value,
            tooltip: {trigger: 'axis', valueFormatter: (value) => formatCurrency(Number(value))},
            grid: {left: 0, right: 50, top: 30 },
            dataset: {
                source: toValue(data)
            },
            yAxis: {type: 'value', axisLabel: { color: textStyle.value.color}},
            xAxis: {
                type: 'category',
                axisLabel: { color: textStyle.value.color}
            },
            series: [
                {
                    name: 'total',
                    stack: 'total',
                    type: 'line',
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
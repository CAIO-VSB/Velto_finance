import { useTheme } from 'vuetify'

export function useChartTheme() {
  const vuetifyTheme = useTheme()
  const isDark = computed(() => vuetifyTheme.global.current.value.dark)

  const textColor = computed(() => isDark.value ? '#E4E6EB' : '#1A1A1A')

  return {
    colors: [
      '#4F7CFF',
      '#4ECDC4',
      '#FFB020',
      '#9B7EDE', 
      '#FF9F6B', 
      '#6C7A96', 
      '#FF6B6B',
      '#2BB673',
    ],
    textStyle: computed(() => ({ fontSize: 13, color: textColor.value })),
    textColor,
  }
}
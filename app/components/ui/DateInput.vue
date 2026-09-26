<script setup lang="ts">

    import type { TPeriod} from "~~/types/period/TPeriod"
   
    const emit = defineEmits<{
        applyFilterMonth: [filter: TPeriod]
    }>()    

    const props = defineProps<{
        initialPeriod?: TPeriod | null
    }>()

    const months = ['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez']

    const fullMonths = ['Janeiro','Fevereiro','Março','Abril','Maio','Junho','Julho','Agosto','Setembro','Outubro','Novembro','Dezembro']

    const period = ref({
        month: new Date().getMonth(),
        year: new Date().getFullYear(),
    })

    const currentYear = ref(new Date().getFullYear())

    const expanded = ref(false)

    watch(() => props.initialPeriod, (newVal, oldVal) => {
        if (!newVal) return
        if (oldVal && newVal.month === oldVal.month && newVal.year === oldVal.year) return

        period.value = { month: newVal.month, year: newVal.year}
        currentYear.value = newVal.year

        emit("applyFilterMonth", period.value)
    })

    function changeYear(direction: number) {
        currentYear.value += direction
        emit("applyFilterMonth", period.value)
    }

    function prevMonth() {
        if (period.value.month === 0) {
            period.value.month = 11
            period.value.year--
            currentYear.value-- 
            emit("applyFilterMonth", period.value)
        } else {
            period.value.month--
            emit("applyFilterMonth", period.value)
        }
    }

    function nextMonth() {
        if (period.value.month === 11) {
            period.value.month = 0
            period.value.year++
            currentYear.value++ 
            emit("applyFilterMonth", period.value)
        } else {
            period.value.month++
            emit("applyFilterMonth", period.value)
        }
    }

    function selectMonth(index: number) {
        period.value.month = index
        period.value.year = currentYear.value 
        expanded.value = false
        emit("applyFilterMonth", period.value)
    }

    function isActive(index: number) {
        return index === period.value.month && currentYear.value === period.value.year
    }

    const monthLabel = computed(() => {
        return `${fullMonths[period.value.month]} ${period.value.year}`
    })

</script>

<template>
    <div>
        <v-expand-transition mode="out-in">
            <div :key="expanded ? 'months' : 'period'">
                <div
                    v-if="!expanded"
                    class="d-flex align-center justify-center ga-2"
                >
                    <v-btn
                        icon="mdi-chevron-left"
                        variant="text"
                        class="text-medium-emphasis"
                        @click="prevMonth"
                    />

                    <v-btn
                        color="primary"
                        variant="tonal"
                        rounded="lg"
                        class="text-none font-weight-bold"
                        @click="expanded = true"
                    >
                        {{ monthLabel }}

                        <v-icon
                            icon="mdi-chevron-down"
                            end
                        />
                    </v-btn>

                    <v-btn
                        icon="mdi-chevron-right"
                        variant="text"
                        class="text-medium-emphasis"
                        @click="nextMonth"
                    />
                </div>

                <v-card
                    v-else
                    rounded="xl"
                    elevation="4"
                    class="mt-2 pa-4"
                >
                    <div class="d-flex align-center justify-center ga-4 mb-4">
                        <v-btn
                            icon="mdi-chevron-left"
                            variant="text"
                            color="primary"
                            @click="changeYear(-1)"
                        />

                        <span class="text-subtitle-1 font-weight-bold">
                            {{ currentYear }}
                        </span>

                        <v-btn
                            icon="mdi-chevron-right"
                            variant="text"
                            color="primary"
                            @click="changeYear(1)"
                        />
                    </div>

                    <v-row >
                        <v-col
                            v-for="(month, index) in months"
                            :key="index"
                            cols="4"
                            sm="3"
                        >
                            <v-btn
                                :variant="isActive(index) ? 'flat' : 'outlined'"
                                color="primary"
                                rounded="lg"
                                block
                                class="text-none"
                                @click="selectMonth(index)"
                            >
                                {{ month }}
                            </v-btn>
                        </v-col>
                    </v-row>
                </v-card>
            </div>
        </v-expand-transition>
    </div>
</template>

<style scoped>
</style>
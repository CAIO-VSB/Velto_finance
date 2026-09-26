<script setup lang="ts">
    definePageMeta({
        title: "Configurações de acesso",
        layout: "layout-dashboard"
    })

    import type { TUser } from '~~/types/auth/Tauth.types'
    import { format } from 'date-fns'
    import { UAParser } from 'ua-parser-js'
    import { useAuthStore } from '~~/store/modules/auth-store'
    import { useValidateFields } from "~/composables/useValidateFields"
    import { useHttpAuth } from '~/composables/useHttp/useHtppAuth'
    import { useOnFileChange } from '~/composables/useFileChange.js'
    import DialogEditEmail from '~/pages/config/components/DialogEditEmail.vue'
    import DialogEditPassword from './components/DialogEditPassword.vue'

    import defaultUser from "~/assets/default-user.webp"
    
    const { $authClient } = useNuxtApp()
    const authStore = useAuthStore()
    const {nameRules} = useValidateFields()
    const { notifyError, notifyInfo, notifySuccess } = useNotify()
    const { getAllAuthAccounts, patchImageUser } = useHttpAuth()
    const { submitImage, isUploading } = useOnFileChange()
  

    const { data: session } = await $authClient.getSession()
    const fakePassword = ref("***********")
    const parser = new UAParser(session?.session.userAgent ?? "")
    const resultParser = parser.getResult()
    const dateFormated = format(session?.user.createdAt!, "dd/MM/yyyy HH:mm:ss")
    const inputFocus = ref(false)
    const changeName = ref(false)
    const showConfirmEditName = ref(true)
    const inputNameReadOnly = ref(true)
    const hidePencilEditName = ref(false)
    const showCardChangeEmail = ref(false)
    const showCardChangePassword = ref(false)
    const showModalAlterImage = ref(false)
    const modelImage = ref([])
    const userForm = ref<Partial<TUser>>({
      name: session?.user.name,
      email: session?.user.email,
      image: session?.user.image
    })

    if (!authStore.user) {
      await authStore.initUser()
    }

    const { data } = useQuery({
        queryKey: QUERY_KEYS.auth.all,
        queryFn: getAllAuthAccounts,
    })

    const userProvider = computed(() => {
        return data.value?.find(item => item.userId === session?.session.userId) ?? null
    })
    
    const provedor = computed(() => {
        if (!userProvider.value) return ""
        if (userProvider.value.providerId === 'credential') {
            return "e-mail e senha"
        }
        return userProvider.value.providerId.charAt(0).toUpperCase() + userProvider.value.providerId.slice(1)
    })

    const headers = [
        { key: 'dispositivo', title: 'Dispositivo'},
        { key: 'inicio', title: 'Inicio' },
        { key: 'expiracao', title: 'Expiração' },
    ]

    const items = computed(() => [
      {
        dispositivo: `${resultParser.os.name} ${resultParser.os.version} (${resultParser.browser})`,
        inicio: format(session?.session.createdAt!, "dd/MM/yyyy HH:mm:ss"),
        expiracao: format(session?.session.expiresAt!, "dd/MM/yyyy HH:mm:ss")
      }
    ])

    async function onFileChange() {

      try {
  
        if (!modelImage.value.length) {
          notifyInfo(
            "Atenção",
            "Selecione uma imagem para continuar.",
            5000
          )
          return
        }
        
        const res = await submitImage(modelImage.value)
    
        userForm.value.image = res

        await patchImageUser(res)
        authStore.updateUserImage(res)
        
        showModalAlterImage.value = false

      } catch (e) {
        notifyError("Erro", "Não foi possível enviar a imagem.", 7000)
      } finally {
        isUploading.value = false
      }
    }

    function enableNameEditing() {
        changeName.value = true
        inputFocus.value = true
        inputNameReadOnly.value = false
        showConfirmEditName.value = false
        hidePencilEditName.value = true
    }

    function resetStates() {
        changeName.value = false
        inputFocus.value = false
        inputNameReadOnly.value = true
        showConfirmEditName.value = true
        hidePencilEditName.value = false
        showCardChangeEmail.value = false
    } 

    function handleOpenModalSubmitEmail() {
        showCardChangeEmail.value = true
    }

    function handleCloseModalSubmitEmail() {
        showCardChangeEmail.value = false
    }

    function handleOpenModalSubmitPassword() {
        showCardChangePassword.value = true
    }

    function handleCloseModalSubmitPassword() {
        showCardChangePassword.value = false
    }

    async function hanldeUpdateUser() {
        if (!userForm.value.name) {
            notifyInfo("Atenção", "O nome não pode ficar em branco.", 7000, true)
            return
        }

        if (userForm.value.name.length > 30) {
            notifyInfo("Atenção", "O nome informado é muito longo. Use até 30 caracteres.", 7000, true)
            return
        }
        await authStore.alterUser(userForm.value)
        resetStates()
    }

</script>

<template>
  <v-container fluid class="mt-6 pa-4">
    <v-row>
      <v-col cols="12" lg="4">
        <v-card rounded="lg" elevation="2" >
          <v-card-item class="pa-4 pb-2">
            <v-card-title class="text-h6 font-weight-bold text-blue-grey-darken">
              Meu perfil
            </v-card-title>

            <v-card-subtitle class="mt-1">
              Gerencie as informações do seu perfil.
            </v-card-subtitle>
          </v-card-item>

  
          <v-divider />

          <v-card-text class="pa-6 text-center">
          <v-img
              class="mx-auto mb-4"
              height="200"
              :lazy-src="defaultUser"
              max-width="200"
              style="border-radius: 50%;"
              :src="authStore.user?.image || defaultUser"
              cover
            >
              <template v-slot:placeholder>
                <div class="d-flex align-center justify-center fill-height">
                  <v-progress-circular
                    color="grey-lighten-4"
                    indeterminate
                  ></v-progress-circular>
                </div>
              </template>
            </v-img>

            <div class="text-subtitle-2 font-weight-bold text-blue-grey-darken text-truncate">
              {{ authStore.user?.name}}
            </div>

            <div class="text-body-2 text-medium-emphasis text-truncate mt-1">
              {{ authStore.user?.email }}
            </div>

            <div>
              <v-dialog max-width="500" v-model="showModalAlterImage">
                <template v-slot:activator="{ props: activatorProps }">
                  <v-btn
                  v-bind="activatorProps"
                  prepend-icon="mdi-camera"
                  color="primary"
                  variant="tonal"
                  rounded="lg"
                  class="text-none mt-6"
                  >
                  alterar foto
                  </v-btn> 
                </template>

                <template v-slot:default="{ isActive }">
                  <v-card class="pa-4">
                    <v-file-upload :disabled="isUploading" :loading="isUploading" accept="image/*" show-size clearable v-model="modelImage"  variant="comfortable"></v-file-upload>
                    <v-btn
                    color="primary"
                    variant="flat"
                    rounded="lg"  
                    @click="onFileChange"
                    prepend-icon="mdi-content-save-check"
                    :disabled="isUploading"
                    >
                      Salvar
                    </v-btn>
                  </v-card>
                </template>
              </v-dialog>
            </div>       

          </v-card-text>
        </v-card>
      </v-col>
      <v-col cols="12" lg="8" class="d-flex flex-column ga-4">
        <v-card rounded="lg" elevation="2">
          <v-card-item class="pa-4 pb-2">
            <v-card-title class="text-h6 font-weight-bold text-blue-grey-darken">
              Dados da conta
            </v-card-title>

            <v-card-subtitle class="mt-1">
              Mantenha seus dados sempre atualizados.
            </v-card-subtitle>
          </v-card-item>

          <v-divider />

          <v-card-text v-if="session?.user" class="pa-4 pa-sm-6">
            <v-row>
              <v-col cols="12">
                <v-text-field
                  v-model="userForm.name"
                  :rules="nameRules"
                  :focused="inputFocus"
                  :readonly="inputNameReadOnly"
                  counter="30"
                  label="Nome"
                  variant="outlined"
                  density="comfortable"
                  color="primary"
                  hide-details="auto"
                >
                  <template #append-inner>
                    <v-tooltip text="Editar nome">
                      <template #activator="{ props }">
                        <v-btn
                          v-bind="props"
                          :class="{ 'd-none': hidePencilEditName }"
                          icon="mdi-pencil"
                          variant="text"
                          size="small"
                          density="compact"
                          @click="enableNameEditing"
                        />
                      </template>
                    </v-tooltip>

                    <v-tooltip text="Salvar alterações">
                      <template #activator="{ props }">
                        <v-btn
                          v-bind="props"
                          :class="{ 'd-none': showConfirmEditName }"
                          icon="mdi-check"
                          color="primary"
                          variant="text"
                          size="small"
                          density="compact"
                          @click="hanldeUpdateUser"
                        />
                      </template>
                    </v-tooltip>
                  </template>
                </v-text-field>
              </v-col>

              <v-col cols="12" sm="6">
                <v-text-field
                  v-model="userForm.email"
                  :disabled="provedor === 'Discord' || provedor === 'Google'"
                  readonly
                  label="E-mail de acesso"
                  variant="outlined"
                  density="comfortable"
                  color="primary"
                  hide-details="auto"
                >
                  <template #append-inner>
                    <v-tooltip text="Editar e-mail">
                      <template #activator="{ props }">
                        <v-btn
                          v-bind="props"
                          icon="mdi-pencil"
                          variant="text"
                          size="small"
                          density="compact"
                          @click="handleOpenModalSubmitEmail"
                        />
                      </template>
                    </v-tooltip>
                  </template>
                </v-text-field>
              </v-col>

              <v-col cols="12" sm="6">
                <v-text-field
                  v-model="fakePassword"
                  :disabled="provedor === 'Discord' || provedor === 'Google'"
                  readonly
                  label="Senha"
                  variant="outlined"
                  density="comfortable"
                  color="primary"
                  hide-details="auto"
                >
                  <template #append-inner>
                    <v-tooltip text="Editar senha">
                      <template #activator="{ props }">
                        <v-btn
                          v-bind="props"
                          icon="mdi-pencil"
                          variant="text"
                          size="small"
                          density="compact"
                          @click="handleOpenModalSubmitPassword"
                        />
                      </template>
                    </v-tooltip>
                  </template>
                </v-text-field>
              </v-col>

              <v-col v-if="userProvider" cols="12" sm="6">
                <v-text-field
                  v-model="provedor"
                  readonly
                  label="Método de login"
                  variant="outlined"
                  density="comfortable"
                  color="primary"
                  hide-details="auto"
                />
              </v-col>

              <v-col cols="12" sm="6">
                <v-text-field
                  v-model="dateFormated"
                  readonly
                  label="Criado em"
                  variant="outlined"
                  density="comfortable"
                  color="primary"
                  hide-details="auto"
                />
              </v-col>
            </v-row>
          </v-card-text>
        </v-card>

        <v-card rounded="lg" elevation="2">
          <v-card-item class="pa-4 pb-2">
            <v-card-title class="text-h6 font-weight-bold text-blue-grey-darken">
              Informações da sessão
            </v-card-title>

            <v-card-subtitle class="mt-1">
              Veja as informações da sua sessão atual.
            </v-card-subtitle>

            <template #append>
              <v-tooltip text="Encerrar sessão atual">
                <template #activator="{ props }">
                  <v-btn
                    v-bind="props"
                    icon="mdi-power"
                    color="error"
                    variant="text"
                    size="small"
                    @click="authStore.logout()"
                  />
                </template>
              </v-tooltip>
            </template>
          </v-card-item>

          <v-divider />

          <v-data-table
            :headers="headers"
            :items="items"
            mobile-breakpoint="md"
            hide-default-footer
          >
            <template #item.dispositivo>
              <div class="d-flex align-center ga-2">
                <v-icon icon="mdi-monitor" size="small" color="primary" />
                <span>
                  {{ `${resultParser.os.name} ${resultParser.os.version} (${resultParser.browser})` }}
                </span>
              </div>
            </template>
          </v-data-table>
        </v-card>

        <v-alert
          type="info"
          variant="tonal"
          density="comfortable"
          icon="mdi-information-outline"
          class="ma-0"
        >
          Nem todas as informações estão disponíveis para todas as contas.
          Se você utiliza um provedor de login, como Google ou Discord,
          alguns campos podem aparecer vazios ou não permitir edição.
          Isso é esperado.
        </v-alert>
      </v-col>
    </v-row>
  </v-container>

  <DialogEditEmail
    :email="userForm.email"
    :model-value="showCardChangeEmail"
    @close-modal="handleCloseModalSubmitEmail"
  />

  <DialogEditPassword
    :model-value="showCardChangePassword"
    @close-modal="handleCloseModalSubmitPassword"
  />
</template>

<style scoped>
.user-avatar {
  object-fit: cover;
}

:deep(.v-data-table-header__content) {
  font-weight: 700;
}
</style>
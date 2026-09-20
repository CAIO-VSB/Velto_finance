export function useOnFileChange() {
    const { notifyError, notifyInfo, notifySuccess } = useNotify()
    const config = useRuntimeConfig()
    const isUploading = ref(false)

    const submitImage = async (files: File[]) => {

        const file = files[0]

        if (!file) {
            notifyInfo(
                "Atenção",
                "Selecione uma imagem para continuar.",
                5000
            )
            return
        }

        isUploading.value = true

        const formData = new FormData()
        formData.append('file', file)
        formData.append('upload_preset', 'ml_default')

        try {

            const res = await fetch( `https://api.cloudinary.com/v1_1/${config.public.cloudinaryCloudName}/image/upload`,
                {method: "POST", body: formData}
            )
            
            const data = await res.json()

            if (!res.ok) {
                console.error("Cloudinary error:", data)
                notifyError("Erro", "O serviço está sobrecarregado no momento. Tente novamente em alguns instantes.", 8000)
                return
            }

            notifySuccess("Sucesso", "Operação realizada com sucesso", 5000)


            return data.secure_url

        } catch (e) {
            notifyError("Erro", "Não foi possível enviar a imagem.", 7000)
        } finally {
            isUploading.value = false
        }
    }

    return {
        submitImage, 
        isUploading,
    }
}
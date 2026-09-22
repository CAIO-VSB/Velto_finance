// https://nuxt.com/docs/api/configuration/nuxt-config
import vuetify, { transformAssetUrls } from 'vite-plugin-vuetify'

export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  devtools: { enabled: false },
  css: ['~/assets/css/main.css',],
  ssr: false,
  spaLoadingTemplate: true,

  build: {
    transpile: ['vuetify']
  },

  toast: {composableName: 'useNotification'},
  
  modules: [
    '@peterbud/nuxt-query',
    '@nuxt/eslint',
    '@nuxt/fonts',
    '@nuxt/icon',
    '@nuxt/image',
    '@nuxt/test-utils',
    '@nuxt/ui',
    '@pinia/nuxt',
    '@nuxtjs/cloudinary',
    '@vee-validate/nuxt',
    'pinia-plugin-persistedstate/nuxt',
    'nuxt-toast',
    'nuxt-echarts',
    "nuxt-api-shield",
    (_options, nuxt) => {
      nuxt.hooks.hook('vite:extendConfig', (config, { isClient }) => {
        if (!isClient) return

        config.plugins ??=[]
        config.plugins?.push(vuetify({ autoImport: true}))
      })
    },
  ],

  echarts: {
    renderer: ['svg', 'canvas'],
    charts: ['BarChart', 'LineChart', 'PieChart'],
    components: ['DatasetComponent', 'GridComponent', 'TooltipComponent', 'LegendComponent', 'TitleComponent'],
    features: ['LabelLayout', 'UniversalTransition']
  },


  nuxtApiShield: {

    limit: {
      max: 10,
      duration: 10,
      ban: 10,
    },

    delayOnBan: true,
    errorMessage: "Too many Requests",
    retryAfterHeader: true,
    
    log: {
      path: "./logs/nuxt-api-shield",
      attempts: 1,
      fail2ban: true,
    },

    routes: ["/api/auth/sign-in/email"],
    skipRoutes: [],
    ipTTL: 7 * 24 * 60 * 60,

    security: {
      trustXForwardedFor: false,
    }
  },

  
  nitro: {
    "storage": {
      "shield": {
        "driver": "memory"
      }
    },
    experimental: {tasks: true},
    scheduledTasks: {
      '0 1 * * *': ['alertInvoices']
    },
  },

  nuxtQuery: {
    autoImports: ["useQuery", "useMutation", "useQueryClient"],
    devtools: true,

    queryClientOptions: {
      defaultOptions: {
        queries: {
          refetchOnWindowFocus: false,
        }
      }
    }
  },

  ignore: [
    'pages/**/types/**'
  ],

  app: {
    head: {
      title: 'Velto finance',
      meta: [
        {name: "referrer", content: "no-referrer"}
      ],

      link: [
      { rel: 'icon', type: 'image/png', sizes: '32x32', href: '/genfavicon-32.png' },
      { rel: 'icon', type: 'image/png', sizes: '16x16', href: '/genfavicon-16.png' },
      { rel: 'apple-touch-icon', sizes: '180x180', href: '/apple-touch-icon-180x180.png' },
      {rel: 'manifest', href: '/manifest.webmanifest'}
    ]
    },
  },
  
  vite: {
    vue: {
      template: {
        transformAssetUrls
      }
    },
  },

  // Define variáveis que só estarão disponíveis no lado do servidor (Server-side)
  runtimeConfig: {
  // Mapeia a variável de ambiente DATABASE_URL que o Docker vai injetar
    databaseUrl: process.env.DATABASE_URL,
    public: {
      cloudinaryCloudName: '',
      cloudinaryUploadPreset: 'ml_default'
    }
  },

  // Ativa os recursos e a estrutura de pastas do Nuxt 4
  future: {
    compatibilityVersion: 4,
  },

  
})
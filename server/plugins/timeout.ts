import { Agent, setGlobalDispatcher } from 'undici'

export default defineNitroPlugin(() => {
    setGlobalDispatcher(new Agent({
        connect: {
            timeout: 20000, 
            autoSelectFamily: true
        }
    }))
})
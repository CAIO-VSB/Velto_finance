export default defineNuxtRouteMiddleware(async (to, from) => {
	const { $authClient } = useNuxtApp()

	const publicRoutes = ['/login-page', '/register-page', '/recover-password-page', '/reset-password-page', '/unauthorized']

	if (to.path.startsWith('/api/auth')) {
		return
	}

	if (publicRoutes.includes(to.path) || to.path.includes('callback')) {
		return
	}

	const { data: session } = await $authClient.getSession()

	const isAutenticated = !!session?.session.token

	if (!isAutenticated) {
		return navigateTo('/unauthorized')
	}
});
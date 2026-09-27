export default defineNuxtRouteMiddleware(async (to, from) => {
	const { $authClient } = useNuxtApp()

	const guestOnlyRoutes = ['/login-page', '/register-page', '/recover-password-page', '/reset-password-page']

	const publicRoutes = ['/unauthorized']

	if (to.path.startsWith('/api/auth')) {
		return
	}

	if (publicRoutes.includes(to.path) || to.path.includes('callback')) {
		return
	}

	const { data: session } = await $authClient.getSession()

	const isAutenticated = !!session?.session.token

	if (isAutenticated && guestOnlyRoutes.includes(to.path)) {
		return navigateTo('/dashboard')
	}

	if (guestOnlyRoutes.includes(to.path)) {
		return
	}

	if (!isAutenticated) {
		return navigateTo('/unauthorized')
	}
});
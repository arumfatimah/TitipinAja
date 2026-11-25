<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class RoleMiddleware
{
    public function handle(
        Request $request,
        Closure $next,
        string ...$roles
    ): Response {

        // Memastikan pengguna sudah login
        $user = $request->user();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'Kamu harus login terlebih dahulu.',
            ], 401);
        }

        // Memastikan role pengguna sesuai
        if (!in_array($user->role, $roles, true)) {
            return response()->json([
                'success' => false,
                'message' => 'Kamu tidak memiliki akses ke fitur ini.',
            ], 403);
        }

        // Jika sesuai, lanjutkan ke controller
        return $next($request);
    }
}

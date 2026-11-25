<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    // ==========================================
    // REGISTRASI PENGGUNA
    // ==========================================

    public function register(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|max:255|unique:users,email',
            'password' => 'required|string|min:8|confirmed',
            'role' => 'required|in:pelanggan,penyedia',
        ]);

        // Membuat akun pengguna baru
        // Password otomatis di-hash oleh User model
        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => $validated['password'],
            'role' => $validated['role'],
        ]);

        // Membuat token autentikasi
        $token = $user->createToken(
            'titipinaja-mobile'
        )->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Registrasi berhasil.',
            'data' => [
                'user' => $user,
                'token' => $token,
                'token_type' => 'Bearer',
            ],
        ], 201);
    }

    // ==========================================
    // LOGIN PENGGUNA
    // ==========================================

    public function login(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        // Mencari pengguna berdasarkan email
        $user = User::where(
            'email',
            $validated['email']
        )->first();

        // Memeriksa email dan password
        if (
            !$user ||
            !Hash::check(
                $validated['password'],
                $user->password
            )
        ) {
            return response()->json([
                'success' => false,
                'message' => 'Email atau password salah.',
            ], 401);
        }

        // Membuat token login
        $token = $user->createToken(
            'titipinaja-mobile'
        )->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Login berhasil.',
            'data' => [
                'user' => $user,
                'token' => $token,
                'token_type' => 'Bearer',
            ],
        ]);
    }

    // ==========================================
    // LOGOUT PENGGUNA
    // ==========================================

    public function logout(Request $request)
    {
        // Mengambil token yang sedang digunakan
        $currentToken = $request->user()->currentAccessToken();

        // Menghapus token aktif
        if ($currentToken) {
            $currentToken->delete();
        }

        return response()->json([
            'success' => true,
            'message' => 'Logout berhasil.',
        ]);
    }
}

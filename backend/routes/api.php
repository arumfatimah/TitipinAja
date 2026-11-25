
<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Http\Request;

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\StorageSlotController;
use App\Http\Controllers\StorageRequestController;
use App\Http\Controllers\StoragePlaceController;
use App\Http\Controllers\PaymentController;

// ==========================================
// API PUBLIK
// Tidak membutuhkan token login
// ==========================================

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);


// ==========================================
// API WAJIB LOGIN
// Seluruh route di dalam grup ini memerlukan
// token Laravel Sanctum yang valid
// ==========================================

Route::middleware('auth:sanctum')->group(function () {

    // Informasi akun pengguna yang sedang login
    Route::get('/me', function (Request $request) {
        return response()->json([
            'success' => true,
            'message' => 'Data pengguna berhasil diambil.',
            'data' => $request->user(),
        ]);
    });

    // Logout
    Route::post('/logout', [AuthController::class, 'logout']);


    // ======================================
    // API YANG BISA DIAKSES KEDUA ROLE
    // ======================================

    Route::middleware('role:pelanggan,penyedia')->group(function () {

        // Melihat tempat penyimpanan
        Route::get('/storage-places', [StoragePlaceController::class, 'index']);
        Route::get('/storage-places/{id}', [StoragePlaceController::class, 'show']);

        // Melihat kategori slot
        Route::get('/storage-slots', [StorageSlotController::class, 'index']);
        Route::get('/storage-slots/{id}', [StorageSlotController::class, 'show']);

        // Melihat detail pemesanan
        Route::get('/storage-requests/{id}', [StorageRequestController::class, 'show']);

    });


    // ======================================
    // KHUSUS PELANGGAN
    // ======================================

    Route::middleware('role:pelanggan')->group(function () {

    // Membuat tagihan pembayaran
Route::post(
    '/storage-requests/{id}/payment',
    [PaymentController::class, 'store']
);

// Melihat detail pembayaran
Route::get(
    '/payments/{id}',
    [PaymentController::class, 'show']
);

// Simulasi pembayaran berhasil (khusus development)
Route::post(
    '/payments/{id}/simulate-success',
    [PaymentController::class, 'simulateSuccess']
);

        // Membuat pemesanan
        Route::post('/storage-requests', [StorageRequestController::class, 'store']);

        // Riwayat pemesanan pelanggan
        Route::get(
            '/my-requests/{userId}',
            [StorageRequestController::class, 'myRequests']
        );

        // Membatalkan pemesanan
        Route::patch(
            '/storage-requests/{id}/cancel',
            [StorageRequestController::class, 'cancel']


        );

    });


    // ======================================
    // KHUSUS PENYEDIA
    // ======================================

    Route::middleware('role:penyedia')->group(function () {

        // Membuat tempat penyimpanan
        Route::post('/storage-places', [StoragePlaceController::class, 'store']);

        // Mengubah tempat penyimpanan
        Route::put('/storage-places/{id}', [StoragePlaceController::class, 'update']);
        Route::patch('/storage-places/{id}', [StoragePlaceController::class, 'update']);

        // Menghapus tempat penyimpanan
        Route::delete('/storage-places/{id}', [StoragePlaceController::class, 'destroy']);

        // Mengubah status ketersediaan slot
        Route::put('/storage-slots/{id}', [StorageSlotController::class, 'update']);
        Route::patch('/storage-slots/{id}', [StorageSlotController::class, 'update']);

        // Riwayat pemesanan masuk penyedia
        Route::get(
            '/incoming-requests/{userId}',
            [StorageRequestController::class, 'incomingRequests']
        );

        // Riwayat penyewaan penyedia
        Route::get(
            '/owner-history/{userId}',
            [StorageRequestController::class, 'ownerHistory']
        );

        // Mengubah status penitipan
        Route::patch(
            '/storage-requests/{id}/status',
            [StorageRequestController::class, 'updateStatus']
        );

    });

});

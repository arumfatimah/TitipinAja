<?php

namespace App\Http\Controllers;

use App\Models\StorageSlot;
use Illuminate\Http\Request;

class StorageSlotController extends Controller
{
    // ==========================================
    // MENAMPILKAN SEMUA SLOT
    // ==========================================

    public function index(Request $request)
    {
        $user = $request->user();

        $query = StorageSlot::with('storagePlace');

        // Pelanggan hanya melihat slot dari tempat yang aktif
        if ($user->role === 'pelanggan') {
            $query->whereHas('storagePlace', function ($placeQuery) {
                $placeQuery->where('status', 'active');
            });
        }

        // Penyedia hanya melihat slot miliknya sendiri
        if ($user->role === 'penyedia') {
            $query->whereHas('storagePlace', function ($placeQuery) use ($user) {
                $placeQuery->where('user_id', $user->id);
            });
        }

        $slots = $query
            ->orderBy('storage_place_id')
            ->orderBy('id')
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'Data slot penyimpanan berhasil diambil.',
            'data' => $slots
        ]);
    }


    // ==========================================
    // MENAMPILKAN DETAIL SLOT
    // ==========================================

    public function show(Request $request, $id)
    {
        $user = $request->user();

        $slot = StorageSlot::with('storagePlace')->find($id);

        if (!$slot) {
            return response()->json([
                'success' => false,
                'message' => 'Slot penyimpanan tidak ditemukan.'
            ], 404);
        }

        $place = $slot->storagePlace;

        // Pelanggan hanya dapat melihat slot dari tempat aktif
        if (
            $user->role === 'pelanggan' &&
            $place->status !== 'active'
        ) {
            return response()->json([
                'success' => false,
                'message' => 'Slot penyimpanan tidak tersedia.'
            ], 404);
        }

        // Penyedia hanya dapat melihat slot miliknya sendiri
        if (
            $user->role === 'penyedia' &&
            (int) $place->user_id !== (int) $user->id
        ) {
            return response()->json([
                'success' => false,
                'message' => 'Kamu tidak memiliki akses ke slot ini.'
            ], 403);
        }

        return response()->json([
            'success' => true,
            'message' => 'Detail slot penyimpanan berhasil diambil.',
            'data' => $slot
        ]);
    }


    // ==========================================
    // MEMBUAT SLOT
    // ==========================================

    public function store(Request $request)
    {
        // Slot tidak dibuat secara manual.
        // Empat kategori slot otomatis dibuat
        // ketika penyedia membuat tempat penyimpanan.

        return response()->json([
            'success' => false,
            'message' => 'Slot S, M, L, dan XL dibuat secara otomatis ketika tempat penyimpanan dibuat.'
        ], 405);
    }


    // ==========================================
    // MENGUBAH KETERSEDIAAN SLOT
    // ==========================================

    public function update(Request $request, $id)
    {
        $user = $request->user();

        $slot = StorageSlot::with('storagePlace')->find($id);

        if (!$slot) {
            return response()->json([
                'success' => false,
                'message' => 'Slot penyimpanan tidak ditemukan.'
            ], 404);
        }

        // Memastikan slot dimiliki oleh penyedia yang login
        if (
            (int) $slot->storagePlace->user_id !== (int) $user->id
        ) {
            return response()->json([
                'success' => false,
                'message' => 'Kamu tidak memiliki akses untuk mengubah slot ini.'
            ], 403);
        }

        // Penyedia hanya boleh mengubah status ketersediaan
        // Kapasitas, ukuran, dan harga tidak dapat diubah di sini
        $validated = $request->validate([
            'is_available' => 'required|boolean'
        ]);

        $slot->update([
            'is_available' => $validated['is_available']
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Ketersediaan slot berhasil diperbarui.',
            'data' => $slot->load('storagePlace')
        ]);
    }


    // ==========================================
    // MENGHAPUS SLOT
    // ==========================================

    public function destroy(Request $request, $id)
    {
        // Slot tidak dapat dihapus secara manual.
        // Setiap tempat penyimpanan harus memiliki
        // empat kategori slot: S, M, L, dan XL.

        return response()->json([
            'success' => false,
            'message' => 'Slot tidak dapat dihapus karena merupakan bagian tetap dari konfigurasi tempat penyimpanan.'
        ], 405);
    }
}

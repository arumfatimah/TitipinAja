<?php

namespace App\Http\Controllers;

use App\Models\StoragePlace;
use App\Models\StorageRequest;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class StoragePlaceController extends Controller
{
    // ==========================================
    // MENAMPILKAN TEMPAT PENYIMPANAN
    // ==========================================

    public function index(Request $request)
    {
        $user = $request->user();

        $query = StoragePlace::with([
            'user',
            'storageSlots'
        ]);

        // Pelanggan dapat melihat tempat yang aktif
        if ($user->role === 'pelanggan') {
            $query->where('status', 'active');
        }

        // Penyedia hanya dapat melihat tempat miliknya
        if ($user->role === 'penyedia') {
            $query->where('user_id', $user->id);
        }

        $places = $query->latest()->get();

        return response()->json([
            'success' => true,
            'message' => 'Data tempat penyimpanan berhasil diambil.',
            'data' => $places
        ]);
    }

    // ==========================================
    // DETAIL TEMPAT PENYIMPANAN
    // ==========================================

    public function show(Request $request, $id)
    {
        $user = $request->user();

        $place = StoragePlace::with([
            'user',
            'storageSlots'
        ])->find($id);

        if (!$place) {
            return response()->json([
                'success' => false,
                'message' => 'Tempat penyimpanan tidak ditemukan.'
            ], 404);
        }

        // Pelanggan hanya boleh melihat tempat aktif
        if (
            $user->role === 'pelanggan' &&
            $place->status !== 'active'
        ) {
            return response()->json([
                'success' => false,
                'message' => 'Tempat penyimpanan tidak tersedia.'
            ], 404);
        }

        // Penyedia hanya boleh melihat tempat miliknya
        if (
            $user->role === 'penyedia' &&
            (int) $place->user_id !== (int) $user->id
        ) {
            return response()->json([
                'success' => false,
                'message' => 'Kamu tidak memiliki akses ke tempat penyimpanan ini.'
            ], 403);
        }

        return response()->json([
            'success' => true,
            'message' => 'Detail tempat penyimpanan berhasil diambil.',
            'data' => $place
        ]);
    }

    // ==========================================
    // MEMBUAT TEMPAT PENYIMPANAN
    // ==========================================

    public function store(Request $request)
    {
        // Identitas penyedia berasal dari token login
        $user = $request->user();

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'address' => 'required|string',
            'city' => 'required|string|max:255',
            'latitude' => 'nullable|numeric|between:-90,90',
            'longitude' => 'nullable|numeric|between:-180,180',
        ]);

        $place = DB::transaction(function () use ($validated, $user) {

            // Membuat satu tempat penyimpanan
            $place = StoragePlace::create([
                'user_id' => $user->id,
                'name' => $validated['name'],
                'description' => $validated['description'] ?? null,
                'address' => $validated['address'],
                'city' => $validated['city'],
                'latitude' => $validated['latitude'] ?? null,
                'longitude' => $validated['longitude'] ?? null,
                'capacity' => 40,
                'price_per_day' => 0,
                'status' => 'active',
            ]);

            // Konfigurasi empat ukuran slot
            $slotConfigurations = [
                [
                    'slot_name' => 'Slot S',
                    'size' => 'S',
                    'capacity' => 10,
                    'price_per_day' => 8000,
                ],
                [
                    'slot_name' => 'Slot M',
                    'size' => 'M',
                    'capacity' => 10,
                    'price_per_day' => 10000,
                ],
                [
                    'slot_name' => 'Slot L',
                    'size' => 'L',
                    'capacity' => 10,
                    'price_per_day' => 12000,
                ],
                [
                    'slot_name' => 'Slot XL',
                    'size' => 'XL',
                    'capacity' => 10,
                    'price_per_day' => 15000,
                ],
            ];

            // Membuat empat slot secara otomatis
            foreach ($slotConfigurations as $configuration) {
                $place->storageSlots()->create([
                    'slot_name' => $configuration['slot_name'],
                    'size' => $configuration['size'],
                    'capacity' => $configuration['capacity'],
                    'occupied' => 0,
                    'price_per_day' => $configuration['price_per_day'],
                    'is_available' => true,
                ]);
            }

            return $place;
        });

        return response()->json([
            'success' => true,
            'message' => 'Tempat penyimpanan dan empat kategori slot berhasil dibuat.',
            'data' => $place->load([
                'user',
                'storageSlots'
            ])
        ], 201);
    }

    // ==========================================
    // MENGEDIT TEMPAT PENYIMPANAN
    // ==========================================

    public function update(Request $request, $id)
    {
        $user = $request->user();

        // Mencari tempat yang benar-benar milik penyedia login
        $place = StoragePlace::where('user_id', $user->id)
            ->find($id);

        if (!$place) {
            return response()->json([
                'success' => false,
                'message' => 'Tempat penyimpanan tidak ditemukan atau bukan milikmu.'
            ], 404);
        }

        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'description' => 'sometimes|nullable|string',
            'address' => 'sometimes|required|string',
            'city' => 'sometimes|required|string|max:255',
            'latitude' => 'sometimes|nullable|numeric|between:-90,90',
            'longitude' => 'sometimes|nullable|numeric|between:-180,180',
            'status' => 'sometimes|required|in:active,inactive',
        ]);

        // Kapasitas, harga, dan pemilik tidak dapat diubah dari endpoint ini
        $place->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Tempat penyimpanan berhasil diperbarui.',
            'data' => $place->load([
                'user',
                'storageSlots'
            ])
        ]);
    }

    // ==========================================
    // MENGHAPUS TEMPAT PENYIMPANAN
    // ==========================================

    public function destroy(Request $request, $id)
    {
        $user = $request->user();

        // Memastikan tempat dimiliki penyedia yang login
        $place = StoragePlace::where('user_id', $user->id)
            ->find($id);

        if (!$place) {
            return response()->json([
                'success' => false,
                'message' => 'Tempat penyimpanan tidak ditemukan atau bukan milikmu.'
            ], 404);
        }

        // Mempertahankan riwayat pemesanan
        $hasRequests = StorageRequest::where(
            'storage_place_id',
            $place->id
        )->exists();

        if ($hasRequests) {
            return response()->json([
                'success' => false,
                'message' => 'Tempat penyimpanan tidak dapat dihapus karena memiliki riwayat pemesanan.'
            ], 422);
        }

        $place->delete();

        return response()->json([
            'success' => true,
            'message' => 'Tempat penyimpanan berhasil dihapus.'
        ]);
    }
}
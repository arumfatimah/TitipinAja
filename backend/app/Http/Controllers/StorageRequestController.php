<?php

namespace App\Http\Controllers;

use App\Models\StorageRequest;
use App\Models\StorageSlot;
use App\Models\StoragePlace;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Carbon\Carbon;

class StorageRequestController extends Controller
{
    private const ACTIVE_STATUSES = [
        'pending',
        'approved',
        'checked_in',
    ];

    // ==========================================
    // MELIHAT RIWAYAT PEMESANAN SESUAI ROLE
    // ==========================================

    public function index(Request $request)
    {
        $user = $request->user();

        $query = StorageRequest::with([
            'user',
            'storagePlace',
            'storageSlot'
        ]);

        if ($user->role === 'pelanggan') {
            $query->where('user_id', $user->id);
        } else {
            $query->whereHas('storagePlace', function ($query) use ($user) {
                $query->where('user_id', $user->id);
            });
        }

        return response()->json([
            'success' => true,
            'message' => 'Data pemesanan berhasil diambil.',
            'data' => $query->latest()->get()
        ]);
    }

    // ==========================================
    // DETAIL PEMESANAN
    // ==========================================

    public function show(Request $request, $id)
    {
        $user = $request->user();

        $requestData = StorageRequest::with([
            'user',
            'storagePlace',
            'storageSlot',
            'payment'
        ])->find($id);

        if (!$requestData) {
            return response()->json([
                'success' => false,
                'message' => 'Pemesanan tidak ditemukan.'
            ], 404);
        }

        if (
            $user->role === 'pelanggan' &&
            (int) $requestData->user_id !== (int) $user->id
        ) {
            return response()->json([
                'success' => false,
                'message' => 'Kamu tidak memiliki akses ke pemesanan ini.'
            ], 403);
        }

        if (
            $user->role === 'penyedia' &&
            (int) $requestData->storagePlace->user_id !== (int) $user->id
        ) {
            return response()->json([
                'success' => false,
                'message' => 'Kamu tidak memiliki akses ke pemesanan ini.'
            ], 403);
        }

        return response()->json([
            'success' => true,
            'message' => 'Detail pemesanan berhasil diambil.',
            'data' => $requestData
        ]);
    }

    // ==========================================
    // MEMBUAT PEMESANAN
    // ==========================================

    public function store(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'storage_place_id' => 'required|exists:storage_places,id',
            'storage_slot_id' => 'required|exists:storage_slots,id',

            'item_name' => 'required|string|max:255',
            'item_category' => 'required|string|max:100',
            'item_description' => 'nullable|string',
            'quantity' => 'required|integer|min:1',

            'estimated_weight' => 'nullable|numeric|gt:0',
            'photo' => 'nullable|image|mimes:jpg,jpeg,png,webp|max:5120',
            'special_notes' => 'nullable|string',

            'start_date' => 'required|date|after_or_equal:today',
            'end_date' => 'required|date|after:start_date',
        ]);

        return DB::transaction(function () use ($validated, $user, $request) {

            // Mengunci slot selama pemeriksaan kapasitas
            $slot = StorageSlot::whereKey(
                $validated['storage_slot_id']
            )->lockForUpdate()->first();

            if (!$slot) {
                return response()->json([
                    'success' => false,
                    'message' => 'Slot penyimpanan tidak ditemukan.'
                ], 404);
            }

            // Memastikan tempat penyimpanan aktif
            $place = StoragePlace::find(
                $validated['storage_place_id']
            );

            if (!$place || $place->status !== 'active') {
                return response()->json([
                    'success' => false,
                    'message' => 'Tempat penyimpanan tidak aktif atau tidak ditemukan.'
                ], 422);
            }

            // Memastikan slot sesuai dengan tempat penyimpanan
            if (
                (int) $slot->storage_place_id !==
                (int) $validated['storage_place_id']
            ) {
                return response()->json([
                    'success' => false,
                    'message' => 'Slot tidak sesuai dengan tempat penyimpanan.'
                ], 422);
            }

            // Memeriksa ukuran slot
            $size = strtoupper(trim($slot->size));

            if (!in_array($size, ['S', 'M', 'L', 'XL'], true)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Ukuran slot tidak valid.'
                ], 422);
            }

            // Mengambil harga langsung dari database
            $dailyPrice = (float) $slot->price_per_day;

            if ($dailyPrice <= 0) {
                return response()->json([
                    'success' => false,
                    'message' => 'Harga slot belum ditentukan.'
                ], 422);
            }

            if (!$slot->is_available) {
                return response()->json([
                    'success' => false,
                    'message' => 'Slot penyimpanan tidak tersedia.'
                ], 422);
            }

            $startDate = Carbon::parse($validated['start_date']);
            $endDate = Carbon::parse($validated['end_date']);

            $requestStart = $startDate->toDateString();
            $requestEnd = $endDate->toDateString();

            // Mengambil pemesanan aktif yang bertumpang tindih
            $existingRequests = StorageRequest::where(
                'storage_slot_id',
                $slot->id
            )
            ->whereIn('status', self::ACTIVE_STATUSES)
            ->whereDate('start_date', '<', $requestEnd)
            ->whereDate('end_date', '>', $requestStart)
            ->get([
                'start_date',
                'end_date',
                'quantity'
            ]);

            // Menghitung penggunaan kapasitas per tanggal
            $events = [
                $requestStart => 0,
                $requestEnd => 0,
            ];

            foreach ($existingRequests as $booking) {

                $bookingStart = Carbon::parse(
                    $booking->start_date
                )->toDateString();

                $bookingEnd = Carbon::parse(
                    $booking->end_date
                )->toDateString();

                $overlapStart = max(
                    $bookingStart,
                    $requestStart
                );

                $overlapEnd = min(
                    $bookingEnd,
                    $requestEnd
                );

                $quantity = (int) $booking->quantity;

                $events[$overlapStart] =
                    ($events[$overlapStart] ?? 0) + $quantity;

                $events[$overlapEnd] =
                    ($events[$overlapEnd] ?? 0) - $quantity;
            }

            ksort($events);

            $reservedQuantity = 0;
            $maximumExistingOccupancy = 0;
            $maximumTotalOccupancy = 0;

            foreach ($events as $date => $change) {

                $reservedQuantity += $change;

                if ($date >= $requestEnd) {
                    continue;
                }

                $maximumExistingOccupancy = max(
                    $maximumExistingOccupancy,
                    $reservedQuantity
                );

                $totalRequired =
                    $reservedQuantity + $validated['quantity'];

                $maximumTotalOccupancy = max(
                    $maximumTotalOccupancy,
                    $totalRequired
                );

                if ($totalRequired > $slot->capacity) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Kapasitas slot tidak mencukupi untuk tanggal yang dipilih.',
                        'data' => [
                            'kapasitas_total' => (int) $slot->capacity,
                            'kapasitas_terpesan' => $reservedQuantity,
                            'kapasitas_tersedia' => max(
                                0,
                                (int) $slot->capacity - $reservedQuantity
                            ),
                            'tanggal_bentrok' => $date,
                            'jumlah_diminta' => (int) $validated['quantity'],
                        ]
                    ], 422);
                }
            }

            // Menghitung durasi penitipan
            $duration = (int) $startDate->diffInDays($endDate);

            // Menghitung paket bulanan, mingguan, dan harian
            $monthlyPackages = intdiv($duration, 30);
            $remainingDays = $duration % 30;

            $weeklyPackages = intdiv($remainingDays, 7);
            $dailyRemainder = $remainingDays % 7;

            // Diskon bulanan 20%
            $monthlyPrice = $dailyPrice * 30 * 0.80;

            // Diskon mingguan 10%
            $weeklyPrice = $dailyPrice * 7 * 0.90;

            // Total harga satu barang
            $pricePerItem =
                ($monthlyPackages * $monthlyPrice) +
                ($weeklyPackages * $weeklyPrice) +
                ($dailyRemainder * $dailyPrice);

            // Total harga seluruh barang
            $totalPrice = round(
                $pricePerItem * $validated['quantity'],
                2
            );

            // Menyimpan foto barang jika pelanggan mengunggahnya
            $photoPath = null;

            if ($request->hasFile('photo')) {
                $photoPath = $request->file('photo')->store(
                    'storage-request-photos',
                    'public'
                );
            }

            // Membuat data pemesanan
            $requestData = StorageRequest::create([
                'request_code' => 'TJA-' . strtoupper(Str::random(8)),

                'user_id' => $user->id,
                'storage_place_id' => $validated['storage_place_id'],
                'storage_slot_id' => $validated['storage_slot_id'],

                'item_name' => $validated['item_name'],
                'item_category' => $validated['item_category'],
                'item_description' => $validated['item_description'] ?? null,
                'quantity' => $validated['quantity'],
                'estimated_weight' => $validated['estimated_weight'] ?? null,
                'photo_path' => $photoPath,
                'special_notes' => $validated['special_notes'] ?? null,

                'start_date' => $validated['start_date'],
                'end_date' => $validated['end_date'],

                'total_price' => $totalPrice,
                'status' => 'pending',
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Permohonan penitipan berhasil dibuat. Silakan lanjutkan pembayaran.',

                'data' => $requestData->load([
                    'user',
                    'storagePlace',
                    'storageSlot',
                    'payment'
                ]),

                'price_details' => [
                    'size' => $size,
                    'daily_price' => $dailyPrice,
                    'duration_days' => $duration,
                    'monthly_packages' => $monthlyPackages,
                    'weekly_packages' => $weeklyPackages,
                    'remaining_days' => $dailyRemainder,
                    'quantity' => $validated['quantity'],
                    'maximum_existing_occupancy' => $maximumExistingOccupancy,
                    'available_capacity_after_booking' =>
                        (int) $slot->capacity - $maximumTotalOccupancy,
                    'total_price' => $totalPrice,
                ]
            ], 201);
        });
    }

    // ==========================================
    // PEMBATALAN PEMESANAN PELANGGAN
    // ==========================================

    public function cancel(Request $request, $id)
    {
        $user = $request->user();

        return DB::transaction(function () use ($id, $user) {

            $requestData = StorageRequest::whereKey($id)
                ->lockForUpdate()
                ->first();

            if (!$requestData) {
                return response()->json([
                    'success' => false,
                    'message' => 'Pemesanan tidak ditemukan.'
                ], 404);
            }

            if ((int) $requestData->user_id !== (int) $user->id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Kamu tidak memiliki hak untuk membatalkan pemesanan ini.'
                ], 403);
            }

            if ($requestData->status !== 'pending') {
                return response()->json([
                    'success' => false,
                    'message' => 'Pemesanan hanya dapat dibatalkan ketika menunggu pembayaran.'
                ], 422);
            }

            $slot = StorageSlot::whereKey(
                $requestData->storage_slot_id
            )->lockForUpdate()->first();

            if (!$slot) {
                return response()->json([
                    'success' => false,
                    'message' => 'Slot penyimpanan tidak ditemukan.'
                ], 404);
            }

            $requestData->status = 'cancelled';
            $requestData->save();

            return response()->json([
                'success' => true,
                'message' => 'Pemesanan berhasil dibatalkan. Kapasitas periode tersebut tersedia kembali.',
                'data' => $requestData
            ]);
        });
    }

    // ==========================================
    // PERUBAHAN STATUS OLEH PENYEDIA
    // ==========================================

    public function updateStatus(Request $request, $id)
    {
        $user = $request->user();

        $validated = $request->validate([
            'status' => 'required|in:approved,checked_in,checked_out'
        ]);

        return DB::transaction(function () use ($validated, $id, $user) {

            $requestData = StorageRequest::whereKey($id)
                ->lockForUpdate()
                ->first();

            if (!$requestData) {
                return response()->json([
                    'success' => false,
                    'message' => 'Pemesanan tidak ditemukan.'
                ], 404);
            }

            $place = StoragePlace::find(
                $requestData->storage_place_id
            );

            if (!$place || (int) $place->user_id !== (int) $user->id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Kamu tidak memiliki hak untuk mengelola pemesanan ini.'
                ], 403);
            }

            $slot = StorageSlot::whereKey(
                $requestData->storage_slot_id
            )->lockForUpdate()->first();

            if (!$slot) {
                return response()->json([
                    'success' => false,
                    'message' => 'Slot penyimpanan tidak ditemukan.'
                ], 404);
            }

            // Mengatur perubahan status yang diperbolehkan
            $allowedTransitions = [
                'pending' => ['approved'],
                'approved' => ['checked_in'],
                'checked_in' => ['checked_out'],
            ];

            $currentStatus = $requestData->status;
            $newStatus = $validated['status'];

            if (
                !isset($allowedTransitions[$currentStatus]) ||
                !in_array($newStatus, $allowedTransitions[$currentStatus], true)
            ) {
                return response()->json([
                    'success' => false,
                    'message' => 'Perubahan status pemesanan tidak diizinkan.'
                ], 422);
            }

            // Memastikan pembayaran sudah lunas sebelum pemesanan disetujui
            if ($newStatus === 'approved') {

                $payment = $requestData->payment()
                    ->lockForUpdate()
                    ->first();

                if (!$payment || $payment->status !== 'paid') {
                    return response()->json([
                        'success' => false,
                        'message' => 'Pemesanan belum dapat disetujui karena pembayaran belum lunas.'
                    ], 422);
                }
            }

            // Menyimpan perubahan status
            $requestData->status = $newStatus;
            $requestData->save();

            $message = match ($newStatus) {
                'approved' => 'Pembayaran telah diverifikasi dan pemesanan berhasil disetujui.',
                'checked_in' => 'Barang berhasil dititipkan.',
                'checked_out' => 'Barang berhasil diambil. Kapasitas periode tersebut tersedia kembali.',
            };

            return response()->json([
                'success' => true,
                'message' => $message,
                'data' => $requestData->load([
                    'user',
                    'storagePlace',
                    'storageSlot',
                    'payment'
                ])
            ]);
        });
    }

    // ==========================================
    // PEMESANAN MASUK PENYEDIA
    // ==========================================

    public function incomingRequests(Request $request, $userId)
    {
        $user = $request->user();

        $requests = StorageRequest::with([
            'user',
            'storagePlace',
            'storageSlot',
            'payment'
        ])
        ->whereHas('storagePlace', function ($query) use ($user) {
            $query->where('user_id', $user->id);
        })
        ->latest()
        ->get();

        return response()->json([
            'success' => true,
            'message' => 'Data pemesanan masuk berhasil diambil.',
            'data' => $requests
        ]);
    }

    // ==========================================
    // RIWAYAT PEMESANAN PELANGGAN
    // ==========================================

    public function myRequests(Request $request, $userId)
    {
        $user = $request->user();

        $requests = StorageRequest::with([
            'user',
            'storagePlace',
            'storageSlot',
            'payment'
        ])
        ->where('user_id', $user->id)
        ->latest()
        ->get();

        return response()->json([
            'success' => true,
            'message' => 'Riwayat pemesanan berhasil diambil.',
            'data' => $requests
        ]);
    }

    // ==========================================
    // RIWAYAT PENYEWAAN PENYEDIA
    // ==========================================

    public function ownerHistory(Request $request, $userId)
    {
        $user = $request->user();

        $requests = StorageRequest::with([
            'user',
            'storagePlace',
            'storageSlot',
            'payment'
        ])
        ->whereHas('storagePlace', function ($query) use ($user) {
            $query->where('user_id', $user->id);
        })
        ->latest()
        ->get();

        return response()->json([
            'success' => true,
            'message' => 'Riwayat penyewaan berhasil diambil.',
            'data' => $requests
        ]);
    }
}

<?php

namespace App\Http\Controllers;

use App\Models\Payment;
use App\Models\StorageRequest;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class PaymentController extends Controller
{
    // ==========================================
    // MEMBUAT TAGIHAN PEMBAYARAN
    // ==========================================

    public function store(Request $request, $id)
    {
        $validated = $request->validate([
            'payment_method' => [
                'required',
                'in:bank_transfer,e_wallet',
            ],
        ]);

        return DB::transaction(function () use (
            $request,
            $id,
            $validated
        ) {

            // Mengunci pemesanan agar tidak diproses bersamaan
            $storageRequest = StorageRequest::where('user_id', $request->user()->id)
                ->lockForUpdate()
                ->find($id);

            if (!$storageRequest) {
                return response()->json([
                    'success' => false,
                    'message' => 'Permohonan penitipan tidak ditemukan.',
                ], 404);
            }

            if ($storageRequest->status !== 'pending') {
                return response()->json([
                    'success' => false,
                    'message' => 'Permohonan ini tidak dapat dibayar.',
                ], 422);
            }

            // Memeriksa apakah tagihan sudah pernah dibuat
            $existingPayment = Payment::where(
                'storage_request_id',
                $storageRequest->id
            )->lockForUpdate()->first();

            if ($existingPayment) {
                return response()->json([
                    'success' => true,
                    'message' => 'Tagihan pembayaran sudah tersedia.',
                    'data' => $existingPayment->load('storageRequest'),
                ]);
            }

            // Membuat tagihan baru
            $payment = Payment::create([
                'storage_request_id' => $storageRequest->id,
                'payment_code' => 'PAY-' . Str::upper(Str::random(10)),
                'payment_method' => $validated['payment_method'],
                'amount' => $storageRequest->total_price,
                'status' => 'pending',
                'expires_at' => now()->addHours(24),
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Tagihan pembayaran berhasil dibuat.',
                'data' => $payment->load('storageRequest'),
            ], 201);
        });
    }

    // ==========================================
    // MELIHAT DETAIL PEMBAYARAN
    // ==========================================

    public function show(Request $request, $id)
    {
        $payment = Payment::with('storageRequest')
            ->whereHas('storageRequest', function ($query) use ($request) {
                $query->where('user_id', $request->user()->id);
            })
            ->find($id);

        if (!$payment) {
            return response()->json([
                'success' => false,
                'message' => 'Data pembayaran tidak ditemukan.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Detail pembayaran berhasil diambil.',
            'data' => $payment,
        ]);
    }

    // ==========================================
    // SIMULASI PEMBAYARAN BERHASIL
    // PEMBAYARAN DAN PEMESANAN OTOMATIS DISETUJUI
    // ==========================================

    public function simulateSuccess(Request $request, $id)
    {
        return DB::transaction(function () use ($request, $id) {

            // Mencari tagihan pembayaran
            $paymentData = Payment::find($id);

            if (!$paymentData) {
                return response()->json([
                    'success' => false,
                    'message' => 'Data pembayaran tidak ditemukan.',
                ], 404);
            }

            // Mengunci pemesanan milik pelanggan
            $storageRequest = StorageRequest::where(
                'user_id',
                $request->user()->id
            )
            ->lockForUpdate()
            ->find($paymentData->storage_request_id);

            if (!$storageRequest) {
                return response()->json([
                    'success' => false,
                    'message' => 'Data pembayaran tidak ditemukan.',
                ], 404);
            }

            // Mengunci data pembayaran
            $payment = Payment::whereKey($id)
                ->lockForUpdate()
                ->first();

            if (!$payment) {
                return response()->json([
                    'success' => false,
                    'message' => 'Data pembayaran tidak ditemukan.',
                ], 404);
            }

            // Jika sudah lunas dan disetujui, tidak diproses ulang
            if (
                $payment->status === 'paid' &&
                $storageRequest->status === 'approved'
            ) {
                return response()->json([
                    'success' => true,
                    'message' => 'Pembayaran sudah lunas dan pemesanan sudah disetujui.',
                    'data' => $payment->fresh()->load('storageRequest'),
                ]);
            }

            // Memastikan pemesanan masih menunggu pembayaran
            if ($storageRequest->status !== 'pending') {
                return response()->json([
                    'success' => false,
                    'message' => 'Pemesanan tidak dapat diproses karena statusnya bukan pending.',
                ], 422);
            }

            // Memastikan pembayaran belum diproses sebelumnya
            if ($payment->status !== 'pending') {
                return response()->json([
                    'success' => false,
                    'message' => 'Pembayaran ini tidak berstatus pending.',
                ], 422);
            }

            // Memeriksa batas waktu pembayaran
            if ($payment->expires_at && $payment->expires_at->isPast()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Batas waktu pembayaran telah berakhir.',
                ], 422);
            }

            // 1. Mengubah pembayaran menjadi lunas
            $payment->update([
                'status' => 'paid',
                'paid_at' => now(),
            ]);

            // 2. Otomatis menyetujui pemesanan
            $storageRequest->update([
                'status' => 'approved',
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Pembayaran berhasil. Pemesanan otomatis disetujui.',
                'data' => $payment->fresh()->load('storageRequest'),
            ]);
        });
    }
}

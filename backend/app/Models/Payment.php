<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Payment extends Model
{
    protected $fillable = [
        'storage_request_id',
        'payment_code',
        'payment_method',
        'amount',
        'status',
        'paid_at',
        'expires_at',
    ];

    protected function casts(): array
    {
        return [
            'amount' => 'integer',
            'paid_at' => 'datetime',
            'expires_at' => 'datetime',
        ];
    }

    public function storageRequest(): BelongsTo
    {
        return $this->belongsTo(
            StorageRequest::class,
            'storage_request_id'
        );
    }
}

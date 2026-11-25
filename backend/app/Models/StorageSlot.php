<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class StorageSlot extends Model
{
    protected $fillable = [
        'storage_place_id',
        'slot_name',
        'size',
        'capacity',
        'occupied',
        'price_per_day',
        'is_available',
    ];

    public function storagePlace(): BelongsTo
    {
        return $this->belongsTo(StoragePlace::class);
    }

    public function storageRequests(): HasMany
    {
        return $this->hasMany(StorageRequest::class);
    }
}
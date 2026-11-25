<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class StoragePlace extends Model
{
    protected $fillable = [
        'user_id',
        'name',
        'description',
        'address',
        'city',
        'latitude',
        'longitude',
        'capacity',
        'price_per_day',
        'status',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function storageSlots(): HasMany
    {
        return $this->hasMany(StorageSlot::class);
    }

    public function storageRequests(): HasMany
    {
        return $this->hasMany(StorageRequest::class);
    }
}
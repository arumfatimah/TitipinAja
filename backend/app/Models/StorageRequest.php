<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;
class StorageRequest extends Model

{
    protected $fillable = [
        'user_id',
        'storage_place_id',
        'storage_slot_id',
        'request_code',
        'item_name',
        'item_category',
        'item_description',
        'quantity',
        'estimated_weight',
        'photo_path',
        'special_notes',
        'start_date',
        'end_date',
        'total_price',
        'status',
    ];
public function payment(): HasOne
{
    return $this->hasOne(Payment::class);
}
    protected function casts(): array
    {
        return [
            'estimated_weight' => 'decimal:2',
            'quantity' => 'integer',
            'start_date' => 'date',
            'end_date' => 'date',
            'total_price' => 'integer',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function storagePlace(): BelongsTo
    {
        return $this->belongsTo(StoragePlace::class);
    }

    public function storageSlot(): BelongsTo
    {
        return $this->belongsTo(StorageSlot::class);
    }
}

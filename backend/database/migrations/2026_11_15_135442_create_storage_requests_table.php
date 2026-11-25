<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('storage_requests', function (Blueprint $table) {
            $table->id();

            $table->foreignId('user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            $table->foreignId('storage_place_id')
                ->constrained('storage_places')
                ->cascadeOnDelete();

            $table->foreignId('storage_slot_id')
                ->constrained('storage_slots')
                ->cascadeOnDelete();

            $table->string('request_code')->unique();
            $table->string('item_name');
            $table->text('item_description')->nullable();

            $table->integer('quantity')->default(1);

            $table->date('start_date');
            $table->date('end_date');

            $table->decimal('total_price', 12, 2);

            $table->enum('status', [
                'pending',
                'approved',
                'checked_in',
                'checked_out',
                'cancelled'
            ])->default('approved');

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('storage_requests');
    }
};

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('storage_slots', function (Blueprint $table) {
            $table->id();

            $table->foreignId('storage_place_id')
                ->constrained('storage_places')
                ->cascadeOnDelete();

            $table->string('slot_name');
            $table->string('size');
            $table->integer('capacity');
            $table->integer('occupied')->default(0);
            $table->decimal('price_per_day', 12, 2);
            $table->boolean('is_available')->default(true);

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('storage_slots');
    }
};

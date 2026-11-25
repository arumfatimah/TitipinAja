
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('storage_requests', function (Blueprint $table) {
            $table->string('item_category')->nullable();
            $table->decimal('estimated_weight', 8, 2)->nullable();
            $table->string('photo_path')->nullable();
            $table->text('special_notes')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('storage_requests', function (Blueprint $table) {
            $table->dropColumn([
                'item_category',
                'estimated_weight',
                'photo_path',
                'special_notes',
            ]);
        });
    }
};

<?php
// One-shot (service webdav-seed): the workshop project in webdav, created and initialized once.
// webdav has no CLI for projects, so this does what ProjectController::store, the project-user
// attach and the "Initialize" stream do, inside the app. Idempotent.
//
// The project is app-led ("Index app is source of truth"): ediarum.index keeps its registers,
// and the registry tells index, id and fileservice so (index_source_of_truth: app).

require '/var/www/html/vendor/autoload.php';
$app = require '/var/www/html/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Models\Project;
use App\Models\User;
use App\Services\LockTableManager;
use App\Services\ProjectInitializer;

$slug = getenv('PROJECT');

$project = Project::where('slug', $slug)->first();
if ($project === null) {
    $project = new Project();
    $project->fill([
        'name' => getenv('PROJECT_NAME'),
        'slug' => $slug,
        // git:// is used as is: webdav adds credentials to https:// URLs only.
        'git_remote_url' => "git://gitserver/{$slug}.git",
        'git_username' => 'workshop',
        'git_branch' => 'main',
        'push_to_ediarum_services' => true,
        'is_index_app_source_of_truth' => true,
    ]);
    // required by the admin form, never sent for a git:// URL
    $project->git_access_token = 'workshop';
    $project->save();
    LockTableManager::ensureTableForProject($project->id);
    echo "webdav-seed: project {$slug} created\n";
}

if (! $project->is_index_app_source_of_truth) {
    $project->is_index_app_source_of_truth = true;
    $project->save();
    echo "webdav-seed: project {$slug} set to app-led\n";
}

$project->users()->syncWithoutDetaching(User::pluck('id')->all());

if ($project->initialized_at === null) {
    app(ProjectInitializer::class)->initialize($project, function (string $message) {
        echo "webdav-seed: {$message}\n";
    });
    echo "webdav-seed: project {$slug} initialized\n";
} else {
    echo "webdav-seed: project {$slug} already initialized\n";
}

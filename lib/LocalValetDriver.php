<?php

use Valet\Drivers\BasicValetDriver;

// Shared Herd driver for every app synk-mac-apps installs. Each site directory
// (active-setup/sites/<app>) symlinks this file and holds:
//   dist -> builds/<version>   the live build, swapped atomically by site-update.sh
//   root-redirect              optional path that / redirects to
//   .auto-update/              update state and log
// Opening a page starts a background update check at most once a week.
class LocalValetDriver extends BasicValetDriver
{
    public function isStaticFile(string $sitePath, string $siteName, string $uri)
    {
        return parent::isStaticFile($this->dist($sitePath), $siteName, $uri);
    }

    // Every page open lands here; existing files are answered by isStaticFile.
    public function frontControllerPath(string $sitePath, string $siteName, string $uri): ?string
    {
        // A missing file (an old chunk, a probe) is a real 404, not a page open.
        if (pathinfo($uri, PATHINFO_EXTENSION) !== '' || preg_match('#^/(assets|_app)/#', $uri)) {
            return null;
        }

        $redirect = trim((string) @file_get_contents($sitePath.'/root-redirect'));
        if ($uri === '/' && $redirect !== '') {
            header('Location: '.$redirect, true, 302);
            exit;
        }

        $this->updateIfDue($sitePath);

        // Prerendered routes (SvelteKit's /edit -> edit.html) get their own page;
        // other routes get the SPA shell: 404.html where the build ships one as its
        // fallback (SvelteKit), else index.html.
        $dist = $this->dist($sitePath);
        if (! is_file($dist.'/index.html')) {
            return null; // no build yet
        }
        $route = rtrim($uri, '/');
        if ($route === '') {
            $page = '/index.html';
        } elseif (preg_match('#^[\w/-]+$#', $route) && is_file($dist.$route.'.html')) {
            $page = $route.'.html';
        } else {
            $page = is_file($dist.'/404.html') ? '/404.html' : '/index.html';
        }

        $_SERVER['SCRIPT_FILENAME'] = $dist.$page;
        $_SERVER['SCRIPT_NAME'] = $page;
        $_SERVER['DOCUMENT_ROOT'] = $dist;

        return $dist.$page;
    }

    // Resolve dist ourselves: PHP's realpath cache would keep using the previous
    // build for up to two minutes after site-update.sh swaps the symlink. Without
    // dist, an empty directory, never the site directory itself.
    private function dist(string $sitePath): string
    {
        $link = @readlink($sitePath.'/dist');

        return $link === false ? '/var/empty' : $sitePath.'/'.$link;
    }

    private function updateIfDue(string $sitePath): void
    {
        $state = $sitePath.'/.auto-update';
        if (file_exists($state.'/last-check') && time() - filemtime($state.'/last-check') < 7 * 86400) {
            return;
        }

        // Claim this week's slot before spawning, so a burst of page loads starts one run.
        @mkdir($state);
        touch($state.'/last-check');
        // Site directories live at <repo>/active-setup/sites/<app>.
        exec('nohup /bin/bash '.escapeshellarg(dirname($sitePath, 3).'/lib/site-update.sh')
            .' '.escapeshellarg(basename($sitePath))
            .' >> '.escapeshellarg($state.'/update.log').' 2>&1 &');
    }
}
